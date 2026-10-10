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

## Linux integration verification

On October 3, 2026, a temporary fake-SSH harness ran the health-check script
from outside the repository directory. All 10 cases passed: Bound, empty,
Pending, missing phase, missing identity, malformed JSON, missing structure,
multiple documents, retrieval failure, and retrieval failure with valid JSON
on stdout.

Checks confirmed expected exit codes, later-check execution, and final RESULT
output. Retrieval failures emitted the retrieval error and skipped validator
success output. No cluster connection was made. The temporary harness was
removed after execution.

## Hermes supervised pilot and live-check follow-up

Hermes read `docs/local-ai-workflow.md` and summarized user-supplied evidence. It did not execute the health, backup, checksum, or restore checks.

User-supplied observations:

- `k3s-health-check.sh` reported `RESULT: PASS`.
- All PVCs were Bound; no pods required attention.
- The backup timer was active and enabled.
- The backup service reported `Result=success` and `ExecMainStatus=0`.
- Snapshot and token checksum checks returned `OK`.

Backup freshness is not established by the supplied review evidence, which lacked a backup timestamp, reference time, and freshness threshold. No completed full restore-test result was supplied. Service success and matching checksums do not establish proven recoverability.

Initial AI answers omitted a freshness threshold and confused an active timer with boot enablement. Human review corrected both. A separate fresh-session test, reviewed by Lee, correctly classified three unsupported claims and one supported timer observation.

File tools were enabled. Read-only instructions were a task constraint, not an enforced technical permission boundary. This pilot demonstrates supervised assistance, not reliable autonomous operations.
