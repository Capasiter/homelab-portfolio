# Storage Recovery Plan (human-reviewed)

Status: **Draft for human review.** This document is planning and procedure only. No commands were run, no live system was queried, and nothing was changed while writing it.

Evidence rule: every validation result cited below is **historical evidence recorded in this repository** (primarily `kubernetes/storage-demo/README.md`, dated 2026-10-13, plus `docs/portfolio-history-through-v0.7.md` and `docs/backup-evidence-collector.md`). None of it is a live check. Before executing any check in this plan, a human must confirm the current live state matches the assumptions listed under each check's prerequisites.

Approval model:

- Steps marked `⚠ HUMAN APPROVAL REQUIRED` can modify, replace, or delete data or workload state. They must not be executed until a human has explicitly approved that specific step, in that specific order.
- Read-only steps (list, checksum, status, mount inspection) do not require per-step approval but must still happen inside a window a human has authorized.
- The repository working rules (see `docs/ai/HANDOFF.md`) still apply: no commits, no pushes, no automation changes from within this work.

## 1. Current data path

Application data (sources: `kubernetes/storage-demo/storage.yaml`, `kubernetes/storage-demo/deployment.yaml`):

```
storage-demo Pod (namespace storage-demo, busybox:1.37.0, UID 99 / GID 100, mounts /data)
  -> PVC  storage-demo-data  (ReadWriteMany, 1Gi, volumeName: storage-demo-nfs)
  -> PV   storage-demo-nfs   (Retain, storageClassName "", nfsvers=3, hard, proto=tcp)
  -> NFSv3 export 192.168.0.102:/mnt/user/k3s-app-data  (Unraid, "Fast" storage)
```

Key properties that shape recovery:

- `ReadWriteMany` is meaningful here: any of the three K3s nodes can mount the volume, which is what makes cross-node checks possible.
- `Retain` reclaim policy: deleting the PVC does not delete the data on Unraid; it leaves the volume in use and requires manual PV/PVC re-attachment work to recover.
- `hard` mount option: if the Unraid host disappears, client I/O **hangs indefinitely** rather than erroring. Expect hung Pods, not fast failures (see Check 5).
- The PV has a fixed `claimRef` to `storage-demo-data`; re-pointing a lost server address is a manual PV edit, not an automated step.
- Export rule recorded in `kubernetes/storage-demo/README.md`: `192.168.0.162(rw,sync,insecure,root_squash)` — the `insecure` option is required because of client-side port translation, and the rule cannot distinguish which K3s node is connecting.

Backup data (sources: `ansible/roles/k3s_backup/defaults/main.yml`, `ansible/roles/k3s_backup/files/k3s-backup.sh`, `docs/portfolio-history-through-v0.7.md`):

- All "off-server" backups land on the **same Unraid host** (192.168.0.102), export `/mnt/user/k3s-backups`, mounted at `/mnt/k3s-backups` on the K3s bootstrap server.
- `k3s-backup.timer` (daily 03:15 + up to 10 min randomized delay) runs `k3s-backup.sh`: etcd snapshot to `etcd/<host>/rolling` (retention 3), one permanent baseline, and a protected K3s server token under `token/<host>`, all SHA-256 verified with atomic write-then-rename.
- **Etcd snapshots do not back up PV contents** (stated in `kubernetes/storage-demo/README.md`). There is no documented full-volume backup of `k3s-app-data` and no documented copy of any Unraid data to a different physical host.
- Single-file application backup, recorded 2026-10-13: `persistence-proof.txt` copied to `/mnt/k3s-backups/applications/storage-demo.71a7FL/persistence-proof.txt` (directory 0700 root-owned, file 0600), restored under a new name `/data/restored-proof.txt` with an overwrite guard; SHA-256 and `cmp` matched.
- Full K3s restore is **not** complete: decompression verified, blocked by a reproducible K3s reset-path panic (v0.7 record in `docs/portfolio-history-through-v0.7.md`). The isolated restore lab for drills is `proxmox/opentofu/environments/restore-lab/` (VM ID 404, template 9100, NIC disconnected by default).

## 2. Shared prerequisites (all checks)

Before any check, a human confirms, read-only:

1. Repository state matches this plan's source documents (read `kubernetes/storage-demo/README.md`, `kubernetes/storage-demo/storage.yaml`, `kubernetes/storage-demo/deployment.yaml` at the commit being tested).
2. The lab is reachable through the documented SSH bastion path and the operator has cluster admin access.
3. All three K3s nodes are Ready; the `storage-demo` Deployment is 1/1 available and its PVC is Bound.
4. The demo Pod's current node, Pod name, and UID/GID (99/100) are recorded.
5. The file under test exists in `/data` and its SHA-256 digest is recorded as the baseline for the session.
6. The NFS client (`nfs-common`) is installed on the nodes involved (installed by `ansible/playbooks/k3s_storage_clients.yml`; verify with `findmnt` on the target node).
7. Argo CD `storage-demo` Application is Synced and Healthy (manual-sync model; `kubernetes/argocd/applications/storage-demo.yaml`).
8. The human designates which node hosts the backup export mount used for Check 4 (recorded historically as `k3s-server-01`) and confirms that node's `/mnt/k3s-backups` mount is live.
9. No other live work depends on the `storage-demo` namespace or the nodes being cordoned, for the duration of the test window.

## 3. Check 1 — Pod replacement persistence (already documented)

Recorded evidence (2026-10-13, `kubernetes/storage-demo/README.md`): original pod `storage-demo-5df449c886-tvkbb` on `k3s-server-03` wrote `persistence-proof.txt`; replacement pod `storage-demo-5df449c886-kctxc` (same node) read it back; content `homelab-storage-proof-5285091` and SHA-256 `741681964e93ad07f5faba653cccaf87ce1922530efaa82e369961b65ac66958` matched.

This check re-verifies that deleting and recreating the Pod does not lose data. It is the baseline that the cross-node checks build on.

Prerequisites: shared prerequisites 1–7; known baseline digest.

Steps:

1. Record current Pod name, node, and `/data` file listing with SHA-256 (read-only).
2. `⚠ HUMAN APPROVAL REQUIRED — replaces the running workload (brief outage); does not delete data: delete the current demo Pod (e.g., `kubectl delete pod` in namespace `storage-demo`) to force the Deployment controller to create a replacement.`
3. Wait for the replacement Pod to be Ready; record its name and node (read-only).
4. Read the file from the replacement Pod and run `sha256sum -c` against the baseline digest (read-only).

Evidence to capture: both Pod names, node placement, timestamps (UTC), full `sha256sum` output, `kubectl get pods -n storage-demo -o wide` before and after.

Success criteria: replacement Pod is Running and Ready; file present with identical content and SHA-256; Deployment remains 1/1; Argo Application still Synced/Healthy.

Abort conditions: replacement Pod stuck Pending/CrashLoopBackOff beyond a human-set window (suggested: 5 minutes); file missing or digest mismatch (stop, preserve the Pod, do not retry deletion); PVC leaves Bound state; Argo reports OutOfSync with no manifest change.

Cleanup / rollback: none expected. If the replacement Pod must be replaced again (e.g., wrong node for Check 3), that deletion is itself `⚠ HUMAN APPROVAL REQUIRED`.

## 4. Check 2 — Cross-node read (already documented)

Recorded evidence (2026-10-13): a temporary Pod `storage-demo-reader` mounted the same PVC **read-only** on `k3s-server-02` while the Deployment ran on `k3s-server-03`; it printed the expected content and `sha256sum -c` returned `/data/persistence-proof.txt: OK`. The README is explicit: this proves cross-node read access, **not** Deployment rescheduling or recovery.

Prerequisites: shared prerequisites 1–8; the demo Deployment currently on one known node; at least one other Ready node available for the reader.

Steps:

1. Record the writer Pod's node (read-only).
2. Prepare a temporary reader Pod manifest **outside** the Argo-managed `kubernetes/storage-demo/` directory (the Application tracks `*.yaml` in that path, so a manifest added there would be picked up by sync), mounting `storage-demo-data` with `readOnly: true` and a pinned node to a node **other than** the writer's.
   `⚠ HUMAN APPROVAL REQUIRED — creates a new cluster object; manifest must be human-reviewed before apply.`
3. Apply the reader manifest; wait for completion; capture its stdout, including the `sha256sum -c` result (read-only after apply).
4. Record the reader Pod's node from `kubectl get pods -o wide` (read-only).
5. `⚠ HUMAN APPROVAL REQUIRED — deletes the temporary reader object: delete the reader Pod/manifest and confirm the object is gone.`

Evidence to capture: reader manifest, reader Pod name and node, writer Pod name and node, stdout with digest check, apply/delete timestamps.

Success criteria: reader completed successfully on a **different node** than the writer; printed content matches the baseline; digest check passes; no changes visible to the writer Pod's data (re-check baseline digest on the writer).

Abort conditions: reader mount fails (check the NFS client on that node and the export's `insecure` requirement before retrying); digest mismatch; reader lands on the same node as the writer (invalid test — delete and re-plan); writer's baseline digest changed at any point.

Cleanup / rollback: delete the reader (step 5, approval-gated); confirm no stale NFS client mount lingers on the reader node (`findmnt`, read-only); confirm the writer Pod and file are unchanged.

## 5. Check 3 — Cross-node Deployment rescheduling (UNTESTED)

This is the first time the Deployment itself (not a one-shot reader) is expected to land on a different node and still serve the same data. No recorded validation exists for it; treat any result as new evidence.

Prerequisites: shared prerequisites 1–8; Deployment 1/1 on a known node (record it); the other two nodes Ready and unscheduled-free; human has confirmed what else runs on the current node (Argo CD is a single-replica, non-HA install; WebDemo runs in `k8s-learning`) so cordon side effects are understood.

Chosen method: cordon + Pod replacement. Cordon only blocks **new** scheduling; it does not evict existing Pods, so this avoids touching Argo CD or WebDemo. `drain` is deliberately **not** used here — it evicts every Pod on the node and is a separate, higher-impact decision.

Steps:

1. Record baseline: Pod name, node, file SHA-256, Argo state (read-only).
2. `⚠ HUMAN APPROVAL REQUIRED — changes cluster scheduling state; other workloads can no longer land on this node: cordon the demo Pod's current node.`
3. `⚠ HUMAN APPROVAL REQUIRED — replaces the running workload (brief outage): delete the demo Pod so the Recreate-strategy Deployment schedules a replacement on a different node.`
4. Wait for the replacement to be Ready; **verify its node is different from the baseline**; capture `kubectl get pods -n storage-demo -o wide` (read-only).
5. Read the file and run `sha256sum -c` against the baseline (read-only).
6. `⚠ HUMAN APPROVAL REQUIRED — restores scheduling state: uncordon the node.`
7. Confirm all three nodes are schedulable again and Argo is Synced/Healthy (read-only).

Evidence to capture: cordon/uncordon commands and timestamps, both Pod names and nodes, digest check output, node Ready/schedulable states after uncordon, Argo state.

Success criteria: replacement Pod Running and Ready on a node **different** from the baseline node; data identical by SHA-256; Argo Synced/Healthy; all nodes unscheduled (uncordoned) at the end; no other workload evicted.

Abort conditions: replacement lands on the same node (cordon not effective — stop, uncordon, re-plan); not scheduled within the human-set window; CrashLoopBackOff or NFS mount errors (check client install and export options before any retry); digest mismatch (stop and preserve the Pod); uncordon fails (leave the node cordoned, do not cascade fixes).

Cleanup / rollback: step 6 (uncordon, approval-gated) is the rollback for scheduling. If the human wants the Pod back on its original node: `⚠ HUMAN APPROVAL REQUIRED` for each of — cordon the new node, delete the replacement Pod, uncordon the original node — in that order.

## 6. Check 4 — Single-file restore versus full-volume recovery

### 6a. Single-file restore (already documented)

Recorded evidence (2026-10-13): the live `persistence-proof.txt` was copied through `kubectl exec` to `/mnt/k3s-backups/applications/storage-demo.71a7FL/persistence-proof.txt` on the backup export mounted at `k3s-server-01`; directory 0700, file 0600; copy passed SHA-256 against the original; it was then restored into `/data/restored-proof.txt` with an overwrite guard, without removing the original; restored file passed SHA-256 and `cmp`.

Prerequisites: shared prerequisites 1–8; the backup artifact still exists and is readable on the designated node (verify read-only: listing, mode, digest).

Steps:

1. Verify the backup artifact (read-only): path, size, mode (0600 in a 0700 directory), and its SHA-256 against the digest recorded in the 2026-10-13 evidence. If the recorded digest no longer matches the live file, stop — the file changed after the backup and a fresh backup is needed.
2. `⚠ HUMAN APPROVAL REQUIRED — writes a new file into the live volume: restore the backup into /data under a NEW name (e.g., restored-proof.txt) via kubectl exec, with an overwrite guard that refuses to run if the target already exists. The original file is never touched.`
3. Verify the restored file: `sha256sum -c` against the backup digest and `cmp` against the backup (read-only).
4. Re-verify the original file's digest is unchanged (read-only).
5. `⚠ HUMAN APPROVAL REQUIRED — deletes the restored copy created in step 2: remove the restored file and confirm it is gone.`

Evidence to capture: artifact listing/mode/digest, restore command, both digest checks, `cmp` output, original-file digest before and after, cleanup confirmation.

Success criteria: restored file digest equals the backup digest; `cmp` clean; original file untouched and unchanged; backup artifact still present and unchanged.

Abort conditions: backup artifact missing or unreadable; digest mismatch at any stage (stop; do not proceed to a destructive restore); overwrite guard trips (target exists — stop, clean up with approval, restart); backup mount absent on the designated node.

Cleanup / rollback: step 5 (approval-gated deletion of the restored copy). The original and the backup artifact must never be deleted in this check.

### 6b. Full-volume recovery (UNTESTED — no full-volume backup exists yet)

Gap: the only recorded application-data backup is the single file in 6a. Etcd snapshots exclude PV contents, and no automation creates a full backup of `/mnt/user/k3s-app-data`. **A full-volume recovery cannot be tested until a human-approved full-volume backup method exists and has produced a verified artifact.** Building that automation is a separate work item (manifest/Ansible changes are out of scope for documentation work).

Prerequisites:

1. A human-approved backup method (for example: a tar archive of `/mnt/user/k3s-app-data` taken from the Unraid side, or `rsync` from a K3s node into the backup export) with a per-file manifest (path + SHA-256).
2. One backup artifact plus manifest, stored on the backup export, independently verified (artifact digest and manifest check pass, read-only).
3. A scratch restore location that is **not** the live export (for example, a sibling directory under the backup export or a local temp path) so verification never writes over live data.
4. Shared prerequisites 1–8.

Steps (non-destructive phase — the actual recovery proof):

1. Verify artifact and manifest (read-only): `tar -tf` listing, per-file `sha256sum -c` from the manifest.
2. `⚠ HUMAN APPROVAL REQUIRED — creates new files in the scratch location; no existing data is modified: extract the full-volume backup into the scratch location.`
3. Verify every file in the scratch restore against the manifest (read-only): `sha256sum -c`, listing comparison, total file count.
4. `⚠ HUMAN APPROVAL REQUIRED — deletes the scratch restore: remove the scratch location and confirm it is gone.`

Steps (destructive phase — ONLY if a live restore into the real export is actually required, e.g., after simulated data loss):

5. `⚠ HUMAN APPROVAL REQUIRED — DESTRUCTIVE, overwrites live data in /mnt/user/k3s-app-data: restore the backup over the live export.` Only a human who has confirmed the current live contents are either backed up elsewhere or deliberately discardable may approve this.
6. Re-verify the live export against the manifest and re-check the demo Pod's file digest (read-only).

Evidence to capture: method description, artifact path/digest/size, manifest digest, scratch extraction listing, per-file verification results, (if destructive phase) live export state before and after.

Success criteria (non-destructive phase): 100% of manifest files present in scratch restore with matching digests; live export untouched (digest re-check of a known live file).
Success criteria (destructive phase, only if approved): live export matches the manifest; demo Pod reads expected content; Argo Synced/Healthy.

Abort conditions: any manifest mismatch or missing file (stop; the backup is untrusted — do not use it for a live restore); scratch location unavailable; live export unmounted or the designated node unreachable; any step fails its approval gate.

Cleanup / rollback: step 4 (approval-gated scratch deletion). For the destructive phase, "rollback" means restoring the previous contents — which only exists if a backup of the pre-restore state was taken first (`⚠ HUMAN APPROVAL REQUIRED — creates a new backup artifact`).

## 7. Check 5 — Unraid host loss and the limits of same-host backups

This check is primarily a **limits review and decision record**, not a routine test. Actually powering off the Unraid host is a catastrophic, mostly irreversible action and is only ever done under explicit, informed human approval.

Documented limits (sources as in section 1):

- The application data (`/mnt/user/k3s-app-data`) and **every** off-server backup (etcd snapshots, baseline, rolling, server token, single-file app backup) live on the **same Unraid host** (192.168.0.102). "Off-server" means off the K3s VMs, not off the physical host.
- No documented copy of any Unraid data exists on another machine. Loss of the host or its disks means simultaneous loss of the data and its backups.
- The K3s control plane runs on a different physical machine (the Proxmox host), so the cluster itself survives Unraid loss — but:
  - the demo Pod's `hard` NFS mount will **hang** (indefinite I/O stalls), not fail cleanly; expect unresponsive Pods;
  - `k3s-backup.timer` runs will start failing (the script fails fast when `/mnt/k3s-backups` is not a live NFS mount — that guard is working as designed, but it means backups stop, not that they continue);
  - the Check 4a restore path becomes unusable because the backup artifact is on the lost host;
  - full K3s etcd restore is already blocked (v0.7 record), so even a scenario where the snapshots survive (Unraid software failure with disks intact) has no proven restore path yet.

Scenario A — Unraid software failure, disks intact (recovery expected):

Prerequisites: human physically or remotely at the Unraid machine; Proxmox/console access to K3s nodes; baseline digests recorded (shared prerequisite 5).

Steps:

1. Record the failure state (read-only): Pod states, `dmesg`/mount errors on K3s nodes, timer/service status.
2. `⚠ HUMAN APPROVAL REQUIRED — reboots/repairs the storage host; all K3s-side NFS I/O is affected: restore Unraid to a bootable state (array check, export re-enabled).`
3. Verify the export config still matches the documented rule (read-only on Unraid).
4. Re-verify the known file's SHA-256 from a K3s node (read-only).
5. Confirm the demo Pod recovers I/O and the backup timer's next run succeeds (read-only).

Evidence to capture: failure timeline, Unraid array status, export rule before/after, digests, timer/service results after recovery.

Success criteria: data intact by digest; export serves the three nodes again; demo Pod functional; backup job completes and verifies.

Abort conditions: array degraded or any disk failed (switch to Scenario B; no repair attempts without the human); digests mismatch (data corruption — stop and preserve state).

Scenario B — Unraid host or disk loss (data loss accepted; re-provisioning only):

- Application data: unrecoverable from this repository's documented backups. The only surviving copy is whatever a human separately maintains off-host (none is documented).
- K3s cluster: survives (different physical host), but loses its off-server backups. The `k3s-backup` job must be re-pointed to a new storage host.
- Recovery steps (each approval-gated): provision/restore a storage host; recreate the export; `⚠ HUMAN APPROVAL REQUIRED — edits a live cluster object (the claimRef-bound PV) or creates replacement objects: re-point `storage-demo-nfs` (or replace PV/PVC pair, using the `Retain` semantics) to the new server path`; re-point the backup mount and Ansible defaults (`ansible/roles/k3s_backup/defaults/main.yml`) to the new host; re-run Check 1 as the post-recovery verification.
- Success criteria: export serving, demo Pod reading/writing with a fresh digest baseline, backup job completing with SHA-256 verification on the new host.
- Record: this is a lab portfolio. The human decides whether the outcome is documented as a loss-and-rebuild record (consistent with the repo's "document only what the evidence proves" rule) and what, if anything, is archived from the lost host first.

Explicit non-goals: this plan does not propose Unraid hardware redundancy, ZFS-level off-host replication, or a second storage host — those are architecture decisions for the human, and the repo currently documents the single-Unraid-host setup as a known failure boundary (`README.md`, `docs/ai/PROJECT_GUIDE.md`).

## 8. Evidence log template

For every executed check, record (one row per step, UTC timestamps):

```
check | step | date/time (UTC) | node | pod/object | command (verbatim) | digest/exit | result | approver (name + time of approval)
```

Attach: `kubectl get pods -n storage-demo -o wide` output before/after, full digest-check output, Argo Application state at start and end. Store the log in a location a human designates (this repository only after human review, per working rules).

## 9. Human decisions required before any live test

1. Confirm the current live state matches section 2 prerequisites (who, when, what was checked).
2. Approve Check 1 re-run: one Pod deletion (brief outage, no data deletion).
3. Approve Check 2: the temporary reader manifest (review the exact YAML) and its later deletion.
4. Approve Check 3: cordon, Pod deletion, uncordon — in that order, with the abort conditions honored.
5. Approve Check 4a: backup-directory write, live-volume restore under a new name, and cleanup deletion of the restored copy.
6. Decide whether to fund/build a full-volume backup method (new automation, separate work item) before attempting Check 4b; if yes, approve the non-destructive phase; the destructive phase needs a separate, explicit approval with the current live contents' disposition stated.
7. Decide whether Check 5 is (a) a documented limits review only, (b) a Scenario A drill with a healthy Unraid, or (c) an actual power-off test. Option (c) is destructive to all data and all backups on the Unraid host and requires the human to state, in writing, that the loss is accepted and what (if anything) will be preserved first.
