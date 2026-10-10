# K3s API VIP — Live Validation

**Validation date:** September 19, 2026 (America/Chicago)

**Milestone:** [v0.8.0](https://github.com/Capasiter/homelab-portfolio/releases/tag/v0.8.0) — released September 20, 2026

**Implementation commit:** `155fd62` — `feat: add K3s API VIP failover foundation`

[Return to the portfolio](../../README.md) · [Implementation role](../roles/k3s_api_vip/) · [Cluster playbook](../playbooks/k3s_cluster.yml)

## Outcome

A controlled deletion of the kube-vip leader pod was followed by VIP ownership moving from `k3s-server-02` to `k3s-server-03`. No `api-vip=FAILED` entries were found in the recorded probe log. After the test, all three kube-vip pods were Running and all three K3s nodes reported Ready.

This is **pod-level failover evidence**, not proof of uninterrupted service, node-power-loss recovery, or physical-host high availability.

## Environment

| Item | Validated state |
|---|---|
| K3s | `v1.36.2+k3s1` |
| Servers | `k3s-server-01`, `k3s-server-02`, `k3s-server-03` |
| Server addresses | `10.20.0.101`, `10.20.0.102`, `10.20.0.103` |
| API endpoint | `https://10.20.0.110:6443` |
| VIP attachment | `10.20.0.110/32` on the owning server's `eth0` |
| kube-vip deployment | `kube-system/kube-vip-ds`, DaemonSet across all three servers |
| Initial DaemonSet state | Desired 3, current 3, ready 3, available 3 |
| Physical topology | Three K3s VMs share one Proxmox host |
| Access | SSH through the configured bastion; API probes issued from server 01 |

The live implementation is a DaemonSet, not a static-pod deployment.

## Pre-test checks

- Git worktree clean on `main`, matching the locally recorded `origin/main` at `155fd62`.
- Ansible syntax check and task listing completed successfully.
- A configuration-tag check-mode run reported `changed=0`, `unreachable=0`, and `failed=0` on all three nodes.
- The full check-mode run also reported no changes or failures; many runtime tasks were skipped. This is not a substitute for live validation or proof of a full applied idempotence run.
- All three nodes reported Ready with control-plane and etcd roles.
- `k3s-backup.service` reported `Result=success`; the one-shot service was inactive and the timer was active. This check alone does not establish backup freshness or restore viability.
- A certificate inspected at server 01's local API endpoint included `IP Address:10.20.0.110` in its SANs.
- A `kubectl get nodes` request through the VIP returned all three nodes Ready.
- Address inspection showed only server 02 holding the VIP among the three inspected servers.

The VIP did not answer a ping from the workstation, but did answer from inside the lab. Workstation ping failure was not evidence that the address was unused. An ICMP response alone also does not identify an address owner; the later interface and Kubernetes checks established the state above.

## Exercise

1. Started a background loop designed to perform 60 API readiness queries through the VIP.
2. Each iteration connected by SSH to server 01 and ran an authenticated `kubectl get --raw=/readyz` request against `https://10.20.0.110:6443`.
3. Recorded `api-vip=OK` or `api-vip=FAILED` with a timestamp after each command completed, then slept for one second.
4. After a five-second delay, deleted `kube-vip-ds-5cmwp`, the pod on the then-current VIP owner, server 02.
5. Waited for the probe loop to finish.
6. Searched the log for failures, inspected `eth0` on all three servers, listed kube-vip pods, and queried node readiness through the VIP.

The probe log was stored on the workstation at `/tmp/k3s-api-vip-failover.log`. It is **not included in this report**. This report summarizes terminal output reviewed during the exercise; the full line count has not been independently verified here.

## Observed state transition

| Component | Before | After |
|---|---|---|
| VIP owner | `k3s-server-02` | `k3s-server-03` |
| Server 02 pod | `kube-vip-ds-5cmwp` | `kube-vip-ds-rbl5x`, 1/1 Running |
| Server 03 pod | `kube-vip-ds-67p5x`, 1/1 Running | Same pod, 1/1 Running, 0 restarts |
| Server 01 pod | `kube-vip-ds-dh5xg`, 1/1 Running, 1 older restart | Same pod and restart count |
| K3s nodes | All 3 Ready | All 3 Ready |
| Failure-log search | Not applicable | No matching `api-vip=FAILED` lines |

Selected post-test interface output:

```text
k3s-server-01
eth0 UP 10.20.0.101/24
k3s-server-02
eth0 UP 10.20.0.102/24
k3s-server-03
eth0 UP 10.20.0.103/24 10.20.0.110/32
```

The excerpt omits IPv6 link-local addresses and interface metric fields for readability.

Selected final node output:

```text
NAME            STATUS   ROLES                VERSION
k3s-server-01   Ready    control-plane,etcd   v1.36.2+k3s1
k3s-server-02   Ready    control-plane,etcd   v1.36.2+k3s1
k3s-server-03   Ready    control-plane,etcd   v1.36.2+k3s1
```

## Measurement limits

- The loop used 60 planned iterations, not an exact 60-second window. Each SSH connection and API request added time.
- The original probe did not set an explicit SSH connection timeout or Kubernetes request timeout. Requests could wait through an interruption and later succeed.
- The one-second sleep was between completed requests, so this was not continuous traffic.
- Therefore, no failed probes recorded does **not** mean zero downtime. Failover duration and a maximum outage bound were not measured.
- Application HTTP traffic was not monitored during this test. Earlier application-rollout results are a separate exercise.
- Node readiness was checked before and after, not continuously.
- Pod deletion is a controlled event. It does not simulate a node power loss, network partition, etcd quorum loss, or physical-host failure.
- Certificate SAN inspection shows that the VIP is listed; it is not, by itself, a complete certificate-chain or every-node certificate audit.

## Follow-up validation goals

- Preserve the raw probe log and confirm the completed request count before publishing any exact failover-probe totals.
- Use explicit connection and request deadlines, record request latency, and monitor application traffic separately for a future bounded test.
- Plan a separate controlled node-level failure test with backup freshness, capacity, recovery, and rollback checks first.
- Keep physical-host failure outside the current resilience claim.

No additional failure test or live infrastructure change is performed by this documentation update.
