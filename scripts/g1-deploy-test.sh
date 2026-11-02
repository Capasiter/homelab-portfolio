#!/usr/bin/env bash
# G1 deploy + test — run on the Linux box (devops-workstation).
# Requires the bastion tunnel already open (Terminal A):
#   ssh -N -f -L 2222:10.20.0.101:22 -i ~/.ssh/homelab_bastion_ed25519 -o IdentitiesOnly=yes k3s-jump@192.168.0.202
#
# This script: finds the real Alertmanager ConfigMap name, applies the ntfy
# config to it, restarts Alertmanager, and fires one test alert.

set -euo pipefail

BASTION="ssh -p 2222 -i ~/.ssh/homelab_ansible_ed25519 -o IdentitiesOnly=yes ansible@127.0.0.1"
K="sudo -n k3s kubectl"
NS=monitoring
REPO=~/projects/homelab-portfolio
CM_FILE="$REPO/kubernetes/observability/alertmanager-ntfy-configmap.yaml"

echo "==> 1. Find the real Alertmanager ConfigMap name"
REAL_CM=$($BASTION "$K -n $NS get configmap --no-headers" | grep -i alert | awk '{print $1}' | head -1)
echo "    found: ${REAL_CM:-<none>}"
if [[ -z "$REAL_CM" ]]; then
  echo "    ERROR: no alertmanager configmap found. Stop and check: $BASTION \"$K -n $NS get configmap\""
  exit 1
fi

echo "==> 2. Copy the ntfy ConfigMap to the node"
scp -P 2222 -i ~/.ssh/homelab_ansible_ed25519 -o IdentitiesOnly=yes \
  "$CM_FILE" ansible@127.0.0.1:/tmp/alertmanager-ntfy.yaml

echo "==> 3. Rewrite the file to target the real ConfigMap name ($REAL_CM)"
# The file ships with name monitoring-kube-prometheus-alertmanager; if the real
# name differs, sed it in place on the node before applying.
$BASTION "sed -i 's/^  name: monitoring-kube-prometheus-alertmanager/  name: $REAL_CM/' /tmp/alertmanager-ntfy.yaml"

echo "==> 4. Apply"
$BASTION "$K apply -f /tmp/alertmanager-ntfy.yaml"

echo "==> 5. Verify ntfy is in the live config"
$BASTION "$K -n $NS get configmap $REAL_CM -o yaml" | grep -A2 ntfy || echo "    (no ntfy line found — check step 4 output)"

echo "==> 6. Restart Alertmanager to reload config"
$BASTION "$K -n $NS rollout restart statefulset alertmanager-monitoring-kube-prometheus-alertmanager"

echo "==> 7. Wait for rollout"
$BASTION "$K -n $NS rollout status statefulset alertmanager-monitoring-kube-prometheus-alertmanager --timeout=120s" || true

echo "==> 8. Fire ONE test alert (severity=critical)"
$BASTION "$K -n $NS exec statefulset/alertmanager-monitoring-kube-prometheus-alertmanager -- \
  wget -qO- --post-data='[{\"labels\":{\"alertname\":\"G1Test\",\"severity\":\"critical\"},\"annotations\":{\"description\":\"G1 test: Alertmanager to ntfy\"}}]' \
  --header='Content-Type: application/json' http://localhost:9093/api/v2/alerts"

echo
echo "==> DONE. Check your phone for:  🔴 CRITICAL: G1Test"
echo "    If you got it, G1 is complete. If not, run:"
echo "      $BASTION \"$K -n $NS logs statefulset/alertmanager-monitoring-kube-prometheus-alertmanager --tail=50\""
