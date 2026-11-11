# Unraid-backed storage demo

## Configuration

- Static NFS PV: storage-demo-nfs; PVC: storage-demo-data.
- Export: 192.168.0.102:/mnt/user/k3s-app-data, on Unraid Fast storage.
- NFSv3 over TCP; ReadWriteMany; Retain reclaim policy.
- Declared 1Gi capacity is binding metadata, not an enforced NFS quota.
- Demo container runs as UID 99/GID 100.
- Argo CD uses manual sync; the committed Application targets main.
- Initial live validation used feature/shared-app-storage at commit 5285091.
- Export rule: 192.168.0.162(rw,sync,insecure,root_squash).
- All three node connection tests appeared to Unraid as 192.168.0.162.
  This restriction cannot distinguish clients behind that translated address.
- Ansible installs nfs-common through playbooks/k3s_storage_clients.yml.

## Live validation — 2026-10-13

- NFS client installation succeeded on all three K3s nodes.
- Second Ansible run: changed=0, unreachable=0, failed=0 on every node.
- Read-only NFSv3 mount and unmount succeeded on all three nodes.
- Initial mount with the secure export option was denied.
  Adding insecure resolved it, consistent with client-port translation.
- Namespace, PV, PVC, Deployment and Argo Application passed server dry-run.
- Manual Argo sync of commit 5285091 succeeded: Synced and Healthy.
- PVC Bound; Deployment 1/1 available.
- Container confirmed UID 99/GID 100 and wrote persistence-proof.txt.
- Original pod: storage-demo-5df449c886-tvkbb, on k3s-server-03.
- Replacement pod: storage-demo-5df449c886-kctxc, on k3s-server-03.
- File content and SHA-256 matched after pod replacement.

File content: homelab-storage-proof-5285091

SHA-256: 741681964e93ad07f5faba653cccaf87ce1922530efaa82e369961b65ac66958

## Remaining validation

Cross-node Deployment rescheduling remains untested. Full application-volume
backup and a non-destructive restore proof are documented below (2026-11-06).
Single-file backup/restore is also documented below.
Etcd snapshots do not back up volume contents.
The shared Unraid host remains a storage dependency.

## Cross-node read validation — 2026-10-13

A temporary Pod, storage-demo-reader, mounted the same PVC read-only
on k3s-server-02 while the demo Deployment remained on k3s-server-03.
The reader completed successfully, printed the expected file content,
and returned /data/persistence-proof.txt: OK from sha256sum -c.
This proves cross-node read access, not Deployment rescheduling or recovery.

## Single-file backup and restore — 2026-10-13

Copied persistence-proof.txt from the running demo through kubectl exec
to /mnt/k3s-backups/applications/storage-demo.71a7FL/persistence-proof.txt
on k3s-server-01's mounted Unraid backup export.
The application-backup directory was configured root-owned with mode 0700;
the backup file was set to mode 0600.
The backup copy passed verification against the original SHA-256.

Streamed the backup into /data/restored-proof.txt through kubectl exec,
with an overwrite guard and without removing the original.
The restored file passed SHA-256 verification, and cmp confirmed that
original and restored contents match.

Scope: one test file restored under a new name. Full-volume recovery,
data-loss recovery, automated backups and retention remain untested.
Application data and this backup reside on the same Unraid host;
this is not protection against loss of that host.

## Full-volume backup and restore proof — 2026-11-06 (G3)

The `k3s_app_backup` role (ansible/roles/k3s_app_backup/) creates a
full-volume, checksum-verified backup of the app-data export, and the
restore was proven non-destructively (Phase A of
docs/g3-pvc-full-volume-design.md §4.3).

**Backup (LIVE, 2026-11-06T18:20:54Z, k3s-server-01):**
- Source: /mnt/k3s-app-data (NFSv3 mount of 192.168.0.102:/mnt/user/k3s-app-data).
- Artifact: /mnt/k3s-backups/applications/storage-demo/rolling/20261106T182054Z/
  - storage-demo-data.tar (2 files, --numeric-owner, UID 99 / GID 100 preserved)
  - manifest.sha256 (per-file SHA-256)
  - artifact.sha256 (single digest of the .tar)
  - meta.json (ts, host, file count, artifact digest)
- Baseline: first verified backup preserved at /mnt/k3s-backups/applications/storage-demo/baseline/ (never overwritten).
- Artifact digest: 30b7698be1fd0751f75917c6eb8bf02a2b7da6daf4e5e5f19ee5cb239c46b644

**Phase A restore proof (LIVE, non-destructive):**
- Extracted the archive to a scratch dir (/tmp/g3-restore-proof-...).
- sha256sum -c against the manifest: both files OK
  - k3s-app-data/persistence-proof.txt: OK
  - k3s-app-data/restored-proof.txt: OK
- File count: manifest 2 == scratch 2 (COUNT-MATCH).
- Live export untouched: both files still present, persistence-proof.txt
  digest 741681964e93ad07f5faba653cccaf87ce1922530efaa82e369961b65ac66958
  (identical to the 2026-10-13 historical evidence — the backup faithfully
  preserves the data).
- Scratch dir removed after verification.

**Evidence bar met (docs/g3-pvc-full-volume-design.md §5):** a full-volume
backup artifact + manifest exist and pass sha256sum -c; Phase A recovers
100% of manifest files with matching digests; the live export is untouched.

**Limits (unchanged):** the backup and the data share the Unraid host;
this is not protection against loss of that host. The destructive live
restore (Phase B) was not run — Phase A is the sufficient, non-destructive
proof for the portfolio. (Phase B can be added later if needed.)
