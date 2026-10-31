---
name: Homelab project guidance
alwaysApply: true
---

Before every task, read `docs/ai/INDEX.md`, then `docs/ai/SESSION_STATE.md`, then the task-specific doc named by the index. Do not re-derive project context from scratch. Update `SESSION_STATE.md` after each completed task.

Use plain language and give complete commands. State which machine and terminal each command belongs in.

Ground project answers in attached source files. If needed context is missing, ask for it. Never invent code, test results, or incident root causes.

Evidence discipline: for any check, state which of planned, attempted, executed, and passed actually happened. Before claiming a test or parser passed, report the exact command and its actual output or exit status. Code review or editor lint alone does not prove a test or parser passed. Label every conclusion `LIVE` / `CI` / `DOC` / `INFER`.

Use the current README for architecture and roadmap. Treat dated reports as historical evidence.

When asked to explain or review code, explain the existing code. Make focused edits only when requested.

Preserve existing work, including untracked and uncommitted files, unless explicitly told otherwise.

Prefer existing local fixtures and isolated tests. Live cluster work is paused. Do not access secrets or live infrastructure, deploy, run destructive commands, or commit or push changes without explicit approval.

Secrets protocol: never ask Lee to paste, dictate, save, or print a credential. When a password or passphrase prompt appears, stop and tell Lee exactly which prompt is waiting; Lee types it at the keyboard.

No ntfy or Alertmanager changes until Lee supplies the exact topic URL and approves exactly one test.

Preserve existing SSH behavior, guarded PVC retrieval, and the final RESULT handling; do not introduce a top-level return. Resolve script paths using BASH_SOURCE and an absolute directory.

The PVC validator reads JSON from a file or stdin and uses jq. Non-Bound PVCs fail validation. Fixture status alone does not establish a root cause.

Specialist agents are available under `.continue/agents/`: `validator` (verify one thing, read-only), `docs` (keep the public narrative honest), `infra` (exact read-only commands for live systems). Use the one whose job matches the task; none may modify live state.

Human review is required for proposed changes. These rules provide guidance; they do not enforce access permissions or automatically attach source files.
