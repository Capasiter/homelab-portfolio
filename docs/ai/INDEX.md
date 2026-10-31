# Shared AI Notes — Index (entry point)

> **Start here.** This index is the entry point for every AI tool (Bionic, Hermes, Continue) and every
> human working in this repository. Read this first, then the document that matches what you're doing.
>
> **Last updated:** 2026-10-25 (America/Chicago) — reconciled into the single shared brain.
>
> **Rule:** state lives in the repo. A file here is the only context that is (a) readable by every tool,
> (b) versioned, and (c) survives any one session dying.

---

## 1. The documents, and when to read them

| You are doing… | Read this first |
|---|---|
| **Anything at all** (start of every session) | `SESSION_STATE.md` — the single current-state source of truth |
| Reaching a machine, running a command, "why is this path blocked?" | `ACCESS.md` — machines, working paths, blocked paths, password protocol |
| Wondering why a decision was made, or proposing a new one | `DECISIONS.md` — decision log with rationale + pending items |
| Planning work, or reporting progress against the goal | `ROADMAP.md` — phases, evidence bars, sequencing rationale |
| Explaining a capability to Lee, a recruiter, or an interviewer | `WHY.md` — operating principles + the employer-facing "why" |
| Needing the full map of the project (folders, automation, Argo CD, CI, limits) | `PROJECT_GUIDE.md` — standing reference, grounded in repo files |
| Running the approval-gated storage recovery checks | `STORAGE-RECOVERY-PLAN.md` — every data-modifying step is `⚠ HUMAN APPROVAL REQUIRED` |
| Historical context (PR #54/#55 era handoff) | `HANDOFF.md` — **archive only**; current state is `SESSION_STATE.md` |

## 2. Evidence labels (mandatory on every claim)

| Label | Meaning |
|---|---|
| `LIVE` | A command was run against the live system. Must include the exact command, its output, and its exit code. |
| `CI` | A merged green PR on `origin/main` (cite the PR number). |
| `DOC` | Stated in a repository file; not re-run this session. |
| `INFER` | Derived from other evidence; state the basis of the inference. |

A "pass" without a command + output + exit code is not a pass. Code review or editor lint alone does not
prove a test or parser passed.

## 3. Working routine (every task, every tool)

1. **Read the notes.** This index → `SESSION_STATE.md` → the task-specific document above.
2. **Verify claims against source.** Treat README claims as historical evidence (`DOC`). Confirm anything
   you rely on by reading the cited file or evidence artifact in this session. Never infer live system
   state from documentation or fixtures.
3. **Do one bounded task.** Make the smallest change that accomplishes the stated task. Do not run
   live-infrastructure commands, commit, or push without explicit permission.
4. **Verify.** Re-read changed files; confirm the result is grounded in repository content, not assumed.
5. **Update `SESSION_STATE.md`.** Record what changed, what was verified, and any new known limits or
   open questions.

## 4. Hard rules (never violate — full text in `WHY.md` §A and `DECISIONS.md`)

- Read-only on live infrastructure unless Lee explicitly authorizes the specific change.
- Credentials never leave the keyboard: Lee types passwords/passphrases at the prompt; the agent stops
  and names the prompt that is waiting.
- The real K3s token is never read, printed, hashed, or copied — checked for presence + regular-file + 0600 only.
- No commit / push / merge / reset / delete of unrelated work without Lee's explicit go.
- No Alertmanager or ntfy changes until Lee supplies the exact topic URL and approves exactly one test.
