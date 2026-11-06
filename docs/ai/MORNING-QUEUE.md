# Morning Queue — the single live working queue

> **Purpose:** one place for *what's done, what's blocked, and the 2–3 things Lee must answer*. Replaces
> ad-hoc phone summaries (D-026-6). The agent updates this at the end of every work block; Lee answers the
> decisions; the agent executes. Keep it short — if it's long, split the work.
>
> **Rule:** this is a *queue*, not a log. `SESSION_STATE.md` is the full history; this file is only the
> live "next" and "needed." Mirror the "Needed from Lee" section to the phone when a work block finishes.

**Last updated:** 2026-11-05 (Bionic) — G3 chosen as the next build; brain updated with D-026-6 (standing unattended-OK list + this queue).

---

## Done (this stretch)
- **G3 (PVC full-volume) BUILD:** DONE — new `k3s_app_backup` role (backup script + timer + playbook), validated (bash -n, shellcheck, ansible syntax, template render all pass). PR #75 (CI green). **Run + Phase A proof pending Lee's go.**
- **Brain:** D-026-6 (standing unattended-OK list) + `MORNING-QUEUE.md` (this file) + INDEX updated.
- **G1 (alert delivery):** DONE + deployed + documented (README + observability README, PR #72 merged).
- **ntfy spam:** FIXED — Watchdog routed to a `"null"` receiver (PR #70 merged + deployed; verified LIVE).
- **G2 (etcd restore):** diagnosis + runbook + fresh-start playbook merged (PRs #67/#68).
- **G3 (PVC full-volume):** **design drafted** (PR #74, CI green) — funds `STORAGE-RECOVERY-PLAN.md` §6b.
- **Brain:** D-026-6 added (standing unattended-OK list + this queue); INDEX + working routine updated to use this queue.

## Blocked
- **G2 execution:** Proxmox (192.168.0.182) unreachable from the Linux box (22/443/8006 closed). Needs Lee at the keyboard to restore the PVE/VM network path.
- **Publish:** last, after G2 + G3 are reflected in the narrative.

## Needed from Lee (the 2–3 things)
1. **Approve the G3 build (PR #75) + design (PR #74 §7)** — then I'll run the **first backup + Phase A scratch-restore proof** (non-destructive) in an authorized window, with your go on each gated step.
2. **Add `workflow` scope to the `gh` token** (or I add the CI checks in a follow-up) — so the new role's CI checks (syntax + shellcheck + template render) run automatically. Currently blocked on this.
3. **Approve the standing "unattended OK" list** (D-026-6) — so I can merge docs-only PRs when CI green and batch the rest.

## What I'll do on the go (no further input needed)
- **G3 build:** write `k3s-app-backup.sh` + `k3s-app-backup.timer` (mirroring the etcd backup conventions) → first run + **Phase A non-destructive scratch-restore proof** (verify 100% of manifest files) → capture evidence → document in the storage-demo README → update the brain + this queue → phone summary.
- Each live step is `⚠ HUMAN APPROVAL REQUIRED` per `STORAGE-RECOVERY-PLAN.md`; I'll name each one before running it.

## Open PRs (all CI green)
- **#73** — brain update (narrative + G3 + D-026-6). Merge: `gh pr merge 73 --squash --delete-branch`
- **#74** — G3 design doc. Review §7, then merge or ask for changes.
- **#75** — G3 build (k3s_app_backup role). Review, then merge or ask for changes.

## Big picture
- **G1:** DONE ✅ · **ntfy spam:** FIXED ✅ · **G2:** blocked on PVE · **G3:** design + **BUILD done (PR #75)** — run + proof pending · **Publish:** last.
