# Backup artifact validator

Offline validator for K3s etcd backup artifacts. It checks the local backup
directory only: no backup mounts, SSH, Kubernetes, or secret access.
The token file is never opened or read.

## Run from the repository root

    python3 scripts/validate-backup-artifacts.py --backup-dir /path/to/backups --host k3s-server-01

Expected layout under `--backup-dir`:

    etcd/<host>/rolling/k3s-etcd-*.zip        rolling snapshots
    etcd/<host>/rolling/k3s-etcd-*.zip.sha256 sidecar checksums
    etcd/<host>/baseline/k3s-etcd-*.zip       baseline snapshot
    etcd/<host>/baseline/k3s-etcd-*.zip.sha256 sidecar checksums
    token/<host>/token                         cluster token (never opened)
    token/<host>/token.sha256                  token sidecar

Checks performed per artifact: regular file (not a symlink), sidecar present,
and sidecar format `<sha256>  <name>` with exactly two spaces, 64 lowercase
hex characters, and a name matching the artifact. For every rolling and
baseline snapshot the SHA-256 is recomputed by reading the file in chunks and
compared against the digest in its sidecar; a mismatch is reported as a failed
finding tied to the snapshot path. The token file is never opened or read;
only its existence, regular-file status, and sidecar format are validated —
token contents are not verified. A `--json` flag prints the
structured report with findings, errors, and limitations.

Exit code is `0` when all checks pass and `1` when any check fails.

## Isolated tests

    python3 scripts/validate-backup-artifacts.py --self-test

All 24 checks passed locally with exit code 0 using synthetic fixtures built
in a temporary directory. The self-test includes checksum verification: a
fixture with valid snapshot checksums passes, while fixtures with a mismatched
rolling checksum and a mismatched baseline checksum each fail with a finding
tied to the offending snapshot. No real backup artifacts or hosts were used.
CI is configured to run these tests without connecting to the lab.

## Limitations

Snapshot checksums are recomputed and compared against their sidecars.
Token contents are not verified: the token file is never opened or read, and
its checksum is not checked against the token itself.
Artifact freshness is not assessed. Restore testing is not performed.
Validation success does not prove backup success.
