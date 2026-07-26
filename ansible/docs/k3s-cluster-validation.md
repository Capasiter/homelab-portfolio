# K3s Cluster Live Validation

- **Validation date:** July 25, 2026
- **Environment:** Isolated three-server K3s cluster
- **Result:** Passed
- **K3s version:** `v1.36.2+k3s1`
- **Pull request:** [#6](https://github.com/Capasiter/homelab-portfolio/pull/6)

## Purpose

This validation confirmed that the pinned Ansible automation could initialize a K3s server with embedded etcd, securely transfer the generated server token in memory, join two additional servers sequentially, validate the resulting control plane, and converge idempotently.

The validation also covered Kubernetes API readiness, embedded-etcd readiness, secrets encryption, packaged components, service discovery, cross-node pod networking, metrics, and snapshot creation.

## Cluster Architecture

| Node | Address | Kubernetes roles | Status |
|---|---|---|---|
| `k3s-server-01` | `10.20.0.101` | `control-plane`, `etcd` | Ready |
| `k3s-server-02` | `10.20.0.102` | `control-plane`, `etcd` | Ready |
| `k3s-server-03` | `10.20.0.103` | `control-plane`, `etcd` | Ready |

All three nodes run Ubuntu 24.04 on `x86_64` with two virtual CPUs, 3072 MB of memory, no swap, and networking through the isolated `vmbr1` bridge.

OPNsense provides DHCP, DNS forwarding, routing, and outbound NAT. No upstream-router change or physical Ethernet uplink is required.

## Deployment Controls

The deployment used:

- Exact K3s version pinning
- Immutable installer commit pinning
- SHA-256 verification of the installer and installed binary
- Platform, resource, hostname, address, and interface preflight assertions
- Persistent kernel-module and sysctl configuration
- One embedded-etcd bootstrap server
- Sequential joining with `serial: 1`
- Fatal-error handling that stops the rollout
- Root-owned mode `0600` K3s configuration
- Root-owned mode `0600` join-token files
- `no_log` and disabled diff output for token handling
- A non-cacheable in-memory Ansible token fact
- Runtime service, version, API, node, encryption, and permission validation

The automation was reviewed, committed, pushed, and validated by GitHub Actions before the live installation began.

## Check-Mode Preview

The complete K3s playbook passed check mode before installation.

Each node:

- Passed platform and inventory preflight checks
- Rendered and parsed valid K3s YAML without writing it
- Correctly reported that pinned K3s installation was required
- Completed with `failed=0` and `unreachable=0`

A post-preview stat check confirmed `/usr/local/bin/k3s` remained absent on every node.

## Initial Deployment

The first live run successfully:

- Applied the K3s kernel prerequisites
- Installed the checksum-verified K3s release
- Initialized embedded etcd on server 01
- Joined servers 02 and 03 sequentially
- Started and enabled all three K3s services
- Reached the local API readiness endpoint
- Marked all three Kubernetes nodes Ready
- Enabled secrets encryption

The final validation then rejected server 03 because the playbook expected the legacy `node-role.kubernetes.io/master` label.

Live inspection proved all three nodes correctly had the current `control-plane` and `etcd` labels. K3s removed the obsolete `master` label beginning with its v1.34 release series.

The assertion was corrected in commit `cd1480d`, production linting passed, the fix was pushed, and both GitHub Actions jobs passed before rerunning the playbook.

Reference: [K3s v1.34 release notes](https://docs.k3s.io/release-notes/v1.34.X)

## Idempotence Result

The corrected playbook completed successfully with no further changes:

| Node | OK | Changed | Unreachable | Failed |
|---|---:|---:|---:|---:|
| `k3s-server-01` | 45 | 0 | 0 | 0 |
| `k3s-server-02` | 42 | 0 | 0 | 0 |
| `k3s-server-03` | 42 | 0 | 0 | 0 |

The `changed=0` result on all three nodes proves the automation converged to a repeatable declared state.

## API and Etcd Readiness

The verbose Kubernetes readiness endpoint passed every reported check, including:

- API ping and logging
- `etcd`
- `etcd-readiness`
- KMS providers
- Encryption-provider configuration reload
- Informer synchronization
- API storage readiness
- Admission and controller post-start hooks
- Overall `readyz`

The Kubernetes service advertised all three API endpoints:

| Endpoint |
|---|
| `10.20.0.101:6443` |
| `10.20.0.102:6443` |
| `10.20.0.103:6443` |

## Packaged Components

The following packaged components reached their expected states:

| Component | Result |
|---|---|
| CoreDNS | Running |
| Metrics Server | Running |
| Local Path Provisioner | Running |
| Traefik | Running |
| Traefik service-load-balancer pods | Running on all three nodes |
| Traefik Helm installation jobs | Completed |

The default `local-path` storage class was present with `WaitForFirstConsumer` volume binding.

Traefik advertised the three private K3s node addresses. It is not exposed through the household router.

## Resource Validation

Metrics Server reported low steady-state utilization:

| Node | CPU | CPU percentage | Memory | Memory percentage |
|---|---:|---:|---:|---:|
| `k3s-server-01` | 36 millicores | 1% | 1034 MiB | 34% |
| `k3s-server-02` | 22 millicores | 1% | 655 MiB | 22% |
| `k3s-server-03` | 20 millicores | 1% | 628 MiB | 21% |

Guest-level Linux inspection also reported approximately 1.9 GiB available on server 01. The Proxmox memory percentage represented allocated or cached guest memory rather than actual memory pressure.

## DNS and Cross-Node Networking

A disposable BusyBox pod was scheduled on `k3s-server-03` with pod address `10.42.3.3`.

From that pod:

- CoreDNS was reached through service address `10.43.0.10`
- `kubernetes.default.svc.cluster.local` resolved successfully
- The Kubernetes API service resolved to `10.43.0.1`

CoreDNS was running on `k3s-server-01`, so this test exercised cross-node Flannel networking from server 03 to server 01 and Kubernetes service routing.

The smoke-test pod was deleted after validation.

## Secrets Encryption

K3s reported:

- Encryption status enabled
- Current rotation stage `start`
- Matching encryption hashes across all servers
- Active AES-CBC encryption key

No token, encryption key, kubeconfig, or other secret value was printed or committed.

## Etcd Snapshot Validation

A compressed on-demand snapshot was created successfully:

| Property | Value |
|---|---|
| Name | `v0.4.0-validation-k3s-server-01-1785024377.zip` |
| Location | `/var/lib/rancher/k3s/server/db/snapshots/` |
| Size | 3,315,134 bytes |
| Created | July 25, 2026 at 19:06:17 CDT |

Scheduled compressed snapshots remain configured every 12 hours with retention of five snapshots.

The validation snapshot is currently local to server 01. Protected off-host snapshot and server-token backup remain required for complete disaster recovery.

Reference: [K3s snapshot documentation](https://docs.k3s.io/cli/etcd-snapshot)

## Startup Events

Warning events recorded during initial cluster formation were reviewed.

They included:

- Initial image-filesystem capacity discovery
- Early CoreDNS and metrics-server readiness failures
- A temporary Traefik Helm installation retry
- Temporary missing Flannel state while servers 02 and 03 were joining

All affected components subsequently reached `Running` or `Completed`. Metrics collection, DNS, cross-node networking, and Traefik load-balancer pods were validated successfully. No repair action was required.

## Security Controls

- Isolated virtual network behind OPNsense
- No physical lab uplink or household-router changes
- Restricted destination-allowlisted SSH bastion
- Separate bastion and target SSH identities
- Key-only target authentication
- Disabled root and password SSH access
- Checksum-verified K3s artifacts
- Root-only K3s configuration and token files
- Token suppression from logs and diffs
- Kubernetes secrets encryption
- Embedded-etcd snapshots
- Read-only public CI without infrastructure credentials
- Proxmox console recovery access

## Current Limitations

- The Kubernetes API has no dedicated virtual IP or external load balancer
- The validation snapshot is not yet copied off-host
- Server-token backup and recovery have not yet been exercised
- The default local-path provisioner is node-local storage
- Unraid-backed persistent storage is a future milestone
- Kubernetes network policy is not yet configured
- Monitoring beyond Metrics Server is not yet deployed
- Application GitOps is not yet implemented
- Restore testing remains pending

## Validation Outcome

The three-server K3s control plane passed live deployment and runtime validation.

The cluster is Ready, encrypted, backed by embedded etcd, reachable through three API endpoints, capable of cross-node pod networking and service discovery, and managed by idempotent Ansible automation.

The deployment also produced a documented troubleshooting example: live evidence identified an obsolete validation assumption, the automation was corrected and revalidated through CI, and the final run converged with `changed=0` on every node.
