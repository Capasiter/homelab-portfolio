# G3 — PVC Full-Volume Backup & Restore (Design)

Status: **Design for human review.** This is planning only. No commands were run, no live system was queried, and nothing was changed while writing it. It funds the gap named in `STORAGE-RECOVERY-PLAN.md` §6b ("a full-volume recovery cannot be tested until a human-approved full-volume backup method exists and has produced a verified artifact").

Evidence rule: every fact cited below is either (a) a file already in this repository, or (b) a historical record in `kubernetes/storage-demo/README.md` / `docs/portfolio-history-through-v0.7.md`. Nothing here is a live check. Before any live step, a human confirms the current state matches the prerequisites.

Approval model: inherits `STORAGE-RECOVERY-PLAN.md` unchanged — read-only steps need only an authorized window; any step that creates, replaces, or deletes data or cluster objects is `⚠ HUMAN APPROVAL REQUIRED`.

## 1. What G3 is (and is not)

**Is:** a repeatable, checksum-verified **full-volume** backup of the Unraid-backed application data (`/mnt/user/k3s-app-data`, served as the `storage-demo-data` PVC), plus a restore path that proves the backup actually recovers the data — byte-for-byte.

**Is not:**
- Not a replacement for etcd snapshots (those back up cluster state, not PV contents — stated in `kubernetes/storage-demo/README.md`).
- Not off-host redundancy. The backup lands on the **same Unraid host** as the data (`STORAGE-RECOVERY-PLAN.md` §7). That limit stays documented as a known failure boundary.
- Not a live-infra change. This doc designs the method; building the automation (script/manifest) and running the drill are separate, approval-gated steps.

## 2. The data path (source of truth)

From `kubernetes/storage-demo/storage.yaml` + `deployment.yaml`:

```
storage-demo Pod (ns storage-demo, busybox:1.37.0, UID 99 / GID 100, mounts /data)
  -> PVC  storage-demo-data  (ReadWriteMany, 1Gi, volumeName: storage-demo-nfs)
  -> PV   storage-demo-nfs   (Retain, storageClassName "", nfsvers=3, hard, proto=tcp)
  -> NFSv3 export 192.168.0.102:/mnt/user/k3s-app-data   (Unraid, "Fast" storage)
```

Properties that shape the design:

- **`Retain` reclaim policy:** deleting the PVC does not delete the Unraid data. Recovery is a re-attach, not a recreate.
- **`hard` mount:** if Unraid disappears, client I/O hangs (no fast failure). Backups must therefore be taken **from the Unraid side** (or a node with a live mount), not assumed to succeed under host loss.
- **`ReadWriteMany`:** any of the three K3s nodes can mount it — so a restore can be verified from a node independent of the writer.
- **Same host as data:** the backup and the data share the Unraid host. This is a documented limit, not a bug to fix here.

## 3. Design goals

1. **Verifiable:** every backup artifact has a per-file manifest (path + SHA-256) and an artifact-level digest; a restore is only "proven" when 100% of manifest files match on re-extraction.
2. **Non-destructive by default:** the restore proof extracts to a **scratch** location and compares; it never overwrites live data unless a human explicitly approves the destructive phase.
3. **Reproducible:** the same method, run again, produces an equivalent artifact; retention is bounded (matching the etcd backup's rolling-retention convention).
4. **Consistent with existing conventions:** atomic write-then-rename, SHA-256, lock file, and log format mirror `ansible/roles/k3s_backup/files/k3s-backup.sh` so the two backup jobs read like one system.
5. **Honest about limits:** the same-host limit and the `hard`-mount hang behavior are stated, not hidden.

## 4. Backup method (the build)

**Chosen method: a `tar` archive of the export tree, taken from the Unraid side, with a per-file manifest.**

Why tar-from-Unraid (over rsync-from-a-K3s-node):
- The data physically lives on Unraid; archiving there avoids a second NFS copy and works even if a K3s node's mount is degraded.
- `tar` preserves the directory tree, file modes, and (with `--numeric-owner`) the UID/GID (99/100) that the demo Pod depends on.
- It is a single atomic artifact (one file + one manifest), which is easier to checksum, retain, and restore than a live rsync mirror.

### 4.1 Artifact layout (on the backup export)

```
/mnt/k3s-backups/applications/storage-demo/
  rolling/
    <ts>/
      storage-demo-data.tar        # the volume archive
      manifest.sha256              # per-file:  <sha256>  <relative/path>
      artifact.sha256              # single digest of the .tar
      meta.json                    # ts, host, source path, file count, tar version, uid/gid
  baseline/
    storage-demo-data.tar          # one permanent first-good copy
    manifest.sha256
    artifact.sha256
    meta.json
```

- `rolling/` keeps the last **3** (matching `ROLLING_RETENTION=3` for etcd), pruned oldest-first after a verified new one lands.
- `baseline/` is written once (first verified backup) and never overwritten — same convention as the etcd baseline.
- All writes are atomic (`.partial` → `sync` → `mv`), directories `0750`, files `0640`, matching the etcd backup.

### 4.2 Backup procedure (approval-gated)

1. **Lock** (`/run/lock/k3s-app-backup.lock`) so two runs never interleave.
2. **Verify source is a live Unraid path** (read-only): the export exists, is a directory, and the known demo file is present. If not, fail fast (do not produce an empty archive).
3. **Create the archive** into a `.partial` sibling: `tar --create --file=<...>.partial --numeric-owner --format=ustar -C /mnt/user k3s-app-data`.
4. **Generate the manifest** from the archive (not the live tree, so the manifest describes exactly what is in the artifact): `tar --list --file=<...>.partial` → per-file `sha256sum` of each extracted member into `manifest.sha256.partial`.
5. **Verify the archive** (read-only): re-list it, confirm the member count matches the manifest, and compute `artifact.sha256`.
6. **Atomically publish** the `.partial` set into `<ts>/` (archive, manifest, artifact digest, meta).
7. **Prune** `rolling/` beyond retention 3 (only after the new set is fully published and verified).
8. **Release the lock**; log a one-line summary (ts, file count, artifact digest, retention state).

Abort conditions: source path missing/not a directory; tar fails; manifest member count ≠ archive member count; publish rename fails; disk full (check free space before starting). On any abort, remove the `.partial` set and leave prior artifacts untouched.

### 4.3 Restore procedure (two phases, per §6b)

**Phase A — non-destructive proof (the actual G3 evidence):**
1. Verify artifact + manifest (read-only): `tar -tf`, per-file `sha256sum -c` from the manifest.
2. `⚠ HUMAN APPROVAL REQUIRED — creates files in a scratch location only; no live data touched: extract the archive into a scratch dir` (a sibling under the backup export or a local temp path, **not** `/mnt/user/k3s-app-data`).
3. Verify every file in the scratch restore against the manifest (read-only): `sha256sum -c`, listing comparison, total file count.
4. `⚠ HUMAN APPROVAL REQUIRED — deletes the scratch restore: remove the scratch dir and confirm it is gone.`

Success (Phase A): 100% of manifest files present in scratch with matching digests; live export untouched (re-check a known live file's digest).

**Phase B — destructive live restore (only if a real recovery is required, e.g., after simulated data loss):**
5. `⚠ HUMAN APPROVAL REQUIRED — DESTRUCTIVE, overwrites /mnt/user/k3s-app-data: restore the backup over the live export.` Only a human who has confirmed the current live contents are backed up elsewhere or deliberately discardable may approve.
6. Re-verify the live export against the manifest and re-check the demo Pod's file digest (read-only).

Success (Phase B): live export matches the manifest; demo Pod reads expected content; Argo Synced/Healthy.

Rollback for Phase B: only exists if a backup of the pre-restore state was taken first (`⚠ HUMAN APPROVAL REQUIRED — creates a new backup artifact`).

## 5. What "done" looks like (evidence bar)

G3 is **done** when, in an authorized window with a human approving each gated step:

- A full-volume backup artifact + manifest exist on the backup export and pass `sha256sum -c` (artifact + per-file).
- Phase A (scratch restore) recovers **100%** of manifest files with matching digests; the live export is untouched.
- (Optional, only if approved) Phase B restores over the live export and the demo Pod reads the expected content.
- An evidence-log row per step is captured (template in `STORAGE-RECOVERY-PLAN.md` §8): command, digest/exit, node, pod, approver + time.
- The method + the proof are documented in `kubernetes/storage-demo/README.md` (or a sibling) so the public narrative can cite it.

Until then, G3 is **in progress / blocked on approval**, not done.

## 6. Build plan (the work items, sequenced)

| # | Item | Output | Gate |
|---|---|---|---|
| 6.1 | Write `k3s-app-backup.sh` (tar + manifest + atomic publish + retention), mirroring `k3s-backup.sh` conventions | Script in `ansible/roles/k3s_backup/files/` (or a new `k3s_app_backup` role) | Lee reviews the script |
| 6.2 | Add a `k3s-app-backup.timer` (daily, offset from the etcd timer) + a `k3s-app-backup.service` | systemd units rendered by Ansible | Lee reviews the units |
| 6.3 | Wire the role into the K3s cluster playbook (install on the bootstrap node, enable timer) | Playbook change | Lee approves the playbook diff |
| 6.4 | **First run + verify** (Phase A proof) in an authorized window | Evidence log + artifact + manifest on the export | Lee approves each gated step |
| 6.5 | (Optional) Phase B destructive restore after simulated loss | Evidence log | Lee explicitly approves + states live-content disposition |
| 6.6 | Document the method + proof in the storage-demo README + update the brain | Merged doc PR (CI green) | Lee reviews the PR |

## 7. Open decisions for Lee

1. **Backup source:** confirm **tar-from-Unraid** (recommended) vs rsync-from-a-K3s-node. (Both satisfy §6b; tar-from-Unraid is simpler and avoids a second NFS copy.)
2. **Retention:** rolling **3** + 1 baseline (matches etcd) — OK, or a different count?
3. **Schedule:** daily, offset from the 03:15 etcd timer (e.g., 03:45) — OK?
4. **Phase B:** do you want the destructive live-restore drill at all, or is the Phase A (scratch) proof enough for the portfolio? (Phase A is the honest, sufficient evidence; Phase B is extra.)
5. **Where the script lives:** extend the existing `k3s_backup` role, or a new `k3s_app_backup` role? (I lean new role — keeps the etcd and app-data jobs separate and readable.)

## 8. Limits (stated, not hidden)

- **Same host:** the backup and the data share the Unraid host. Loss of that host loses both. This is a documented failure boundary (`README.md`, `PROJECT_GUIDE.md`), not something G3 fixes.
- **`hard` mount:** under Unraid loss, K3s-side I/O hangs; the Unraid-side backup is the reliable path, which is why the method archives from Unraid.
- **Scope:** G3 covers the `storage-demo` volume. Extending the same method to other Unraid-backed volumes is a later, separate decision.
