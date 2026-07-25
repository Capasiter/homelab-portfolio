# Proxmox OpenTofu Infrastructure

This directory contains reusable OpenTofu modules and environment compositions for provisioning infrastructure on Proxmox VE.

The portfolio demonstrates modular Infrastructure as Code, isolated virtual networking, cloud-init automation, dependency-aware startup, secure API usage, controlled recovery, and live drift validation.

## Delivered Infrastructure

| Milestone | Environment | Managed infrastructure | Status |
|---|---|---|---|
| v0.1.0 | `environments/dev` | Ubuntu 24.04 LXC container | Released and drift-free |
| v0.4.0 | `environments/k3s` | Three Ubuntu 24.04 K3s VMs | Infrastructure deployed; K3s installation pending |

### Development LXC

The development environment manages:

| Setting | Value |
|---|---|
| Container ID | 337 |
| Hostname | `ubuntu-dev-01` |
| CPU | 2 cores |
| Memory | 3072 MB |
| Disk | 16 GB |
| Network | DHCP on `vmbr0` |
| Container type | Unprivileged |
| Start on boot | Enabled |

See [LXC Live Validation](docs/live-validation.md).

### K3s VM Infrastructure

The K3s environment manages:

| Node | VM ID | Reserved address | Network |
|---|---:|---|---|
| `k3s-server-01` | 401 | `10.20.0.101` | Isolated `vmbr1` |
| `k3s-server-02` | 402 | `10.20.0.102` | Isolated `vmbr1` |
| `k3s-server-03` | 403 | `10.20.0.103` | Isolated `vmbr1` |

Each node is a full clone of a sanitized Ubuntu 24.04 cloud-image template with two CPU cores, 3072 MB of memory, a 32 GB disk, QEMU guest-agent support, cloud-init, automatic startup, and serial-console access.

OPNsense provides DHCP, DNS forwarding, outbound NAT, and the gateway for the isolated lab. OpenTofu does not manage the OPNsense configuration or the upstream household network.

See:

- [K3s Environment Guide](environments/k3s/README.md)
- [K3s Live Validation](docs/k3s-live-validation.md)

## Responsibility Boundaries

The project separates infrastructure lifecycle from operating-system configuration:

| Layer | Responsibility |
|---|---|
| OpenTofu | Proxmox containers, VMs, disks, CPU, memory, networking, cloning, and startup policy |
| Cloud-init | Initial hostname, automation user, SSH public key, and first-boot initialization |
| Ansible | Packages, Linux baseline, SSH policy, services, and K3s installation |
| OPNsense | Isolated lab routing, DHCP reservations, DNS forwarding, firewall policy, and NAT |
| K3s | Cluster control plane, embedded etcd, scheduling, and Kubernetes services |

This separation makes each layer independently testable and prevents configuration-management concerns from being embedded in the infrastructure module.

## Repository Structure

```text
proxmox/opentofu/
├── docs/
│   ├── live-validation.md
│   └── k3s-live-validation.md
├── environments/
│   ├── dev/
│   └── k3s/
│       ├── README.md
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── terraform.tfvars.example
│       ├── variables.tf
│       └── versions.tf
├── modules/
│   ├── ubuntu-lxc/
│   └── ubuntu-vm/
├── archive/
├── .gitignore
└── README.md
```

- `modules/ubuntu-lxc/` defines a reusable unprivileged Ubuntu container.
- `modules/ubuntu-vm/` defines a reusable cloud-init Ubuntu virtual machine.
- `environments/dev/` deploys the development LXC.
- `environments/k3s/` deploys the isolated three-node VM foundation.
- `docs/` contains live validation and troubleshooting evidence.
- `archive/` preserves earlier prototype configuration for project history.

## Reusable Ubuntu VM Module

The `ubuntu-vm` module supports:

- Full cloning from a Proxmox template
- Stable VM IDs, names, tags, and MAC addresses
- Configurable CPU, memory, disk, storage, and bridge
- Cloud-init user and SSH public-key injection
- DHCP or environment-defined IP configuration
- QEMU guest-agent integration
- Start-on-boot behavior
- Validated startup order and delay values
- Serial socket and `VGA serial0` recovery access
- Structured outputs for VM identity and networking

Input validation rejects invalid resource sizes, malformed MAC addresses, and negative or fractional startup values before the provider can modify infrastructure.

## Requirements

- Proxmox VE with API access
- OpenTofu 1.10.0 or newer
- A compatible Proxmox template
- The `bpg/proxmox` provider
- Proxmox storage and virtual bridges
- A dedicated API service identity
- Appropriate datastore, network, system, VM, and guest-agent permissions
- An SSH public key for the cloud-init automation user
- A gateway and DHCP service for isolated environments

The K3s environment was validated with:

- OpenTofu 1.12.4
- `bpg/proxmox` provider 0.66.0
- Proxmox VE 9.2.x
- Ubuntu 24.04 Noble

## Safe Workflow

Run environment commands from the repository root.

Initialize:

```bash
tofu -chdir=proxmox/opentofu/environments/k3s init
```

Check formatting and configuration:

```bash
tofu fmt -check proxmox/opentofu/modules/ubuntu-vm
tofu fmt -check proxmox/opentofu/environments/k3s
tofu -chdir=proxmox/opentofu/environments/k3s validate
```

Review the entire environment:

```bash
tofu -chdir=proxmox/opentofu/environments/k3s plan
```

Apply only after reviewing every proposed action and resolving the exact target resources:

```bash
tofu -chdir=proxmox/opentofu/environments/k3s apply
```

Targeted operations may be useful for controlled canary deployment or recovery, but a normal full plan is always required afterward.

## Security Practices

- Real `terraform.tfvars` files are excluded from Git
- OpenTofu state and saved plans are excluded from Git
- Provider caches and local override files are excluded from Git
- Example files contain placeholder credentials only
- API tokens are marked sensitive
- Read-only and provisioning workflows use separate tokens
- Provisioning uses a purpose-built Proxmox role
- Effective permissions are verified for privilege-separated tokens
- OPNsense configuration exports remain outside the repository
- Cloud-image templates are sanitized before reuse
- State files are treated as sensitive infrastructure data
- Previously exposed credentials were revoked and replaced

## Validation Approach

Infrastructure is not considered complete after a successful apply alone.

Validation includes:

1. OpenTofu formatting and configuration validation
2. Plan review before every apply
3. Guest-agent verification of MAC and IP mappings
4. Hostname and cloud-init verification
5. Default-route, NAT, and DNS checks
6. Service checks inside each guest
7. A final non-targeted OpenTofu plan
8. Confirmation that no drift or pending replacement remains

This workflow distinguishes successful resource creation from a validated, operational environment.

## Current Limitations

- OpenTofu state remains local rather than using a remote backend
- The homelab permits a self-signed Proxmox certificate
- OPNsense and DHCP reservations are external prerequisites
- The management workstation does not directly route into the isolated subnet
- Management access to the isolated subnet intentionally depends on a restricted, forwarding-only Proxmox bastion
- The broader parent API ACL requires staged hardening after both tokens are verified
- K3s has not yet been installed
- Persistent Kubernetes storage, monitoring, backups, and GitOps are future phases

## Next Milestone

The infrastructure and Linux baseline phases are complete. The next phase will:

1. Build and review the Ansible K3s installation automation
2. Deploy the initial K3s server as a controlled canary
3. Join the remaining two control-plane servers
4. Validate embedded etcd membership, cluster health, scheduling, DNS, storage, and networking
5. Document the live cluster evidence and publish v0.4.0
6. Add persistent storage, monitoring, backups, and GitOps
