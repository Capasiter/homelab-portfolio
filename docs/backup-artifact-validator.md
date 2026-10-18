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
hex characters, and a name matching the artifact. A `--json` flag prints the
structured report with findings, errors, and limitations.

Exit code is `0` when all checks pass and `1` when any check fails.

## Isolated tests

    python3 scripts/validate-backup-artifacts.py --self-test

All 21 checks passed locally with exit code 0 using synthetic fixtures built
in a temporary directory. No real backup artifacts or hosts were used.
CI is configured to run these tests without connecting to the lab.

## Limitations

Checksum values are not recomputed or compared against artifact contents.
Artifact freshness is not assessed. Restore testing is not performed.
The token file is never opened or read.
Validation success does not prove backup success.
