# K3s Observability

This directory contains the version-pinned and resource-tuned observability configuration for the three-server K3s homelab.

## Purpose

The monitoring stack provides cluster, node, and workload visibility using Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter.

This foundation will later support controlled incident testing and isolated, read-only AI-assisted incident analysis.

## Versions

- Kubernetes distribution: K3s `v1.36.2+k3s1`
- Helm CLI: `v4.2.4`
- kube-prometheus-stack chart: `88.3.0`
- Prometheus Operator: `v0.93.0`

## Architecture

```mermaid
flowchart TD
    N["node-exporter"] --> P["Prometheus"]
    K["kube-state-metrics"] --> P
    A["Kubernetes API and kubelet"] --> P
    P --> G["Grafana"]
    P --> M["Alertmanager"]
```

- **Prometheus** collects and stores time-series metrics.
- **Grafana** queries Prometheus and visualizes the results.
- **Alertmanager** manages active alerts, grouping, silences, and routing.
- **kube-state-metrics** exposes Kubernetes object state such as desired and available replicas.
- **node-exporter** exposes operating-system and hardware metrics from every K3s server.
- **Prometheus Operator** converts custom resources into managed Prometheus and Alertmanager workloads.

## Configuration

- `namespace.yaml` declaratively creates the `monitoring` namespace.
- `kube-prometheus-stack-values.yaml` contains resource limits, retention, storage, and K3s-specific monitoring decisions.
- Grafana credentials are stored in the separately managed `monitoring-grafana-admin` Kubernetes Secret.
- No passwords, tokens, kubeconfig data, or live Secrets are stored in Git.

## Resource and Storage Plan

| Component | CPU request | CPU limit | Memory request | Memory limit | Storage |
|---|---:|---:|---:|---:|---:|
| Prometheus | 250m | 1 core | 512Mi | 1536Mi | 10Gi |
| Grafana | 100m | 500m | 128Mi | 512Mi | 2Gi |
| Alertmanager | 25m | 200m | 64Mi | 256Mi | 1Gi |
| Prometheus Operator | 100m | 500m | 128Mi | 256Mi | None |
| kube-state-metrics | 25m | 200m | 64Mi | 128Mi | None |
| node-exporter | 10m | 100m | 32Mi | 64Mi | None |

Prometheus retains metrics for seven days with an 8 GiB retention-size cap.

## K3s-Specific Decisions

Live socket inspection showed these endpoints were network-accessible:

- Kubernetes API server: `6443`
- Kubelet: `10250`

These metrics endpoints listened only on node loopback:

- Controller manager: `10257`
- Scheduler: `10259`
- Kube-proxy: `10249`
- Etcd metrics: `2381`

The loopback-only component monitors and their associated default rules are disabled. This prevents unreachable scrape targets and false alerts without weakening the K3s defaults by exposing additional ports.

## Validation

Render the pinned chart without changing the cluster:

```bash
helm template monitoring prometheus-community/kube-prometheus-stack \
  --version 88.3.0 \
  --namespace monitoring \
  --include-crds \
  --values kubernetes/observability/kube-prometheus-stack-values.yaml
```

Inspect live resources:

```bash
sudo k3s kubectl -n monitoring get pods -o wide
sudo k3s kubectl -n monitoring get pvc -o wide
sudo k3s kubectl top nodes
sudo k3s kubectl -n monitoring top pods --containers
```

## Initial Live Validation

Validated on August 16, 2026:

- Helm release `monitoring` deployed successfully at revision 1.
- All monitoring containers became Ready.
- No monitoring pod restarts were observed.
- One node-exporter pod ran on each K3s server.
- Prometheus, Grafana, and Alertmanager PVCs were Bound.
- Cluster CPU utilization remained approximately 2–3%.
- Node memory utilization remained approximately 53–57%.
- Grafana displayed live cluster, namespace, and workload metrics.
- PromQL `min(up)` returned `1`, confirming all discovered targets were healthy.
- `web-demo` desired replicas returned `3`.
- `web-demo` available replicas returned `3`.

## Learning Queries

Confirm scrape health:

```promql
up
```

Confirm that every discovered target is healthy:

```promql
min(up)
```

Show desired `web-demo` replicas:

```promql
kube_deployment_spec_replicas{namespace="k8s-learning", deployment="web-demo"}
```

Show available `web-demo` replicas:

```promql
kube_deployment_status_replicas_available{namespace="k8s-learning", deployment="web-demo"}
```

A difference between desired and available replicas indicates that Kubernetes has not yet reached the declared state.

## Current Limitations

- Prometheus, Grafana, and Alertmanager each run as a single replica.
- Persistent storage uses node-local `local-path` volumes.
- Local-path volumes cannot be expanded and are unavailable if their assigned node is offline.
- Loopback-only K3s component metrics are intentionally not collected.
- Grafana is accessed through a local SSH tunnel rather than a public ingress.
- External alert notification routing is not configured yet.
- Black-box application probing and the controlled alert test remain pending.

## Next Steps

1. Add black-box availability probing for `web-demo`.
2. Add one meaningful availability alert.
3. Trigger a controlled failure and capture the firing alert.
4. Restore the application and capture alert recovery.
5. Confirm the new Helm rendering job passes in GitHub Actions.
6. Document evidence and operational limitations.
7. Complete the v0.6 pull request, changelog, tag, and release.
8. Use these metrics and alerts as read-only evidence for an isolated AI incident-analysis agent.
