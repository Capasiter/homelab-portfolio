# AI Decision Log — homelab-portfolio

> **Purpose:** the running record of *decisions and their rationale*, so no AI re-litigates a
> settled point and no future reader wonders *why* we did it this way. Newest first.
>
> **Last updated:** 2026-10-27 (America/Chicago) — added D-026-4 (agents roadmap → ROADMAP Phase 6) and D-026-5 (reasoning levels); P-4 parked. Previous: 2026-10-25 evening — folded in Lee’s stated preferences
> **Status:** FINAL (reconciled 2026-10-25; preferences folded in 2026-10-25 evening). Part of the shared brain; read via `INDEX.md`.

**Format per entry:** `Date — Decision — Rationale — Alternatives rejected — Revisit when?`

---

## 2026-10-26 — 2026-10-27

### D-026-4 — Lee’s local-assistance/agents roadmap is tracked as ROADMAP Phase 6 (agent decision, built on Lee’s own text)
- **Decision:** Lee’s “Local assistance, kept under human control” + “Kubernetes capabilities to evaluate” roadmap (already in `README.md` on main; re-pasted by Lee 2026-10-26) is tracked as **ROADMAP Phase 6** — an *evaluation* lane with per-step evidence bars.
- **Rationale:** Lee: “I want to use agents… AGENTS are the future… 2 or 3 agents and a brain.” The repo already carries his roadmap in the README; the brain sequences it instead of re-inventing it. The hard boundary is kept verbatim: agents gather evidence and prepare suggestions; Lee reviews findings and diffs; changes go through PR + repo checks; **no agent makes autonomous live-infrastructure changes**.
- **Audit note (2026-10-27):** the prior session’s handoff claimed this fold-in was done; the staged `ROADMAP.md` did not contain it. Restored this session, sourced from Lee’s exact README text.
- **Rejected:** treating Phase 6 as a build/commitment phase (it is evaluation until each evidence bar is met).
- **Revisit when:** Lee re-prioritizes, or a Phase 6 step is approved as a real build (it then gets its own phase entry).

### D-026-5 — Reasoning level: MED by default; HIGH/extra-high only for hard work
- **Decision:** Keep sessions at **MED** for routine steps. Use **HIGH/extra-high** only for hard work (e.g., G2 etcd reset-path root-cause, a large reconcile).
- **Rationale:** Lee’s own practice (D-026-3): he moved back to MED after one ~19-hour HIGH session, and chose extra-high only for “do it fully correctly” overnight work. The brain keeps steps small, so HIGH is rarely needed.
- **Rejected:** permanently HIGH (too slow for routine steps); permanently LOW (accuracy risk on hard debugging).
- **Revisit when:** Lee says otherwise.

## 2026-10-25 (evening — Lee's stated preferences)

### D-026-1 — Linux checkout is the canonical working copy
- **Decision:** The **Linux checkout** (`wickedgamingserver@devops-workstation:~/projects/homelab-portfolio`) is the canonical working copy, per Lee's explicit preference (2026-10-25 evening). The agent (Bionic) reads the Windows clone and the `Z:` handoff share directly, so *reading* never needs Lee; *executing* git/SSH on the Linux box is Lee's keyboard.
- **Rationale:** Lee: *"I keep wanting to use the linux… I like Hermes… it's faster, more accurate."* His real workflow is VS Code → Linux terminal → Hermes/Continue. Canonicalizing where he actually works removes the mismatch that caused the mess.
- **Supersedes:** D-025-3 (Windows-clone recommendation).
- **Revisit when:** Lee says otherwise, or a tool truly requires Windows.

### D-026-2 — Hermes is the preferred assistant; Continue is secondary
- **Decision:** Treat **Hermes** as the primary assistant for repo work and **Continue** as secondary (its parameters are not finished). Keep both available; do not force consolidation.
- **Rationale:** Lee: *"I like Hermes more, it's faster, more accurate… better than Continue because the parameters haven't been set all the way up yet."* He is also explicit he wants to *keep* Bionic + Hermes + Continue (D-025-1).
- **Rejected:** dropping Continue (Lee wants to keep learning the tooling).
- **Revisit when:** Continue's parameters are finished and Lee re-ranks them.

### D-026-3 — Optimize for small, fast, accurate steps (not one long session)
- **Decision:** Break work into **small, bounded, verifiable steps** with a quick check-in, rather than one very long autonomous session. Keep reasoning at **MED**. The brain (these docs) is the mechanism: it externalizes state so each step starts fast instead of re-deriving context.
- **Rationale:** Lee: *"I am just looking for efficiency… and accuracy!!… now I have to break this into smaller FASTER parts… [a prompt] took like 19 hours to answer it feels like… but that was on high so putting it back on med."* Accuracy is the top priority, but he does not want needless slowness.
- **Rejected:** bigger context windows as the fix (the fix is externalized state + smaller tasks, not more tokens).
- **Revisit when:** steps are consistently too small (churn) or too large (slow) in practice.

---

## 2026-10-25

### D-025-1 — Build a shared brain in the repo, not per-tool notes
- **Decision:** Put the operational brain in `docs/ai/` inside the repo, plus small Continue agents in `.continue/agents/`, so Bionic, Hermes, and Continue all read the same state.
- **Rationale:** Switching tools kept losing context (the "mess" Lee described). A file the repo owns is the only thing every tool can read. Lee: *"we need a brain and agents."*
- **Rejected:** consolidating onto one tool (Lee explicitly wants to keep Bionic + Hermes + Continue); keeping notes in a tool-specific workspace (doesn't travel, goes stale).
- **Revisit when:** a 4th tool is added, or the brain grows past what a handful of files can hold.

### D-025-2 — Evidence labels are mandatory (LIVE / CI / DOC / INFER)
- **Decision:** Every claim in docs/reports must carry one of these labels, and a "pass" must include command + output + exit code.
- **Rationale:** This project is Lee's job portfolio; a recruiter (or interviewer) may ask for the evidence. Confident-but-unverified claims are the exact failure mode that made the article read as "half-finished."
- **Rejected:** freeform "looks good."
- **Revisit when:** never — this is a hard rule.

### D-025-3 — Windows clone as the canonical working copy (proposed)
- **Decision:** Recommend the Windows clone `C:/Users/Lee/projects/homelab-portfolio` as the working copy, brought to `origin/main` `83818c1` after importing the Linux-only untracked files.
- **Rationale:** The agent can run git there directly, removing the slow "you run / I paste" loop for repo work. Live-infra work still needs Lee either way.
- **Rejected:** keeping the Linux checkout canonical (slower agent loop; its feature branch is redundant with main).
- **Revisit when:** Lee says no, or a tool requires Linux. **Superseded 2026-10-25 (evening) by D-026-1 — Lee prefers the Linux checkout as canonical.**

### D-025-4 — Reconcile the two brain halves by merge, not rewrite (executed 2026-10-25)
- **Decision:** Keep all 4 Linux `docs/ai/` docs; mark `HANDOFF.md` historical; keep `PROJECT_GUIDE.md` and `STORAGE-RECOVERY-PLAN.md` unchanged; finalize the 5 drafted state docs; add the 3 agents alongside the existing `.continue/agents/new-config.yaml` (a Continue Ollama **model** config — not an agent, left untouched); update the rule's read-first line to point at `SESSION_STATE.md`.
- **Rationale:** The two sets overlap only in the "current-state" role. `PROJECT_GUIDE.md` and `STORAGE-RECOVERY-PLAN.md` are genuinely strong, evidence-labeled, approval-gated docs the drafts do not cover. A single current-state doc (`SESSION_STATE.md`) ends the two-brains problem without deleting Lee's untracked work.
- **Rejected:** replacing the Linux docs with the drafts (would destroy the approval-gated recovery plan and the project guide); deleting `HANDOFF.md` (Lee's untracked history); treating `new-config.yaml` as one of the 3 agents (it is a model config).
- **Revisit when:** the brain outgrows ~10 files.

---

## 2026-10-24

### D-024-1 — A1 via Unraid root SSH (not NFS)
- **Decision:** Validate the etcd set over `ssh root@192.168.0.102` instead of the documented NFS path.
- **Rationale:** The NFS export is ACL'd to `.162`, which is unreachable; SSH is the approved, working path.
- **Rejected:** NFS mount from `.159` (blocked by ACL); waiting for `.162`.
- **Revisit when:** `.162` is restored and Lee wants the NFS path re-validated.

### D-024-2 — Read-only on live infra by default
- **Decision:** No writes to K3s / Unraid / Proxmox / firewall / Alertmanager / GitHub without an explicit, specific authorization.
- **Rationale:** It's a personal homelab Lee relies on; an accidental change is far costlier than a slow session.
- **Rejected:** "just try the change."
- **Revisit when:** Lee explicitly authorizes a specific action.

### D-024-3 — ntfy as the alert receiver (chosen, not yet deployed)
- **Decision:** Use ntfy for alert delivery (G1), pending Lee's exact topic URL + approval for exactly one test.
- **Rationale:** Lightweight, no extra infra, phone-native; fits "monitoring with teeth" without a new platform.
- **Rejected:** email/Slack/other (more moving parts, not yet needed).
- **Revisit when:** Lee picks a different channel.

---

## 2026-10-23

### D-023-1 — PVC full-volume build is gated on A1
- **Decision:** Do not start the PVC backup/restore build until the Unraid etcd set is proven complete and valid.
- **Rationale:** A1 is the prerequisite that proves the backup tier we're designing against actually exists. **Gate cleared by A1 PASS (2026-10-23).** Build still awaits Lee's "go."
- **Rejected:** building on the documented-only assumption.
- **Revisit when:** Lee says go.

### D-023-2 — Keep the token out of every artifact
- **Decision:** The real K3s token is checked for *presence + regular-file + 0600* only; never opened, hashed, printed, or copied.
- **Rationale:** A portfolio is public; a leaked token is a real incident and a disqualifying detail.
- **Rejected:** "just hash it to prove it exists" (the sidecar already proves integrity).
- **Revisit when:** never.

---

## Pending (Lee's call — not decided)

| ID | Decision | Blocking |
|---|---|---|
| P-1 | ✅ **Linux is canonical** (Lee's preference, D-026-1, 2026-10-25 evening) — remaining: his go to install the brain there and open the PR | Lee's OK to install |
| P-2 | PR #62 (README refresh, doc-only) — merge or leave open | Lee's OK |
| P-3 | PVC full-volume build — go | Lee's OK |
| P-4 | ntfy topic URL + one-test approval — **parked 2026-10-27: no topic URL has been supplied; no ntfy/Alertmanager change may be made before he does** | Lee's input + approval |
| P-5 | Publish article / LinkedIn / Medium — when | After G1–G3 reflected |
