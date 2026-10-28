# AI Session State — homelab-portfolio

> **Read this first.** This is the single source of truth for *where the project is right now*.
> Every AI tool (Bionic, Hermes, Continue) should read it before doing anything, and the active
> agent should update it at the end of each work session.
>
> **Last updated:** 2026-10-27 (America/Chicago) — by Bionic (continuation): audited all 16 staged files; restored the install package; added ROADMAP Phase 6 + D-026-4/5; brain installed locally on `feature/ai-brain` (not pushed). Previous: 2026-10-25 evening — by Bionic; folded in Lee's preferences
> **Status:** FINAL (reconciled 2026-10-25 with the Linux `docs/ai/` set; preferences folded in 2026-10-25
> evening). `HANDOFF.md` in this
> directory is the **historical archive**; this file is the current-state doc.

---

## 1. One-line status

The backup **tier is proven valid** (etcd set + daily timer, both live-verified) and both
validators are **merged to main**. The shared brain (these docs + agents + rule) is reconciled
and staged. Remaining work: close the 3 honest gaps (alert delivery, full etcd restore, PVC
full-volume backup), then make the public narrative match the evidence.

> **Lee's stated preferences (2026-10-25 evening):** **Linux is the canonical machine** (not Windows).
> **Hermes is preferred** over Continue (Continue's parameters aren't finished yet). He wants **agents + a
> brain** — "agents are the future" — with 2–3 agents. He values **accuracy above all, then speed**, and wants
> work broken into **smaller, faster steps** (a single ~19h session felt too slow; he moved reasoning back to
> **MED**). Context size is *not* the bottleneck — the brain externalizes state so each step starts fast. See
> `DECISIONS.md` D-026-1/2/3 and `MORNING-ANSWERS.md` in the staging folder.

## 1.1 Session log (newest first)

- **2026-10-27 (Bionic continuation, Lee away at work):** standing order “do what you can… make it the best you have ever seen” → safe local-only, reversible, **no push** work. (1) Read all 16 staged files; audited for inconsistencies. (2) Restored the missing install package (`install-brain.sh` + `INSTALL-STEPS.md`). (3) Fixed the staging README count (13 install + 3 staging-only = 16). (4) Added ROADMAP **Phase 6** (Lee’s agents roadmap, sourced from `README.md` on main) + **D-026-4/5** — the prior handoff claimed the fold-in but the staged ROADMAP lacked it. (5) **Installed the brain into the Windows clone** on `feature/ai-brain` from `origin/main` `83818c1`; committed locally; **not pushed**; Lee’s untracked files preserved; pre-install rule backed up to staging `backup-rules/`. (6) Phone summary delivered as `PHONE-SUMMARY.md` (no ntfy topic URL exists — parked, P-4).
- **2026-10-26 (Bionic):** Lee approved “install the brain”; `MORNING-ANSWERS.md` written (his 7 questions); Lee’s local-assistance roadmap pasted into the record; overnight session at extra-high reasoning.
- **2026-10-25 (Bionic):** brain reconciled (merge, not rewrite) and staged at `Z:\AI-Assistant\handoffs\ai-brain-final\`; Lee’s preferences folded in (D-026-1/2/3).

## 2. Where the code lives (verified 2026-10-25)

| Checkout | Location | Branch @ HEAD | State |
|---|---|---|---|
| **Linux (Lee's VS Code)** | `~/projects/homelab-portfolio` | `feature/backup-artifact-validator` @ `a43692a` | Freshest history. Holds untracked `docs/ai/` (4 files), `.continue/agents/new-config.yaml` (a Continue **model** config — not an agent), modified `.continue/rules/01-homelab.md`, and a junk file `scripts/def add_numbers(a, b):.py`. Its local `main` label is stale (`c63fe10`); the remote is ahead. |
| **Windows** | `C:/Users/Lee/projects/homelab-portfolio` | `review/pvc-integration-20261010` @ `f9cbb74` | Stale (Oct 10). Untracked: `.continue/` (rules only), `docs/argocd-prep/`, `docs/local-ai-workflow.md`. No `docs/ai/`. |
| **origin/main (source of truth)** | GitHub `Capasiter/homelab-portfolio` | `83818c1d27f235e4c4988f7bd3bfacc931d09b4b` | #60 (checksum validator, `2e5fe13`) + #61 (PVC validator, `83818c1`) merged. **PR #62 OPEN** (doc-only README refresh; head `bionic/homepage-refresh-20261021` @ `d1333b1`, base `main`). Verified via GitHub API 2026-10-25. |

**Canonical working copy (P-1):** the **Linux checkout** — Lee's stated preference (D-026-1, 2026-10-25
evening). It holds the freshest history and the untracked `docs/ai/` brain. Bionic reads the Windows clone and
the `Z:` share directly, so *reading* never needs Lee; only *executing* on the Linux box does. Install procedure
is in the staging folder README: `Z:\AI-Assistant\handoffs\ai-brain-final\README.md`.

## 3. What is proven (direct evidence this cycle)

| Item | Status | Evidence |
|---|---|---|
| etcd backup set: 1 baseline + 3 rolling + token + token sidecar | ✅ PASS | A1 2026-10-23: `sha256sum -c` 4/4 OK; token 0600 root:root; sidecar format valid; newest rolling 2026-10-23 03:23 CDT |
| Daily backup timer active + on schedule | ✅ PASS | E1 2026-10-24: `k3s-backup.timer` Active, last 03:20 CDT, next 03:22 CDT |
| Cluster healthy: 3/3 nodes Ready, 4/4 PVCs Bound | ✅ PASS | E1 2026-10-24: `v1.36.2+k3s1`; `storage-demo-data` NFS RWX 1Gi |
| Checksum validator (sidecar format enforced) | ✅ merged | PR #60 → main `2e5fe13` |
| PVC status validator + health-check integration | ✅ merged | PR #61 → main `83818c1` |

## 4. What is NOT done (the honest gaps)

| # | Gap | Why it matters | Blocked on |
|---|---|---|---|
| G1 | **Alert delivery** — no `route`/`receivers` in Alertmanager (E1-confirmed: Grafana overview ConfigMap only) | A cluster that can't page is "monitoring without teeth" | Lee's exact ntfy topic URL + approval for exactly one test notification |
| G2 | **Full etcd restore** | The #1 SRE interview question; repeatable K3s reset-path panic on `v1.36.2+k3s1` | Isolated env + a working reset path + Lee's go |
| G3 | **PVC full-volume backup + restore** | Proves data survives node loss for real workloads | Gate cleared (A1); approval-gated procedure in `STORAGE-RECOVERY-PLAN.md` §6b; awaiting Lee's "go" |
| G4 | Argo CD **auto-sync + pruning** | Currently manual sync only | Lee's go |

## 5. Next action (sequenced)

1. ✅ **Done 2026-10-25:** draft the 5 standing docs + 3 agents + rule; capture the Linux `docs/ai/`; **reconcile (merge)** into the final set, staged at `Z:\AI-Assistant\handoffs\ai-brain-final\`.
2. ✅ **Done 2026-10-27:** installed into the Windows clone on `feature/ai-brain` (from `origin/main` `83818c1`) — committed locally, **not pushed**; Lee’s untracked files preserved; pre-install rule backed up to staging `backup-rules/`. Remaining (Lee’s go): push + open the doc-only PR (base `main` ← head `feature/ai-brain`) → merge after CI → sync the Linux checkout (back up its 4 untracked `docs/ai/` files first — see `INSTALL-STEPS.md`).
3. **Then, each gated on Lee's go:** G1 alert delivery (**parked** — needs his ntfy topic URL + one-test approval) → G2 etcd restore drill → G3 PVC full-volume backup/restore.
4. **Last:** publish the article / LinkedIn / Medium once the gap work above is reflected in the narrative.

## 6. Standing rules (never violate)

- **Evidence first:** label every conclusion `LIVE` / `CI` / `DOC` / `INFER`. Never claim "passed" without the command, its output, and the exit code.
- **Read-only on live infra** unless Lee explicitly authorizes the specific change.
- **Never** put a password, token, kubeconfig credential, or the real K3s token into chat, a command, a report, or a handoff. Lee types passwords at the keyboard.
- **No** commit / push / merge / reset / delete of unrelated work without Lee's explicit go.
- **No** ntfy or Alertmanager changes until Lee supplies the exact topic URL and approves exactly one test.
- Small steps. The repo is the source of truth. Accuracy over speed — but don't be needlessly slow.

## 7. Open questions for Lee (see also `DECISIONS.md` "Pending")

1. **P-1:** ✅ Resolved by Lee's preference — **Linux is canonical** (D-026-1). Remaining: his go to *install* the brain into the Linux checkout and open the PR.
2. What exactly is **Hermes** (a tool? a folder?) and where does its state live?
3. **Cleanup:** OK to delete the junk file `scripts/def add_numbers(a, b):.py` (a stopped/failed AI save) and gitignore `scripts/__pycache__/`?
4. **P-2:** PR #62 (doc-only README refresh) — merge or leave open?
5. **P-3:** PVC full-volume build (G3) — go?
6. **P-4:** ntfy topic URL + one-test approval (G1) — **parked 2026-10-27**: no URL supplied; the phone summary was delivered as a file instead.
7. **P-5:** Publish timing for the article / LinkedIn / Medium.
