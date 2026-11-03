# G2 — Full etcd restore drill (runbook)

**Status:** Ready to execute. Blocked on restore-lab VM (404) access — Proxmox was "No route to host" from the Linux box on 2026-11-03.
**Last updated:** 2026-11-03 (Bionic)
**Read first:** `docs/etcd-restore-g2-diagnosis.md` (root cause: K3s #14526, fixed by #14528)
**Related:** `ansible/docs/k3s-restore-lab.md` · `ansible/playbooks/k3s_restore_lab_stage.yml` · `proxmox/opentofu/environments/restore-lab/`

> **Safety model:** this drill runs **only** in the isolated restore-lab VM (404), which is disposable and never joined to the production cluster. It must never use the production `vmbr1` bridge or the production K3s config directory. Destructive steps are approval-gated.

---

## 0. Preconditions (verify before starting)

| # | Check | How | Expected |
|---|---|---|---|
| 0.1 | Restore-lab VM (404) exists + reachable | Proxmox console / `qm list` | VM present, on staging `vmbr0` only |
| 0.2 | Lab K3s version is in the **fixed** range | `k3s version` on the VM | **v1.36.5+k3s1** (preferred) or v1.36.4+k3s1 with #14528 confirmed |
| 0.3 | A **compressed** etcd snapshot is staged on the VM | `ls -l <snapshot dir>/*.zip` | snapshot present (the affected path — this is the scenario that panicked) |
| 0.4 | Matching K3s server token is staged | `ls -l <token path>` (presence + 0600 only — **never print it**) | token present |
| 0.5 | Snapshot integrity | `sha256sum -c <snapshot>.zip.sha256` | `OK` |
| 0.6 | K3s is **stopped** (offline phase) | `systemctl is-active k3s` | `inactive` |
| 0.7 | NIC state | Proxmox | disconnected (offline) or on staging `vmbr0` only — **never `vmbr1`** |

> **Critical (from the diagnosis):** the panic was specific to **compressed** snapshots. Use a `.zip` snapshot for this drill — that's the exact scenario that failed. If you only have an uncompressed one, the test is weaker (the uncompressed path was never broken).

## 1. Record the "before" state (read-only)

```bash
# On the lab VM (Proxmox console or SSH if on staging network):
k3s version
ls -l <snapshot dir>
sha256sum -c <snapshot>.zip.sha256        # record the digest
systemctl is-active k3s                    # expect: inactive
```

Capture: K3s version, snapshot filename + SHA-256, token presence (not value), k3s service state.

## 2. Run the restore (⚠ HUMAN APPROVAL REQUIRED — this is the destructive/restore step)

The documented K3s single-node etcd restore. **Use only `--cluster-reset` (NOT `--cluster-init` together with it)** — see K3s issue #9305 for why combining them is wrong.

```bash
# <SNAPSHOT> = absolute path to the .zip snapshot on the VM
# <TOKEN>    = the staged K3s server token (type it at the keyboard; never paste into a log)
k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=<SNAPSHOT> \
  --token <TOKEN>
```

**Watch the log for the decisive line.** The old bug failed here:
```
level=fatal msg="... open .../snapshots/.../snapshots/<file>.zip: no such file or directory"
```
The **fixed** version proceeds past decompression to:
```
INFO ... restoring snapshot
```
and then starts the API server.

## 3. Verify the restore (read-only)

```bash
# Wait for the API to come up, then:
k3s kubectl get nodes                          # expect: Ready
k3s kubectl get nodes -o wide
k3s kubectl get cs                           # (or get componentstatuses if available)
k3s kubectl get pods -A                        # system pods Running
k3s kubectl get pvc -A                         # PVCs as expected
```

**Success criteria (all must hold):**
- [ ] Restore log proceeds past decompression to "restoring snapshot" (no doubled-path fatal)
- [ ] `k3s kubectl get nodes` → node **Ready**
- [ ] Core system pods Running
- [ ] Snapshot `sha256sum -c` → `OK` (integrity)
- [ ] Exit codes captured for each command

**Abort conditions:**
- Restore log shows the doubled-path fatal or any nil-pointer panic → **stop**, capture the full log, do NOT retry blindly. Record the exact K3s version + the failing line. (This would mean the lab's K3s is still in the affected range — re-stage with v1.36.5+k3s1.)
- Node stuck NotReady beyond a set window (suggested 5 min) → stop, preserve the VM state for inspection.
- Any snapshot integrity mismatch → the backup artifact is untrusted; do not use it.

## 4. Cleanup (⚠ HUMAN APPROVAL REQUIRED)

- Snapshot the lab VM state (or note it) for the record.
- The VM is disposable: stop it, or delete it per the restore-lab OpenTofu environment (`network_disconnected = true` is the safe default).
- **Do not** connect the VM to `vmbr1` (production bridge).

## 5. Evidence to capture (for the portfolio artifact)

- K3s version used (must be in the fixed range)
- Snapshot filename + SHA-256 + `sha256sum -c` output
- The full restore log (especially the decompression → "restoring snapshot" transition)
- Before/after `k3s kubectl get nodes` + `get pods -A`
- Exit codes for every command
- Timestamps (UTC)

## 6. If it still panics (fallback)

1. Confirm the exact K3s + etcd version (`k3s version`, `k3s etcd --version` if available).
2. Confirm #14528 is actually in that build (release notes / `k3s` binary).
3. Re-stage the lab with **v1.36.5+k3s1** (the first release definitively carrying the 2026-09 backport of #14528) and re-run.
4. If v1.36.5 still fails, capture the full log + version and re-open the diagnosis — it may be a *different* reset-path bug, and that becomes its own finding.

---

*This runbook is `DOC` (procedure). The drill result will be `LIVE` once executed. No live-cluster state is touched — the lab is isolated by design.*
