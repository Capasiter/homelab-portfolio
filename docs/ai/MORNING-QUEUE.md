# Morning Queue — the single live working queue

> **Purpose:** one place for *what's done, what's blocked, and the 2–3 things Lee must answer*. Replaces
> ad-hoc phone summaries (D-026-6). The agent updates this at the end of every work block; Lee answers the
> decisions; the agent executes. Keep it short — if it's long, split the work.
>
> **Rule:** this is a *queue*, not a log. `SESSION_STATE.md` is the full history; this file is only the
> live "next" and "needed." Mirror the "Needed from Lee" section to the phone when a work block finishes.

**Last updated:** 2026-11-07 (Bionic) — **P-3/P-6/P-7 cleanup DONE** (gitignore already in place; storage-demo Explore row added to README; stale duplicate `docs/diagrams/future-architecture.svg` removed). Committed + pushed. **Hermes/LM Studio:** Hermes could not see the local LM Studio models during the 2026-11-06/07 Herdr test — connection setup deferred to 2026-11-07.

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
- **CI checks for `k3s_app_backup`:** the `gh` OAuth token lacks the `workflow` scope, so the workflow-file change (syntax + shellcheck + template render for the new role) can't be pushed/merged by the agent. Lee: add `workflow` scope to the token, or merge the CI-checks branch from your browser.
- **Publish:** last, after G2 is reflected in the narrative.

## Needed from Lee (the 2–3 things)
1. **Add `workflow` scope to the `gh` token** (or merge the CI-checks branch from your browser) — so the new role's CI checks run automatically.
2. **G2 (etcd restore):** when you can, get Proxmox (192.168.0.182) reachable from the Linux box and I'll run the restore drill.
3. **Review the G3 evidence** in `kubernetes/storage-demo/README.md` (the 2026-11-06 section) — confirm it reads as you want for the portfolio.
4. **Hermes ↔ LM Studio:** Hermes couldn't see the local LM Studio models during the Herdr test. When ready, point Hermes at the LM Studio OpenAI-compatible endpoint (see `docs/ai/local-ai-connection.md`) so it can run in a Herdr pane against the local models.

## What's ready to run on the go (no further input needed)
- **G2 drill:** once PVE is reachable — fresh-start playbook → restore drill (compressed snapshot) → verify Ready + clean log → G2 DONE → document. Each live step is `⚠ HUMAN APPROVAL REQUIRED` per `STORAGE-RECOVERY-PLAN.md`.

## Open PRs
- None (all merged to main: #73 brain, #74 G3 design, #75 G3 build).
- **Pending (blocked on `workflow` scope):** the CI-checks branch (`bionic/g3-ci-checks-20261106`) — add the role's CI checks to the workflow.

## Big picture
- **G1:** DONE ✅ · **ntfy spam:** FIXED ✅ · **G2:** blocked on PVE · **G3:** **DONE** (build + backup + Phase A proof, documented) ✅ · **Publish:** last (once G2 is reflected).
