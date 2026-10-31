> **ARCHIVE — historical handoff (PR #54/#55 era).** This document is preserved as the record of that
> handoff. **Current state lives in `SESSION_STATE.md`.** Read this only for history; do not update it
> as new work happens.

---

# AI Handoff Note

Shared project notes are still being built. This is the first handoff document; treat it as a starting point, not a complete record.

All deployment and validation results below are historical evidence documented in README.md unless identified as a local check. The validator self-test below was run against synthetic fixtures; no live infrastructure was accessed and no live infrastructure state was verified.

## Project summary

- **What it is:** A hands-on infrastructure portfolio by Lee Austin running three K3s server VMs (control plane + embedded etcd, Ubuntu 24.04, 4 vCPU/6 GB each) on a single Proxmox host, fronted by a kube-vip API VIP (10.20.0.110:6443) and isolated behind an OPNsense gateway on a separate lab bridge.

- **Automation stack:** OpenTofu provisions VMs with stable identities and networking; Ansible handles the hardened Linux baseline and K3s cluster deployment (demonstrated idempotent with `changed=0`); GitHub Actions does static validation only — no live-infrastructure deployment from CI.

- **Current milestone (v0.9.0):** Argo CD GitOps application delivery for WebDemo, with documented drift detection (replicas 3→4) and manual reconciliation back to Synced/Healthy; automated sync, self-heal, and pruning are intentionally disabled.

- **Verified live evidence (per README.md, historical):** Protected rolling-update rollout (148 successful HTTP requests, 0 failures), Prometheus/Grafana alert lifecycle test, API leader-pod failover (VIP moved server 02→03 with no failed probes), and off-server etcd backups to Unraid NFS with SHA-256 verification and protected tokens.

- **Known limits & roadmap (per README.md, historical):** Full etcd restore is **not** complete (decompression verified but blocked by a K3s reset-path panic); single physical host is a documented failure boundary. Next planned: Unraid-backed shared application storage with volume-recovery validation, then completed restore validation, outbound alert delivery, and a human-supervised local-AI workflow pilot (Hermes, Continue/OpenCode, K8sGPT).

## Recent work — storage recovery plan (documentation only)

- Added `STORAGE-RECOVERY-PLAN.md`: a human-reviewed plan covering the current data path (Pod → PVC `storage-demo-data` → PV `storage-demo-nfs` → Unraid NFS `192.168.0.102:/mnt/user/k3s-app-data`), prerequisites, per-check evidence to capture, success criteria, abort conditions, and cleanup/rollback for: Pod replacement persistence (documented 2026-10-13), cross-node read (documented), cross-node Deployment rescheduling (untested), single-file restore (documented) vs full-volume recovery (untested, and no full-volume backup method exists yet), and Unraid host loss (documented limits: app data and all "off-server" backups share one physical Unraid host).
- Every step that could modify, replace, or delete data (Pod deletion, cordon/uncordon, reader manifest apply/delete, backup-directory writes, live-volume restore, destructive full-volume restore, Unraid repair/power-off, PV re-pointing) is marked `⚠ HUMAN APPROVAL REQUIRED` and must be individually approved before execution.
- Linked the plan from `INDEX.md`. All cited validation results remain historical evidence from `kubernetes/storage-demo/README.md` and `docs/portfolio-history-through-v0.7.md`; nothing in the plan is a live check, and no commands were run for this work.
- Remaining human decisions before any live test are listed in `STORAGE-RECOVERY-PLAN.md` section 9 (live-state confirmation, per-check approvals, decision on funding a full-volume backup method, and whether Check 5 is a review-only exercise or an actual host-loss test).

## Recent work — backup artifact validator and storage-demo health check

- **PR #55 — "Add offline backup artifact validator"** squash-merged as `42208ac`.
- **PR #54 — "Add storage demo to K3s health check"** squash-merged as `ed3bcea`.
- The validator self-test was run as `python3 scripts/validate-backup-artifacts.py --self-test` and printed `PASS: 24 validator self-test checks (synthetic fixtures only).` It builds fixture trees in a temp dir and validates the snapshot/token sidecar format — the token file is never opened.
- Added SHA-256 verification for every rolling and baseline snapshot: the digest is recomputed by reading the file in 1 MiB chunks and compared against the digest in its `.sha256` sidecar; a mismatch is reported as a failed finding tied to the snapshot path. Sidecar format and filename checks are preserved. The token file is still never opened or read — only its existence, regular-file status, and sidecar format are validated, so token contents are not verified. Three new synthetic self-tests cover: valid snapshot checksums pass; a mismatched rolling checksum fails; and a mismatched baseline checksum fails.
- **No live infrastructure was accessed** for this work: the self-test and validator operate on synthetic/local fixtures only, and no live cluster, VM, NFS host, or Unraid storage was touched.

- Updated the `PROJECT_GUIDE.md` scripts table to include `validate-backup-artifacts.py`; documentation alignment only, with no code or live infrastructure checks.

## Working rules for agents

- Ground claims in repository files; do not infer live system state from fixtures or documentation.
- Do not run commands, commit, or push without explicit permission.
- Preserve existing SSH behavior, guarded PVC retrieval, and final RESULT handling; do not introduce a top-level return.
- Human review is required for proposed changes.
