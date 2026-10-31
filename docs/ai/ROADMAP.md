# AI Roadmap — homelab-portfolio

> **Purpose:** the ordered plan to take the project from "backups proven, narrative catching up"
> to "recruiter-ready," with a **concrete evidence bar** for every step so "done" is never vibes.
>
> **Target:** recruiter-ready **after 2027-01-01** (~5–6 weeks from 2026-10-25). No rush; accuracy first.
>
> **Status:** FINAL (reconciled 2026-10-25). Part of the shared brain; read via `INDEX.md`.
>
> **Rule:** a step is *done* only when its **evidence bar** is met (command + output + exit code, or
> a merged green PR). Otherwise it is *in progress* or *blocked*.

---

## Phase 0 — Set up the brain + a clean checkout (this week)
*Unblocks speed; no live-infra changes.*

| # | Step | Done = evidence |
|---|---|---|
| 0.1 | Reconcile the 5 `docs/ai/` docs with the existing Linux `INDEX/HANDOFF/PROJECT_GUIDE/STORAGE-RECOVERY-PLAN` (one brain) | ✅ **DONE 2026-10-25** — merged set staged at `Z:\AI-Assistant\handoffs\ai-brain-final\`; awaiting install + Lee's approval |
| 0.2 | Choose canonical checkout; bring it to `origin/main` `83818c1`; import Linux-only untracked files | `git status` clean-ish; `docs/ai/` + `.continue/agents/` present in the working copy |
| 0.3 | Add Continue agents + one-line rule; verify Continue loads the brain | A Continue session reads `SESSION_STATE.md` before acting (Lee confirms) |
| 0.4 | Decide junk file `scripts/def add_numbers(a, b):.py` + `scripts/__pycache__/` (delete / gitignore) | `git status` shows no junk; Lee approved each removal |

## Phase 1 — Make the public narrative match the evidence (this week)
*Lowest risk, highest credibility gain. No live-infra changes.*

| # | Step | Done = evidence |
|---|---|---|
| 1.1 | Update the article draft: etcd set **now proven** (A1), timer **now confirmed** (E1) | Article no longer says "I have not seen it live"; cites A1/E1 dates + evidence |
| 1.2 | Confirm the README/CHANGELOG labels are accurate to main `83818c1` | README "done/in-progress" lines match the evidence table in `SESSION_STATE.md` §3–4 |
| 1.3 | Retire the stale `kb/argocd-inspection` (pre-install) into the new brain or archive it | No doc still says Argo CD is "pre-install" while it is deployed |
| 1.4 | Commit narrative fixes to a branch → PR → (Lee's OK) merge | Merged PR with green CI; `origin/main` advances |

## Phase 2 — Alert delivery: "monitoring with teeth" (G1)
*The first real build. Needs Lee's ntfy topic URL + approval for exactly one test.*

| # | Step | Done = evidence |
|---|---|---|
| 2.1 | Draft the Alertmanager `route` + `receivers` (ntfy) as a manifest in the repo | Manifest present in repo; reviewed |
| 2.2 | Apply (Lee's go) + confirm `get cm` / `get deploy` show the config | Live `kubectl get` shows the new route/receiver; exit 0 |
| 2.3 | Fire exactly one test alert; confirm it lands in ntfy | One delivered notification (Lee confirms on phone) — **only after explicit approval** |
| 2.4 | Document the alert path + the one test in the article | Article has an "alert delivery" section with the test as evidence |

## Phase 3 — Full etcd restore drill (G2)
*The #1 SRE question. Needs an isolated env and a working K3s reset path.*

| # | Step | Done = evidence |
|---|---|---|
| 3.1 | Root-cause the `v1.36.2+k3s1` reset-path panic (read-only diagnosis first) | A written diagnosis with the exact failing step + a candidate fix |
| 3.2 | Build a repeatable restore drill in an **isolated** environment (not the live cluster) | A runbook that restores etcd from a snapshot and returns the cluster Ready — with logs |
| 3.3 | Run the drill end-to-end; capture before/after `get nodes` + `sha256sum -c` | Cluster Ready after restore; snapshot integrity OK; exit codes captured |
| 3.4 | Document the drill as a portfolio artifact | Article has a "full etcd restore" section with the drill as evidence |

## Phase 4 — PVC full-volume backup + restore (G3)
*The biggest engineering build. Gate cleared by A1; needs Lee's "go."*

The approval-gated live-check procedure **already exists** in `STORAGE-RECOVERY-PLAN.md` (§6b full-volume
recovery, §3–5 cross-node checks). This phase funds the backup method it currently calls missing; the
plan's approval model and abort conditions apply unchanged.

| # | Step | Done = evidence |
|---|---|---|
| 4.1 | Finalize the PVC backup/restore design against the real Unraid tier | Design doc references A1-verified paths; Lee approves |
| 4.2 | Implement backup + a restore path (repo manifests + scripts) | Code + manifests in repo; CI green |
| 4.3 | Prove it: back up `storage-demo-data`, restore to a fresh PVC, compare content | Byte-for-byte match (SHA + `cmp`) across the restore; exit codes captured |
| 4.4 | Document it | Article has a "PVC full-volume backup/restore" section with the proof |

## Phase 5 — Polish + publish (after Phases 1–4 are reflected)
| # | Step | Done = evidence |
|---|---|---|
| 5.1 | Consistency audit: every public claim maps to an evidence label | An audit table with no "unverified" claims left |
| 5.2 | Finalize the article + LinkedIn + Medium posts (when Lee is ready) | Lee approves the text; published |

---

## Phase 6 — Local assistance under human control (the agents roadmap)
*Source: `README.md` on main — “Local assistance, kept under human control” + “Kubernetes capabilities to evaluate” (Lee’s own roadmap text, 2026-10-26). This is an **evaluation** lane: nothing in it is “done” until its evidence bar is met.*

**Hard rule (Lee, verbatim from README):** Agents should gather evidence and prepare suggestions. Lee reviews the findings and code diff; changes go through a pull request and repository checks. No agent should make autonomous live infrastructure changes.

| # | Step | Done = evidence |
|---|---|---|
| 6.1 | Desktop model server: start with **one active model** (LM Studio; 2× RTX 3060 12 GB, 48 GB RAM); queue jobs; measure fit/speed/context/tool use before adding concurrency | Baseline recorded: model, task, tokens/sec, context used, pass/fail |
| 6.2 | Dedicated Linux agent VM **outside** K3s (same Proxmox host — documented, not host-level redundancy) | VM provisioned via the repo’s OpenTofu; the shared-host limit stated in its docs |
| 6.3 | Evaluate **Hermes**: recurring health/capacity reports, backup-freshness checks, incident triage — scoped read-only tools | A sample report generated from read-only data; Lee reviews it |
| 6.4 | Evaluate **Continue/OpenCode**: preparing Ansible/OpenTofu/K8s changes on a separate branch | A prepared change exists on a branch; Lee reviews the diff; no autonomous merge |
| 6.5 | Evaluate **K8sGPT**: diagnosis from the agent VM; confirm a supported local-model connection before relying on it | Connection confirmed + one diagnosis with evidence (command + output) |
| 6.6 | **Prime Agent** — optional comparison on one longer investigation | A side-by-side note recorded |
| 6.7 | Kubernetes capabilities: **Headlamp, Loki, cert-manager, NetworkPolicies** — each needs a deployment plan, access boundaries, and validation before being described as operational | Per capability: plan + validation evidence in the repo |

## Sequencing rationale (why this order)
1. **Brain + clean checkout first** — it makes every later step faster and stops the context-loss that caused the mess.
2. **Narrative next** — it's the cheapest credibility win and is safe (no infra changes).
3. **Alert delivery before the restore drills** — it's small, high-signal ("monitoring with teeth"), and unblocks the teaching layer.
4. **etcd restore before PVC full-volume** — restore is the #1 SRE question and the smaller build; PVC full-volume is the largest and benefits from the restore discipline.
5. **Publish last** — so the public story is fully backed by evidence.
6. **Agents are an evaluation lane (Phase 6)**, not a build commitment — Lee’s local-assistance roadmap (README) is tracked with per-step evidence bars, runs in parallel, and must never be described as operational until validated; it never outranks G1–G3.

## Explicitly out of scope (until Lee says otherwise)
- Argo CD auto-sync + pruning (G4) — parked; do it after the above if time allows.
- PVC cross-node rescheduling test — parked (it is Check 3 in `STORAGE-RECOVERY-PLAN.md`).
- Any ntfy/Alertmanager change before Lee's URL + one-test approval.
- Any live-infra write without explicit authorization.
