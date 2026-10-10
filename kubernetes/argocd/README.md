# Argo CD - WebDemo GitOps

## Configuration
- Argo CD v3.5.3, standard non-HA installation in namespace argocd.
- Version-pinned upstream manifests composed with Kustomize.
- Dashboard accessed through SSH and VS Code port forwarding.
- Application: web-demo; destination namespace: k8s-learning.
- Repository: https://github.com/Capasiter/homelab-portfolio.git
- Source: main branch, kubernetes/k8s-learning/web-demo.yaml.
- Manual sync; automated sync, self-heal, and automatic pruning disabled.

## Initial live validation
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

## Revalidation with preserved evidence

A second controlled drift exercise captured the full state transition:

1. Baseline: the Application was `Synced` and `Healthy`; WebDemo was 3/3 Ready, with one pod on each K3s server and zero restarts.
2. Live drift: the Deployment was scaled from three replicas to four while Git continued to declare three.
3. Detection: Argo CD reported `OutOfSync` while the application remained `Healthy`; WebDemo reached 4/4 Ready.
4. Inspection: the Deployment was the only OutOfSync managed resource. Namespace, Service, ServiceAccount, Ingress, and PodDisruptionBudget remained Synced.
5. Reconciliation: a human-initiated Argo CD operation synchronized only `Deployment/web-demo`.
6. Recovery: the operation succeeded and returned the Application to `Synced` and `Healthy`, with WebDemo at 3/3 Ready.

**Captured output:** [baseline](evidence/argo-web-demo-before.txt) · [detected drift](evidence/argo-web-demo-drift.txt) · [resource and event evidence](evidence/argo-web-demo-diff.txt) · [reconciled state](evidence/argo-web-demo-after.txt)

## Repeat the read-only checks

From an administrative shell with authorized cluster access, these commands show the current state. They do not replay the controlled drift exercise or prove historical availability.

```bash
kubectl -n argocd get pods
kubectl -n argocd get application web-demo
kubectl -n argocd describe application web-demo
kubectl -n k8s-learning get deployment web-demo
kubectl -n k8s-learning get pods -o wide
```

Compare the Application's Sync Status and Health Status with the Deployment's desired, ready, and available replicas. The preserved evidence above records the baseline, detected drift, affected resource, manual reconciliation, and recovered state.

## Limitations
Automatic self-healing and continuous HTTP availability were not tested.
Argo CD was bootstrapped manually and does not manage its own installation.
The cluster runs on one physical Proxmox host.
The incomplete isolated restore drill remains a separate milestone.
