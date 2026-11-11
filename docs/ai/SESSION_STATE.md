## 7. Open questions for Lee (see also `DECISIONS.md` "Pending")

1. ✅ **DONE 2026-10-31**. Brain is on **main**: PR #63 squash-merged as `aa7f9ed` (CI green, run 41181539768); remote branch deleted; Windows clone synced to `main` @ `aa7f9ed` (old tip preserved in `backup/local-main-20261031`). Remaining: Linux canonical checkout sync (Lee at keyboard — §5 commands), then P-3/P-6/P-7 → G1 (needs his ntfy topic URL) → G2 → G3 → publish.
2. What exactly is **Hermes** (a tool? a folder?) and where does its state live?
3. **Cleanup (P-3, updated 2026-10-31):** junk file `scripts/def add_numbers(a, b):.py` + `__pycache__/` are **gone from the Windows clone's disk** (found during the 2026-10-31 resync). `.gitignore` still has **no** `pycache`/`.py` entry (grep exit 1). Remaining ask: OK to add a `__pycache__/` / `*.pyc` line to `.gitignore` (tiny PR), and confirm the same on the Linux checkout after its sync?
4. **P-2:** ✅ **DONE 2026-10-30 night** (Lee's go) — PR #62 squash-merged as `e236661` (2026-10-31T02:03:59Z); remote branch deleted; CI on merge push **success** (run 41158266043); `origin/main` now `e236661`.
5. **P-3:** PVC full-volume build (G3) — go?
6. **P-4:** ntfy topic URL + one-test approval (G1) — **parked 2026-10-27**: no URL supplied; the phone summary was delivered as a file instead.
7. **P-5:** Publish timing for the article / LinkedIn / Medium.
8. **P-6 (new 2026-10-28):** README "Explore the project" is missing a `kubernetes/storage-demo/` row (PR #52; dated live-validation records exist there). One-line fix drafted (`SCOPE-CHECK-20261028.md`) — apply as (a) tiny standalone PR, (b) folded into PR #62, or (c) the brain PR (not recommended)? Lee's call.
9. **P-7 (new 2026-10-29):** delete the stale duplicate `docs/diagrams/future-architecture.svg` (finding F1 — nothing references it; live diagram is `diagrams/future-architecture.svg`). OK to delete — standalone one-line PR or folded into an existing one? Lee's call. (`REPO-AUDIT-20261029.md`.)
