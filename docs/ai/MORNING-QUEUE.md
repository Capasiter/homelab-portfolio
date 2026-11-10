# Morning Queue — the single live working queue

> **Purpose:** one place for *what's done, what's blocked, and the 2–3 things Lee must answer*. Replaces
> ad-hoc phone summaries (D-026-6). The agent updates this at the end of every work block; Lee answers the
> decisions; the agent executes. Keep it short — if it's long, split the work.
>
> **Rule:** this is a *queue*, not a log. `SESSION_STATE.md` is the full history; this file is only the
> live "next" and "needed." Mirror the "Needed from Lee" section to the phone when a work block finishes.

**Last updated:** 2026-11-08 (Bionic) — **CI checks for `k3s_app_backup` DONE + PR #78 open (CI green, mergeable)** — the `workflow`-scope blocker is cleared (branch pushed + PR opened from the Linux box). **Hermes ↔ LM Studio: RESOLVED** — reverse SSH tunnel + clean Hermes config (provider `lmstudio`, `base_url http://127.0.0.1:1235/v1`, model `qwen/qwen3.8-27b`, `streaming: false`) now work; `hermes -z` one-shot returns `HERMES-OK`. Hermes + Copilot both running in Herdr panes.

---

## Done (this stretch)
- **P-3 (gitignore) DONE:** `__pycache__/` + `*.pyc` already present in `.gitignore`; junk `scripts/def add_numbers(a, b):.py` gone from disk. (Queue had listed it pending — it was actually done; reconciled 2026-11-07.)
- **P-6 (storage-demo Explore row) DONE:** README "Explore the project" table now links `[Storage demo](kubernetes/storage-demo/README.md)` (2026-11-07).
- **P-7 (stale duplicate diagram) DONE:** deleted unreferenced `docs/diagrams/future-architecture.svg` (stale, content-different; live `diagrams/future-architecture.svg` untouched, md5 `278decac…`). Committed + pushed 2026-11-07.
- **G3 (PVC full-volume) DONE:** build (`k3s_app_backup` role, PR #75) + **first backup + Phase A non-destructive restore proof** (LIVE 2026-11-06). Backup artifact + per-file manifest on the export; Phase A recovered 100% of files with matching digests; live export untouched. Documented in `kubernetes/storage-demo/README.md` + main README. **Evidence bar met (design §5).**
- **Brain:** D-026-6 (standing unattended-OK list) + this queue + INDEX updated (PR #73).
- **G1 (alert delivery):** DONE + deployed + documented (PR #72).
- **ntfy spam:** FIXED — Watchdog routed to a `"null"` receiver (PR #70).
- **G2 (etcd restore):** diagnosis + runbook + fresh-start playbook merged (PRs #67/#68).

## Blocked
- **G2 execution:** Proxmox (192.168.0.182) unreachable from the Linux box (22/443/8006 closed). Needs Lee at the keyboard to restore the PVE/VM network path.
- **Publish:** last, after G2 is reflected in the narrative.

## Needed from Lee (the 2–3 things)
1. **Merge PR #78** (CI checks for `k3s_app_backup`) — CI green, mergeable. `gh pr merge 78 --squash --delete-branch`.
2. **G2 (etcd restore):** when you can, get Proxmox (192.168.0.182) reachable from the Linux box and I'll run the restore drill.
3. **Review the G3 evidence** in `kubernetes/storage-demo/README.md` — confirm it reads as you want for the portfolio. (Note: the "2026-11-06 section" label was not found in the file during the 2026-11-07 Hermes review — confirm the exact section heading before re-running that review.)

## What's ready to run on the go (no further input needed)
- **G2 drill:** once PVE is reachable — fresh-start playbook → restore drill (compressed snapshot) → verify Ready + clean log → G2 DONE → document. Each live step is `⚠ HUMAN APPROVAL REQUIRED` per `STORAGE-RECOVERY-PLAN.md`.

## Open PRs
- **PR #78** (OPEN, CI green, mergeable): CI checks for `k3s_app_backup` role — branch `ci/k3s-app-backup-validation`, commit `ee0de20`. Awaiting Lee's merge.
- Merged to main: #73 brain, #74 G3 design, #75 G3 build, #77 P-6/P-7 cleanup.

## Big picture
- **G1:** DONE ✅ · **ntfy spam:** FIXED ✅ · **G2:** blocked on PVE · **G3:** **DONE** (build + backup + Phase A proof, documented) ✅ · **CI for k3s_app_backup:** PR #78 open (CI green) · **Hermes↔LM Studio:** RESOLVED ✅ · **Publish:** last (once G2 is reflected).
