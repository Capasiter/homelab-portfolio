# Argo CD - WebDemo GitOps

## Configuration
- Argo CD v3.5.3, standard non-HA installation in namespace argocd.
- Version-pinned upstream manifests composed with Kustomize.
- Dashboard accessed through SSH and VS Code port forwarding.
- Application: web-demo; destination namespace: k8s-learning.
- Repository: https://github.com/Capasiter/homelab-portfolio.git
- Source: main branch, kubernetes/k8s-learning/web-demo.yaml.
- Manual sync; automated sync, self-heal, and automatic pruning disabled.

## Live validation - September 27, 2026
1. Rendered installation manifests and passed server-side dry-run validation.
2. Installed Argo CD and confirmed all seven pods Ready.
3. Validated and registered the WebDemo Application.
4. Reviewed six resource diffs showing added Argo tracking annotations.
5. Manually synced; observed Synced and Healthy.
6. Confirmed three Ready pods, one per node, with zero restarts.
7. Changed live replicas from three to four while Git still declared three.
8. Observed five synced resources and one OutOfSync Deployment.
9. Inspected the replica difference and manually synced the Deployment.
10. Confirmed Synced, Healthy, and 3/3 Ready and available replicas.

## Limitations
Automatic self-healing and continuous HTTP availability were not tested.
Argo CD was bootstrapped manually and does not manage its own installation.
The cluster runs on one physical Proxmox host.
The incomplete isolated restore drill remains a separate milestone.
