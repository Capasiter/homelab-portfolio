#!/usr/bin/env bash

set -Eeuo pipefail

readonly K3S_SSH_HOST="${K3S_SSH_HOST:-k3s-server-01}"
readonly WEB_NAMESPACE="${WEB_NAMESPACE:-k8s-learning}"
readonly MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
readonly -a SSH_OPTIONS=(-o BatchMode=yes -o ConnectTimeout=10)

overall_status=0

section() {
  printf '\n=== %s ===\n' "$1"
}

run_check() {
  if ! "$@"; then
    overall_status=1
  fi
}

remote_kubectl() {
  local remote_command
  printf -v remote_command '%q ' sudo -n k3s kubectl "$@"
  ssh "${SSH_OPTIONS[@]}" "$K3S_SSH_HOST" "$remote_command"
}

if ! command -v ssh >/dev/null 2>&1; then
  printf 'ERROR: ssh was not found in PATH.\n' >&2
  exit 1
fi

printf 'K3s health check: %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
printf 'Remote K3s node: %s\n' "$K3S_SSH_HOST"

section "SSH and remote kubectl preflight"
if ! ssh "${SSH_OPTIONS[@]}" "$K3S_SSH_HOST" \
  'sudo -n k3s kubectl version --client >/dev/null'; then
  printf 'ERROR: Unable to run remote kubectl through %s.\n' \
    "$K3S_SSH_HOST" >&2
  printf 'Confirm SSH agent and bastion access, then try again.\n' >&2
  exit 1
fi
printf 'Remote access passed.\n'

section "Client and context"
remote_kubectl version --client
remote_kubectl config current-context

section "Kubernetes API readiness"
if ! remote_kubectl get --raw=/readyz?verbose; then
  printf '\nRESULT: FAIL - Kubernetes API is not ready or reachable.\n' >&2
  exit 1
fi
printf '\n'

section "Cluster nodes"
run_check remote_kubectl get nodes -o wide

node_issues="$(
  remote_kubectl get nodes --no-headers |
    awk '$2 != "Ready" { print }'
)"

if [[ -n "$node_issues" ]]; then
  printf '\nNodes requiring attention:\n%s\n' "$node_issues"
  overall_status=1
fi

section "web-demo rollout"
run_check remote_kubectl rollout status deployment/web-demo \
  --namespace "$WEB_NAMESPACE" \
  --timeout=15s

run_check remote_kubectl get deployment,pod \
  --namespace "$WEB_NAMESPACE" \
  --selector app=web-demo \
  -o wide

run_check remote_kubectl get service/web-demo ingress/web-demo \
  --namespace "$WEB_NAMESPACE"

section "Monitoring workloads"
run_check remote_kubectl get deployment,statefulset,daemonset \
  --namespace "$MONITORING_NAMESPACE"

section "Availability monitoring objects"
run_check remote_kubectl get probe/web-demo-availability \
  prometheusrule/web-demo-availability \
  --namespace "$MONITORING_NAMESPACE"

section "Persistent volume claims"
run_check remote_kubectl get persistentvolumeclaims --all-namespaces

section "Pods requiring attention"
problem_pods="$(
  remote_kubectl get pods --all-namespaces --no-headers |
    awk '
      {
        split($3, ready, "/")
        if ($4 != "Running" && $4 != "Completed") {
          print
        } else if ($4 == "Running" && ready[1] != ready[2]) {
          print
        }
      }
    '
)"

if [[ -n "$problem_pods" ]]; then
  printf '%s\n' "$problem_pods"
  overall_status=1
else
  printf 'None\n'
fi

if ((overall_status != 0)); then
  printf '\nRESULT: ATTENTION REQUIRED\n'
  exit 1
fi

printf '\nRESULT: PASS\n'