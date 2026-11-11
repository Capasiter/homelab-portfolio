# Argo CD Inspection Checklist

> Warning: Do not install Argo CD yet.

This checklist prepares the homelab portfolio repo for Argo CD while keeping a clear boundary between infrastructure management and application management.

## Safety Boundary

| Area | Owner |
| --- | --- |
| Proxmox VMs | OpenTofu |
| K3s bootstrap and node configuration | Ansible |
| kube-vip / API VIP | Ansible |
| First Argo CD candidate | `kubernetes/k8s-learning/web-demo.yaml` |
| Monitoring stack | Move later after validation |

`scripts/k3s-health-check.sh` is a read-only validation script, not a deployment tool.

## Read These Files

| Category | Files To Read | Key Questions |
| --- | --- | --- |
| Cluster and provisioning | `ansible/playbooks/k3s_cluster.yml`, `ansible/roles/k3s_api_vip/tasks/main.yml` | What does Ansible own? What must Argo CD not touch? |
| Workloads and app definitions | `kubernetes/k8s-learning/web-demo.yaml`, `kubernetes/observability/blackbox-exporter.yaml`, `kubernetes/observability/web-demo-availability.yaml` | Which resources are application workloads? Who deploys them today? |
| Monitoring and backup | `kubernetes/observability/kube-prometheus-stack-values.yaml`, backup docs/playbooks | What is backed up? When was restore last tested? |

## Collect Evidence

Run these before changing anything:

```bash
kubectl version --short
kubectl get nodes -o wide
kubectl get all,ingress -A -o wide
kubectl top nodes