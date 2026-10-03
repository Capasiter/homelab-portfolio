#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v jq >/dev/null 2>&1; then
  printf 'ERROR: jq is required but was not found in PATH.\n' >&2
  exit 1
fi

input=${1-}
if [[ -n "$input" && "$input" != "-" ]]; then
  if [[ ! -f "$input" ]]; then
    printf 'ERROR: input file does not exist: %s\n' "$input" >&2
    exit 1
  fi
  if [[ ! -r "$input" ]]; then
    printf 'ERROR: input file is not readable: %s\n' "$input" >&2
    exit 1
  fi
  json=$(<"$input")
else
  json=$(cat)
fi

if [[ -z "$json" ]]; then
  printf 'ERROR: input is empty.\n' >&2
  exit 1
fi

if ! jq -s -e 'length == 1 and (.[0] | type == "object")' >/dev/null 2>&1 <<<"$json"; then
  printf 'ERROR: input must contain exactly one valid JSON object.\n' >&2
  exit 1
fi

if ! jq -e '.items | type == "array"' >/dev/null 2>&1 <<<"$json"; then
  printf 'ERROR: invalid document structure: items must be an array.\n' >&2
  exit 1
fi

if [[ "$(jq '.items | length' <<<"$json")" -eq 0 ]]; then
  printf 'No PVCs\n'
  exit 0
fi

failures=()
while IFS= read -r pvc; do
  if ! jq -e 'type == "object" and (.metadata | type == "object") and (.status | type == "object")' >/dev/null 2>&1 <<<"$pvc"; then
    failures+=("invalid PVC entry")
    continue
  fi
  namespace=$(jq -r '.metadata.namespace // empty' <<<"$pvc")
  name=$(jq -r '.metadata.name // empty' <<<"$pvc")
  phase=$(jq -r '.status.phase // empty' <<<"$pvc")
  if [[ -z "$namespace" || -z "$name" ]]; then
    failures+=("invalid PVC identity (namespace/name required)")
  elif [[ "$phase" != "Bound" ]]; then
    failures+=("$namespace/$name (${phase:-missing phase})")
  fi
done < <(jq -c '.items[]' <<<"$json")

if ((${#failures[@]})); then
  printf 'ERROR: failing PVCs:\n' >&2
  printf '  %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'All PVCs are Bound\n'
