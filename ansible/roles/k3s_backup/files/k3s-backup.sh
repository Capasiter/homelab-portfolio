#!/usr/bin/env bash

set -Eeuo pipefail

readonly SNAPSHOT_DIR="${SNAPSHOT_DIR:-/var/lib/rancher/k3s/server/db/snapshots}"
readonly BACKUP_ROOT="${BACKUP_ROOT:-/mnt/k3s-backups}"
readonly SNAPSHOT_PREFIX="${SNAPSHOT_PREFIX:-k3s-etcd}"
readonly TOKEN_PATH="${TOKEN_PATH:-/var/lib/rancher/k3s/server/token}"
readonly LOCK_FILE="${LOCK_FILE:-/run/lock/k3s-backup.lock}"
HOST_NAME="$(hostname -s)"
readonly HOST_NAME
readonly BACKUP_DIR="${BACKUP_ROOT}/etcd/${HOST_NAME}/rolling"
readonly BASELINE_DIR="${BACKUP_ROOT}/etcd/${HOST_NAME}/baseline"
readonly TOKEN_BACKUP_DIR="${BACKUP_ROOT}/token/${HOST_NAME}"
readonly ROLLING_RETENTION="${ROLLING_RETENTION:-3}"
marker_file=""
partial_path=""
snapshot_path=""
snapshot_name=""
source_checksum=""

log() {
  printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
}

# Writes $content to $final_path atomically: write to a .partial sibling,
# fsync it, then rename into place. Ensures the visible file is always
# either the old complete version or the new complete version, and always
# gets fresh ownership from the current NFS mapping (a plain '>' onto an
# existing file would keep that file's old ownership/inode).
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

prune_local_snapshots() {
  log "Pruning local on-demand snapshots using the K3s retention policy."
  k3s etcd-snapshot prune --name "$SNAPSHOT_PREFIX"
}

backup_baseline_if_missing() {
  install -d -m 0750 "$BASELINE_DIR"

  if find "$BASELINE_DIR" -maxdepth 1 -type f \
       -name "${SNAPSHOT_PREFIX}-*.zip" -print -quit | grep -q .; then
    log "Baseline snapshot already exists; leaving it untouched."
    return
  fi

  log "No baseline snapshot found. Preserving this snapshot as the permanent baseline."
  local baseline_dest="${BASELINE_DIR}/${snapshot_name}"
  partial_path="${baseline_dest}.partial"

  cp --preserve=timestamps "$snapshot_path" "$partial_path"
  chmod 0640 "$partial_path"
  sync "$partial_path"

  local baseline_checksum
  baseline_checksum="$(sha256sum "$partial_path" | awk '{print $1}')"
  if [[ "$baseline_checksum" != "$source_checksum" ]]; then
    fail "Checksum verification failed for baseline copy of ${snapshot_name}."
  fi

  mv "$partial_path" "$baseline_dest"
  partial_path=""

  atomic_write "${baseline_dest}.sha256" \
    "${baseline_checksum}  ${snapshot_name}
" \
    0640

  log "Baseline snapshot saved: ${baseline_dest}"
}

backup_token() {
  if [[ ! -r "$TOKEN_PATH" ]]; then
    log "WARNING: token not readable at ${TOKEN_PATH}; skipping token backup."
    return
  fi

  install -d -m 0700 "$TOKEN_BACKUP_DIR"

  local token_dest="${TOKEN_BACKUP_DIR}/token"
  partial_path="${token_dest}.partial"

  cp --preserve=timestamps "$TOKEN_PATH" "$partial_path"
  chmod 0600 "$partial_path"
  sync "$partial_path"

  local token_source_checksum token_dest_checksum
  token_source_checksum="$(sha256sum "$TOKEN_PATH" | awk '{print $1}')"
  token_dest_checksum="$(sha256sum "$partial_path" | awk '{print $1}')"

  if [[ "$token_source_checksum" != "$token_dest_checksum" ]]; then
    fail "Checksum verification failed for token backup."
  fi

  mv "$partial_path" "$token_dest"
  partial_path=""

  atomic_write "${token_dest}.sha256" \
    "${token_dest_checksum}  token
" \
    0600

  log "Token backup verified and updated."
}

cleanup() {
  if [[ -n "$marker_file" ]]; then
    rm -f "$marker_file"
  fi

  if [[ -n "$partial_path" ]]; then
    rm -f "$partial_path"
  fi
}

trap cleanup EXIT

if ((EUID != 0)); then
  fail "Run this script as root."
fi

if ! [[ "$ROLLING_RETENTION" =~ ^[1-9][0-9]*$ ]]; then
  fail "ROLLING_RETENTION must be a positive integer."
fi

for command_name in k3s findmnt mountpoint sha256sum flock timeout; do
  command -v "$command_name" >/dev/null 2>&1 ||
    fail "Required command not found: ${command_name}"
done

exec 9>"$LOCK_FILE"
flock -n 9 || fail "Another K3s backup is already running."

mountpoint -q "$BACKUP_ROOT" ||
  fail "Backup path is not mounted: ${BACKUP_ROOT}"

timeout 10 stat "$BACKUP_ROOT" >/dev/null ||
  fail "Backup path is not responding: ${BACKUP_ROOT}"

findmnt -rn -t nfs,nfs4 "$BACKUP_ROOT" >/dev/null ||
  fail "Backup path is not backed by NFS: ${BACKUP_ROOT}"

install -d -m 0750 "$BACKUP_DIR"

marker_file="$(mktemp "${SNAPSHOT_DIR}/.k3s-backup-marker.XXXXXX")"

log "Creating an on-demand K3s etcd snapshot."
k3s etcd-snapshot save --name "$SNAPSHOT_PREFIX"

snapshot_path="$(
  find "$SNAPSHOT_DIR" -maxdepth 1 -type f \
    -name "${SNAPSHOT_PREFIX}-*.zip" \
    -newer "$marker_file" \
    -printf '%T@ %p\n' |
    sort -nr |
    sed -n '1s/^[^ ]* //p'
)"

[[ -n "$snapshot_path" ]] ||
  fail "Unable to identify the newly created snapshot."

snapshot_name="$(basename "$snapshot_path")"
destination_path="${BACKUP_DIR}/${snapshot_name}"
partial_path="${destination_path}.partial"

log "Copying ${snapshot_name} to off-server storage."
cp --preserve=timestamps "$snapshot_path" "$partial_path"
chmod 0640 "$partial_path"
sync "$partial_path"

source_checksum="$(sha256sum "$snapshot_path" | awk '{print $1}')"
destination_checksum="$(sha256sum "$partial_path" | awk '{print $1}')"

if [[ "$source_checksum" != "$destination_checksum" ]]; then
  fail "Checksum verification failed for ${snapshot_name}."
fi

mv "$partial_path" "$destination_path"
partial_path=""

atomic_write "${destination_path}.sha256" \
  "${destination_checksum}  ${snapshot_name}
" \
  0640

log "Checksum verified: ${destination_checksum}"

backup_baseline_if_missing
backup_token

while IFS= read -r expired_snapshot; do
  expired_name="$(basename "$expired_snapshot")"
  rm -f -- "$expired_snapshot" "${expired_snapshot}.sha256"
  log "Pruned expired rolling backup: ${expired_name}"
done < <(
  find "$BACKUP_DIR" -maxdepth 1 -type f \
    -name "${SNAPSHOT_PREFIX}-*.zip" \
    -printf '%T@ %p\n' |
    sort -nr |
    awk -v keep="$ROLLING_RETENTION" '
      NR > keep {
        sub(/^[^ ]+ /, "")
        print
      }
    '
)
prune_local_snapshots
log "Backup completed: ${destination_path}"
