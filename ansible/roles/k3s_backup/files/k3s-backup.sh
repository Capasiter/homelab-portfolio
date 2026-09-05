#!/usr/bin/env bash

set -Eeuo pipefail

readonly SNAPSHOT_DIR="${SNAPSHOT_DIR:-/var/lib/rancher/k3s/server/db/snapshots}"
readonly BACKUP_ROOT="${BACKUP_ROOT:-/mnt/k3s-backups}"
readonly SNAPSHOT_PREFIX="${SNAPSHOT_PREFIX:-k3s-etcd}"
readonly LOCK_FILE="${LOCK_FILE:-/run/lock/k3s-backup.lock}"
HOST_NAME="$(hostname -s)"
readonly HOST_NAME
readonly BACKUP_DIR="${BACKUP_ROOT}/etcd/${HOST_NAME}/rolling"
readonly ROLLING_RETENTION="${ROLLING_RETENTION:-3}"

marker_file=""
partial_path=""

log() {
  printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
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

printf '%s  %s\n' "$destination_checksum" "$snapshot_name" \
  >"${destination_path}.sha256"
chmod 0640 "${destination_path}.sha256"

log "Checksum verified: ${destination_checksum}"

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
log "Backup completed: ${destination_path}"
