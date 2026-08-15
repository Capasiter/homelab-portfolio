# Homelab Infrastructure Portfolio

[![Infrastructure Validation](https://github.com/Capasiter/homelab-portfolio/actions/workflows/infrastructure-validation.yml/badge.svg)](https://github.com/Capasiter/homelab-portfolio/actions/workflows/infrastructure-validation.yml)

Employment-focused homelab demonstrating Linux administration, Infrastructure as Code, configuration management, isolated networking, troubleshooting, continuous integration, and infrastructure operations across Proxmox VE and Unraid.

> **Current build:** A live-validated three-server K3s control plane on Proxmox now runs a version-controlled application workload. OpenTofu provisions the infrastructure, Ansible deploys K3s, and Kubernetes manifests define the workload and its rolling-update, readiness, Service, and Traefik Ingress behavior.

**Career focus:** Linux Systems Administration · Infrastructure Engineering · Cloud Support · Junior DevOps

## Current Milestone — K3s Application Rollout Reliability

The v0.5.0 milestone advances the portfolio from deploying a Kubernetes platform to operating a workload reliably and validating availability through live client traffic.

**Validated live:** An initial rolling restart completed successfully in Kubernetes but produced one client-visible timeout. After adding an HTTP readiness probe, `minReadySeconds`, `maxUnavailable: 0`, controlled surge capacity, and a 10-second `preStop` drain window, live-traffic tests observed 148 successful requests with 0 failures and a separate revalidation observed 120 successful requests with 0 failures. The final Deployment returned to 3/3 Ready and available, with one pod running on each K3s server.

[Review the complete rolling-update reliability evidence](kubernetes/k8s-learning/README.md)

### Platform Foundation — v0.4.0

[Review the complete K3s cluster validation evidence](ansible/docs/k3s-cluster-validation.md)

OpenTofu currently manages:

| Node | VM ID | Reserved address | Role |
|---|---:|---|---|
| `k3s-server-01` | 401 | `10.20.0.101` | K3s server (control plane + etcd) |
| `k3s-server-02` | 402 | `10.20.0.102` | K3s server (control plane + etcd) |
| `k3s-server-03` | 403 | `10.20.0.103` | K3s server (control plane + etcd) |

Each node is a full clone of a sanitized Ubuntu 24.04 cloud-image template with:

- 2 CPU cores using the host CPU type
- 3072 MB of memory
- 32 GB disk on Proxmox storage
- Cloud-init automation user and SSH public key
- QEMU guest-agent integration
- Deterministic MAC address and DHCP reservation
- Automatic startup after the OPNsense gateway
- Serial-console recovery access
- Networking only on the isolated `vmbr1` bridge

### Network Design

OPNsense separates the K3s environment from the management network:

| Component | Function |
|---|---|
| `vmbr0` | Proxmox management and OPNsense WAN |
| OPNsense VM 400 | Firewall, routing, DHCP, DNS forwarding, and outbound NAT |
| `vmbr1` | Isolated `10.20.0.0/24` lab network |
| VMs 401–403 | K3s infrastructure attached only to `vmbr1` |

The isolated bridge carries VM traffic internally and does not require a connected physical uplink. No upstream-router configuration was changed.

### Deployment Evidence

The deployment demonstrated:

- Reusable OpenTofu VM module design
- Stable VM identity through `for_each`, VM IDs, and MAC addresses
- Controlled canary deployment using `k3s-server-01`
- Recovery from a partially completed, tainted canary resource
- Diagnosis of HTTP `401` authentication and HTTP `403` authorization failures
- A purpose-built Proxmox provisioning role
- Understanding of privilege-separated parent and token ACL intersections
- Dependency-aware startup and reverse-order shutdown
- Cloud-init, guest-agent, routing, NAT, DNS, and SSH validation
- A final non-targeted OpenTofu plan reporting no changes

The K3s deployment additionally demonstrated:

- Dependency-aware bootstrap and sequential joins through idempotent Ansible automation
- Pinned K3s installer and binary artifacts with SHA-256 verification
- Secure in-memory join-token handling and root-owned configuration
- Kubernetes Secrets encryption validated across all three servers
- Healthy Kubernetes API and three-member embedded etcd control plane
- Cross-node scheduling, networking, Service routing, and DNS validation
- Successful local etcd snapshot creation and a full `changed=0` rerun
- Evidence-based correction of an obsolete Kubernetes role-label assertion

> **Current limitations:** The Kubernetes API does not yet use a virtual IP or external load balancer. The etcd snapshot is local-only and restore testing remains pending. Unraid-backed persistent storage, monitoring, and GitOps are future milestones.

Documentation:

- [K3s environment and architecture](proxmox/opentofu/environments/k3s/README.md)
- [K3s live-validation report](proxmox/opentofu/docs/k3s-live-validation.md)
- [K3s cluster live-validation report](ansible/docs/k3s-cluster-validation.md)
- [Kubernetes rolling-update reliability lab](kubernetes/k8s-learning/README.md)
- [Proxmox OpenTofu project](proxmox/opentofu/)

## Milestone History

| Milestone | Delivered capability | Status |
|---|---|---|
| v0.1.0 | Reusable OpenTofu module and live Proxmox Ubuntu LXC deployment | Released |
| v0.2.0 | Idempotent Ansible Linux baseline with SSH hardening | Released |
| v0.3.0 | Read-only GitHub Actions infrastructure validation | Released |
| v0.4.0 | Isolated three-node K3s infrastructure and cluster deployment | Released |
| v0.5.0 | K3s application rollout reliability with readiness, graceful termination, and live-traffic validation | Released |

## Featured Infrastructure Projects

### Proxmox OpenTofu Infrastructure

[View the Proxmox OpenTofu project](proxmox/opentofu/)

The OpenTofu project separates reusable modules from environment compositions:

- `modules/ubuntu-lxc` provisions unprivileged Ubuntu containers
- `modules/ubuntu-vm` provisions cloud-init Ubuntu virtual machines
- `environments/dev` manages the live development container
- `environments/k3s` manages the isolated three-VM foundation

Both live environments have completed full drift checks reporting no changes.

### Ansible Linux Baseline

[View the Ansible Linux baseline](ansible/)

[Read the original development-LXC validation report](ansible/docs/live-validation.md)

[Read the three-node K3s bootstrap validation report](ansible/docs/k3s-node-validation.md)

The reusable `linux_baseline` role provides:

- Ubuntu platform validation
- Administration package installation
- Timezone configuration
- Key-only SSH authentication
- Disabled password and keyboard-interactive authentication
- Disabled direct root SSH login
- SSH configuration validation before restart
- Handler-based service management
- Production-profile linting
- Proven idempotency with `changed=0`

The same baseline is now live-validated on all three K3s nodes, including a full idempotent run with `changed=0` on every node.

### GitHub Actions Infrastructure Validation

[View the validation workflow](.github/workflows/infrastructure-validation.yml)

Every pull request and push to `main` runs independent OpenTofu and Ansible jobs on Ubuntu 24.04.

CI validates formatting, initializes both the development and K3s OpenTofu environments without backends, validates both configurations, parses only sanitized Ansible inventory, checks playbook syntax, and runs `ansible-lint` without accessing live infrastructure.

The workflow uses read-only repository permissions and contains no Proxmox credentials, SSH keys, live inventory, or infrastructure state.

## Technology and Status

| Area | Technology | Status |
|---|---|---|
| Virtualization | Proxmox VE 9.2.x | Operational |
| Infrastructure as Code | OpenTofu 1.12.4 and `bpg/proxmox` | Live validated |
| Linux containers | Ubuntu 24.04 LXC | Deployed and configured |
| Virtual machines | Ubuntu 24.04 cloud-init VMs | Three deployed and drift-free |
| Network security | OPNsense isolated lab | Operational |
| Configuration management | Ansible | Linux baseline and K3s deployment live validated |
| Continuous integration | GitHub Actions | Automated validation passing |
| Orchestration | K3s with embedded etcd | Three-server control plane deployed and live validated |
| Application delivery | Kubernetes Deployment, Service, and Traefik Ingress | Protected rolling restart validated under live traffic |
| Cluster storage | K3s local-path provisioner | Operational; node-local only |
| Shared storage | Unraid | Platform operational; K3s integration planned |
| Secure remote access | OpenSSH bastion access | Restricted access live validated |
| Version control | Git and GitHub | Active |

## Engineering Practices Demonstrated

- Reusable Infrastructure as Code modules
- Environment-specific composition and configuration
- Input validation and provider version pinning
- Full-clone cloud-image provisioning
- Cloud-init bootstrap automation
- Deterministic addressing with MAC-based DHCP reservations
- Isolated virtual networking and firewall routing
- Dependency-aware startup and shutdown ordering
- Serial-console recovery design
- Controlled canary deployment
- Tainted-resource recovery
- Full-plan reconciliation after targeted operations
- Infrastructure drift detection
- Runtime validation against live systems
- API troubleshooting based on authentication and authorization boundaries
- Purpose-built service roles and effective-permission testing
- Secret, state, and plan-file protection
- Role-based Ansible configuration management
- Dependency-aware K3s bootstrap and sequential server joins
- Immutable installer pinning and SHA-256 artifact verification
- Secure in-memory handling of cluster join credentials
- Kubernetes Secrets encryption validation
- Cross-node scheduling, networking, Service routing, and DNS testing
- Kubernetes readiness, rolling-update, and graceful-termination design
- Client-visible availability testing during workload changes
- Embedded-etcd health and local snapshot validation
- Evidence-driven troubleshooting with minimal corrective changes
- Key-only SSH automation with controlled privilege escalation
- Pre-restart SSH validation
- Idempotence verification
- Feature-branch Git workflow
- Automated pull-request validation
- Read-only CI without infrastructure credentials
- Honest documentation of delivered work, limitations, and security debt

## Repository Structure

```text
homelab-portfolio/
├── .github/
│   └── workflows/    # Automated infrastructure validation
├── ansible/          # Linux baseline and K3s deployment roles, playbooks, and validation
├── diagrams/         # Architecture diagrams
├── docs/             # Runbooks and technical documentation
├── kubernetes/       # Kubernetes workload manifests and live-traffic validation
└── proxmox/
    └── opentofu/     # Proxmox modules, environments, and validation evidence
```

## Roadmap

- [x] Provision and validate an Ubuntu LXC with OpenTofu
- [x] Build and live-validate an idempotent Ansible Linux baseline
- [x] Add read-only GitHub Actions infrastructure validation
- [x] Build an isolated OPNsense lab network
- [x] Create and sanitize an Ubuntu cloud-image template
- [x] Provision three deterministic K3s virtual machines
- [x] Confirm a final drift-free OpenTofu plan
- [x] Configure dedicated key-based bastion access
- [x] Apply the Ansible Linux baseline to all three nodes
- [x] Prove three-node baseline idempotency
- [x] Deploy a three-server K3s control plane with embedded etcd
- [x] Validate embedded etcd, cluster DNS, networking, Service routing, and scheduling
- [x] Validate Kubernetes Secrets encryption and local etcd snapshot creation
- [x] Prove full K3s Ansible idempotence with `changed=0`
- [x] Deploy a declarative Kubernetes workload through Traefik
- [x] Validate application availability during protected rolling restarts
- [ ] Add an API virtual IP or external control-plane load balancer
- [ ] Integrate shared persistent storage from Unraid
- [ ] Add off-host etcd snapshot backups and complete a documented restore test
- [ ] Add monitoring and alerting
- [ ] Evaluate [Prime Agent](https://github.com/PrimeIntellect-ai/prime-agent) from [**PrimeIntellect-ai**](https://github.com/PrimeIntellect-ai) in an isolated Unraid sandbox for long-running infrastructure operations and incident-analysis workflows
- [ ] Add GitOps deployment
- [x] Publish the v0.4.0 release
- [x] Publish the v0.5.0 release

## Security

Credentials, API-token secrets, private keys, live inventory, local variable files, provider caches, saved plans, state files, and OPNsense configuration exports are excluded from version control.

Public example configuration contains placeholders only. Proxmox automation uses separate read-only and provisioning tokens, with a purpose-built provisioning role and documented effective-permission testing.

The validation record transparently documents a temporary broader parent ACL and the staged verification required before safely removing it.

K3s installation uses an immutable installer commit plus SHA-256 verification of both the installer and installed binary. Cluster configuration and token files are root-owned with mode `0600`.

Join credentials are suppressed from logs, held in a non-cacheable in-memory Ansible fact during deployment, and never committed to Git. Kubernetes Secrets encryption was enabled and validated across all three servers.

GitHub Actions uses read-only repository permissions and no live infrastructure credentials. Public CI performs static validation only and never runs OpenTofu `plan` or `apply`.

State files are treated as sensitive because infrastructure providers can store environment details and secret values in them.

## About

I am building this portfolio to demonstrate practical infrastructure skills through working systems, repeatable automation, controlled troubleshooting, validation, and clear technical documentation.

**Lee Austin**

[GitHub profile](https://github.com/Capasiter)
