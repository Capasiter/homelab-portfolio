# Local AI workflow

Verified on October 3, 2026, using Continue in VS Code on
devops-workstation, with this workspace:

/home/wickedgamingserver/projects/homelab-portfolio

## Verified capabilities

- Continue generated responses using the configured local Ollama setup.
- The project rule "Homelab project guidance" appeared in Continue's rules list.
- Selected source was attached by opening a file, selecting its contents,
  and pressing Ctrl+L.
- Continue quoted the README's future AI roadmap entry accurately after
  clarification. Its quotation and supporting claims were checked against
  the actual README.
- Python autocomplete produced a suggestion that was accepted with Tab.
- Continue correctly identified default/data as Pending and ops/cache as
  Lost in an inline PVC fixture. Neither PVC was Bound.

## Human review findings

Continue initially misunderstood a request to quote the AI roadmap.
Clarifying that "quote" meant exact source wording corrected the response.

The initial PVC analysis included an unsupported explanation for Lost.
After a human challenged that claim, Continue removed it and clearly
separated observed phases from unknown causes.

A missing-source response declined to quote an unavailable script, but
referred to earlier conversation context. Fresh-chat isolation was not
conclusively verified.

These checks demonstrate useful assistance with human review. They do
not establish reliable autonomous incident diagnosis.

## Working procedure

1. Open the correct repository in VS Code.
2. Confirm the project guidance rule is visible.
3. Attach the source needed for each task and verify the attachment name.
4. Request explanations or focused changes with explicit scope.
5. Compare quotations and claims with source evidence.
6. Challenge unsupported claims and review proposed changes.
7. Run appropriate local checks before committing reviewed work.

Rules provide guidance; they do not enforce permissions or attach files
automatically. Do not assume attachments persist across chats.

## Boundaries and remaining work

Live cluster work remains paused. These exercises used source text,
a scratch file, and an inline fixture; they did not validate live cluster
behavior.

The PVC validator was absent from this Linux checkout during testing.
Validator code and integration completed in the Windows repository must
be inspected and reconciled separately before testing them here.

The active Continue configuration location, extension version, and Ollama
runtime location were not independently verified in this Linux session.
The existing .continue/agents/new-config.yaml was not inspected.

No deployment or push is part of this verification.

## Linux PVC follow-up

The earlier validator-absence note describes the initial checkout.
The Windows PVC commits were subsequently transferred using a Git bundle
and applied on feature/local-ai-pvc-workflow:

- afc2263: Add local PVC status validator.
- a1e1d18: Integrate PVC validator into K3s health check.

Both scripts passed bash syntax checking. The local validator test runner
reported 10 passed, 0 failed, with exit code 0. Full health-check integration
tests have not yet been repeated on Linux.

Continue explained the attached validator, but its first answer misplaced
empty-list success and omitted the missing-phase fallback. After correction,
it still confused format strings with rendered output and omitted leading
spaces from a quoted format string. Exact output claims require source review.

Continue correctly analyzed retrieval failure with valid JSON on stdout:
the else branch runs, the validator is skipped, and overall_status becomes 1.
Assuming later commands succeed, the script reaches RESULT: ATTENTION REQUIRED
and exits 1. This was a source-analysis exercise, not an execution test.

No live cluster access or push was performed.
