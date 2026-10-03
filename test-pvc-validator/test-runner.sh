#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$root/scripts/pvc-status-validator.sh"
fixtures="$root/test-pvc-validator/fixtures"
pass=0
fail=0

expect_success() { local label=$1; shift; if "$@" >/dev/null 2>&1; then ((pass+=1)); else printf 'FAIL: %s\n' "$label"; ((fail+=1)); fi; }
expect_failure() { local label=$1; shift; if "$@" >/dev/null 2>&1; then printf 'FAIL: %s\n' "$label"; ((fail+=1)); else ((pass+=1)); fi; }

expect_success bound "$validator" "$fixtures/bound.json"
expect_success empty "$validator" "$fixtures/empty.json"
expect_failure pending "$validator" "$fixtures/pending.json"
expect_failure missing-phase "$validator" "$fixtures/missing-phase.json"
expect_failure missing-identity "$validator" "$fixtures/missing-identity.json"
expect_failure malformed "$validator" "$fixtures/malformed.json"
expect_failure missing-structure "$validator" "$fixtures/missing-structure.json"
expect_failure multiple-documents bash -c "cat '$fixtures/bound.json' '$fixtures/empty.json' | '$validator' -"
expect_failure missing-file "$validator" "$fixtures/does-not-exist.json"
expect_success stdin bash -c "cat '$fixtures/bound.json' | '$validator' -"
printf '%s passed, %s failed\n' "$pass" "$fail"
((fail == 0))
