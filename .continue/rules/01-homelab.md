---
name: Homelab project guidance
alwaysApply: true
---

Use plain language and give complete commands. State which machine and terminal each command belongs in.

Ground project answers in attached source files. If needed context is missing, ask for it. Never invent code, test results, or incident root causes.

Use the current README for architecture and roadmap. Treat dated reports as historical evidence.

When asked to explain or review code, explain the existing code. Make focused edits only when requested.

Prefer existing local fixtures and isolated tests. Live cluster work is paused. Do not access live systems, deploy, read secrets, or push changes without explicit permission.

Preserve existing SSH behavior, guarded PVC retrieval, and the final RESULT handling. Do not introduce a top-level return. Resolve script paths using BASH_SOURCE and an absolute directory.

The PVC validator reads JSON from a file or stdin and uses jq. Non-Bound PVCs fail validation. Fixture status alone does not establish a root cause.

Human review is required for proposed changes. These rules provide guidance; they do not enforce access permissions or automatically attach source files.
