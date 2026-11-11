# Morning Queue — the single live working queue

> **Purpose:** one place for *what's done, what's blocked, and the 2–3 things Lee must answer*. Replaces ad-hoc phone summaries (D-026-6). The agent updates this at the end of every work block; Lee answers the decisions; the agent executes. Keep it short — if it's long, split the work.

> **Rule:** this is a *queue*, not a log. `SESSION_STATE.md` is the full history; this file is only the live "next" and "needed." Mirror the "Needed from Lee" section to the phone when a work block finishes.

**Last updated:** 2026-11-10 (Bionic) — **PR #78/79 merged**, Hermes↔LM Studio connection **resolved**.

---

## Done (this stretch)
- **P-3/P-6/P-7 cleanup DONE**: gitignore already in place; storage-demo Explore row added to README; stale duplicate `docs/diagrams/future-architecture.svg` removed.
- **G1 (alert delivery) DONE**: ntfy spam fixed, Watchdog routed to `"null"` receiver (PR #70).
- **G3 (PVC full-volume) DONE**: build (`k3s_app_backup` role, PR #75) + first backup + Phase A non-destructive restore proof (LIVE 2026-11-06).
- **CI checks for `k3s_app_backup` DONE**: added syntax-check, role-lint, template-render steps (PR #78 merged).
- **Hermes↔LM Studio connection RESOLVED**: reverse SSH tunnel working; Hermes using `qwen/qwen3.5-9b` (non-reasoning model) for fast responses.

## Blocked
- **G2 execution**: Proxmox (`192.168.0.182`) unreachable from the Linux box (22/443/8006 closed). Needs Lee at the keyboard to restore the PVE/VM network path.

## Needed from Lee (the 2–3 things)
1. **G2 (etcd restore)**: when you can, get Proxmox (`192.168.0.182`) reachable and I'll run the restore drill.
2. **Review G3 evidence** in `kubernetes/storage-demo/README.md` — confirm it reads as portfolio-ready.
3. **Publish**: last, after G2 is reflected.

## What's ready to run on the go (no further input needed)
- **G2 drill**: once PVE is reachable — fresh-start playbook → restore drill (compressed snapshot) → verify Ready + clean log → G2 DONE → document. Each live step is `⚠ HUMAN APPROVAL REQUIRED` per `STORAGE-RECOVERY-PLAN.md`.

## Open PRs
- None (all merged to main: #60–#77, plus weekend PR #78/79).

## Big picture
- **G1:** DONE ✅ · **ntfy spam:** FIXED ✅ · **G2:** blocked on PVE · **G3:** DONE ✅ · **CI for k3s_app_backup:** DONE ✅ · **Hermes↔LM Studio:** RESOLVED ✅ · **Publish:** last (once G2 is reflected).
