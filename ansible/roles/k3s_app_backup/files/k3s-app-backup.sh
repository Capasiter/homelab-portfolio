#!/usr/bin/env bash
#
# G3 — full-volume backup of the Unraid-backed application data.
#
# Produces, under $BACKUP_ROOT/applications/$APP_NAME/rolling/<ts>/:
#   <APP_NAME>-data.tar        the volume archive
#   manifest.sha256            per-file:  <sha256>  <relative/path>
#   artifact.sha256            single digest of the .tar
#   meta.json                  ts, host, source, file count, uid/gid note
#
# Conventions mirror ansible/roles/k3s_backup/files/k3s-backup.sh:
#   set -Eeuo pipefail, atomic write-then-rename, SHA-256 verify, flock, retention prune.
#
# This script is BACKUP ONLY (non-destructive). Restore is a separate,
# approval-gated procedure (see docs/g3-pvc-full-volume-design.md §4.3).

set -Eeuo pipefail

readonly BACKUP_ROOT="${BACKUP_ROOT:-/mnt/k3s-backups}"
readonly APP_NAME="${APP_NAME:-storage-demo}"
readonly SOURCE_DIR="${SOURCE_DIR:-/mnt/user/k3s-app-data}"
readonly ROLLING_RETENTION="${ROLLING_RETENTION:-3}"
readonly LOCK_FILE="${LOCK_FILE:-/run/lock/k3s-app-backup.lock}"

HOST_NAME="$(hostname -s)"
readonly HOST_NAME
readonly APP_ROOT="${BACKUP_ROOT}/applications/${APP_NAME}"
readonly ROLLING_DIR="${APP_ROOT}/rolling"
readonly BASELINE_DIR="${APP_ROOT}/baseline"

marker_file=""
partial_path=""
ts=""
archive_path=""
manifest_path=""

log() {
  printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
}

# Writes $content to $final_path atomically: .partial sibling, fsync, rename.
# Ensures the visible file is always either the old complete version or the new
# complete version, and always gets fresh ownership from the current NFS mapping.
atomic_write() {
  local final_path="$1"
  local content="$2"
  local mode="$3"

  local write_partial="${final_path}.partial"
  partial_path="$write_partial"

  printf '%s' "$content" >"$write_partial"
  chmod "$mode" "$write_partial"
  sync "$write_partial"
  mv "$write_partial" "$final_path"
  partial_path=""
}

cleanup() {
  if [[ -n "$marker_file" && -e "$marker_file" ]]; then
    rm -f "$marker_file"
  fi
  if [[ -n "$partial_path" && -e "$partial_path" ]]; then
    rm -f "$partial_path"
  fi
}

trap cleanup EXIT

if ((EUID != 0)); then
  fail "Run this script as root."
fi

if [[ ! "$ROLLING_RETENTION" =~ ^[1-9][0-9]*$ ]]; then
  fail "ROLLING_RETENTION must be a positive integer."
fi

for command_name in tar findmnt mountpoint sha256sum flock timeout find sort awk sed; do
  command -v "$command_name" >/dev/null 2>&1 ||
    fail "Required command not found: ${command_name}"
done

exec 9>"$LOCK_FILE"
flock -n 9 || fail "Another app-data backup is already running."

# The source must be a live NFS mount of the application data export.
mountpoint -q "$SOURCE_DIR" ||
  fail "Source path is not mounted: ${SOURCE_DIR}"

timeout 10 stat "$SOURCE_DIR" >/dev/null ||
  fail "Source path is not responding: ${SOURCE_DIR}"

findmnt -rn -t nfs,nfs4 "$SOURCE_DIR" >/dev/null ||
  fail "Source path is not backed by NFS: ${SOURCE_DIR}"

# The backup root must be a live mount (same guard as the etcd backup).
mountpoint -q "$BACKUP_ROOT" ||
  fail "Backup root is not mounted: ${BACKUP_ROOT}"

# Fail fast if the source is empty (do not publish an empty archive).
if [[ -z "$(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  fail "Source directory is empty: ${SOURCE_DIR} (refusing to create an empty backup)."
fi

install -d -m 0750 "$ROLLING_DIR"

ts="$(date -u +'%Y%m%dT%H%M%SZ')"
readonly ts
readonly DEST_DIR="${ROLLING_DIR}/${ts}"
archive_path="${DEST_DIR}/${APP_NAME}-data.tar"
manifest_path="${DEST_DIR}/manifest.sha256"
partial_path="${archive_path}.partial"

# DEST_DIR must exist before the tar writes its .partial into it.
install -d -m 0750 "$DEST_DIR"

log "Creating a full-volume archive of ${SOURCE_DIR}."
# Archive members are relative to the export root (the basename of
# SOURCE_DIR), preserving the tree the PVC exposes, regardless of where
# the export is mounted (Unraid: /mnt/user/k3s-app-data; node: /mnt/k3s-app-data).
source_parent="$(dirname "$SOURCE_DIR")"
source_base="$(basename "$SOURCE_DIR")"
tar --create \
  --file="$partial_path" \
  --numeric-owner \
  --format=ustar \
  --directory="$source_parent" \
  "$source_base"

chmod 0640 "$partial_path"
sync "$partial_path"

# Build the per-file manifest FROM THE ARCHIVE (so it describes exactly what is
# in the artifact, not the live tree). Extract each member to a temp dir, hash it.
log "Generating the per-file manifest from the archive."
manifest_tmp="$(mktemp)"
trap 'rm -f "$manifest_tmp"' EXIT
extract_tmp="$(mktemp -d)"
trap 'rm -rf "$extract_tmp"; rm -f "$manifest_tmp"' EXIT

# List regular files in the archive (skip directory entries).
while IFS= read -r member; do
  # member looks like: k3s-app-data/some/path/file
  [[ "$member" == */ || -z "$member" ]] && continue
  member_file="${extract_tmp}/${member}"
  mkdir -p "$(dirname "$member_file")"
  tar --extract --file="$partial_path" --to-stdout "$member" >"$member_file"
  digest="$(sha256sum "$member_file" | awk '{print $1}')"
  printf '%s  %s\n' "$digest" "$member" >>"$manifest_tmp"
  rm -f "$member_file"
done < <(tar --list --file="$partial_path" --no-recursion)

# Count files in the manifest and in the archive; they must agree.
manifest_count="$(wc -l <"$manifest_tmp")"
archive_file_count="$(tar --list --file="$partial_path" --no-recursion | grep -v '/$' | grep -c . || true)"
if [[ "$manifest_count" -ne "$archive_file_count" ]]; then
  fail "Manifest file count (${manifest_count}) != archive file count (${archive_file_count})."
fi

# Artifact-level digest.
artifact_digest="$(sha256sum "$partial_path" | awk '{print $1}')"

# Atomically publish the set into DEST_DIR.
install -d -m 0750 "$DEST_DIR"
mv "$partial_path" "$archive_path"
partial_path=""

atomic_write "$manifest_path" "$(cat "$manifest_tmp")" 0640
atomic_write "${DEST_DIR}/artifact.sha256" "${artifact_digest}  ${APP_NAME}-data.tar
" 0640

meta_json="$(printf '{
  "ts": "%s",
  "host": "%s",
  "app": "%s",
  "source": "%s",
  "file_count": %s,
  "artifact_sha256": "%s",
  "note": "uid/gid preserved via --numeric-owner; demo Pod runs UID 99 / GID 100"
}' "$ts" "$HOST_NAME" "$APP_NAME" "$SOURCE_DIR" "$manifest_count" "$artifact_digest")"
atomic_write "${DEST_DIR}/meta.json" "$meta_json" 0640

# Baseline: first verified backup becomes the permanent baseline (never overwritten).
if [[ ! -e "${BASELINE_DIR}/${APP_NAME}-data.tar" ]]; then
  install -d -m 0750 "$BASELINE_DIR"
  log "No baseline found. Preserving this backup as the permanent baseline."
  cp --preserve=timestamps "$archive_path" "${BASELINE_DIR}/${APP_NAME}-data.tar.partial"
  cp --preserve=timestamps "$manifest_path" "${BASELINE_DIR}/manifest.sha256.partial"
  cp --preserve=timestamps "${DEST_DIR}/artifact.sha256" "${BASELINE_DIR}/artifact.sha256.partial"
  cp --preserve=timestamps "${DEST_DIR}/meta.json" "${BASELINE_DIR}/meta.json.partial"
  sync "${BASELINE_DIR}/${APP_NAME}-data.tar.partial"
  mv "${BASELINE_DIR}/${APP_NAME}-data.tar.partial" "${BASELINE_DIR}/${APP_NAME}-data.tar"
  mv "${BASELINE_DIR}/manifest.sha256.partial" "${BASELINE_DIR}/manifest.sha256"
  mv "${BASELINE_DIR}/artifact.sha256.partial" "${BASELINE_DIR}/artifact.sha256"
  mv "${BASELINE_DIR}/meta.json.partial" "${BASELINE_DIR}/meta.json"
  log "Baseline saved: ${BASELINE_DIR}/${APP_NAME}-data.tar"
fi

# Prune rolling backups beyond retention (only after the new set is fully published).
while IFS= read -r expired_dir; do
  rm -rf -- "$expired_dir"
  log "Pruned expired rolling backup: $(basename "$expired_dir")"
done < <(
  find "$ROLLING_DIR" -mindepth 1 -maxdepth 1 -type d \
    -printf '%T@ %p\n' |
    sort -nr |
    awk -v keep="$ROLLING_RETENTION" 'NR > keep { sub(/^[^ ]+ /, ""); print }'
)

log "Backup completed: ${archive_path} (${manifest_count} files, artifact ${artifact_digest})"
