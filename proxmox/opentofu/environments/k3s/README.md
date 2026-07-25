# Proxmox K3s VM Environment

This OpenTofu environment provisions three Ubuntu 24.04 virtual machines that will form a highly available K3s control plane.

> **Current status:** The VM infrastructure is deployed and drift-free. K3s has not yet been installed.

OpenTofu manages the virtual-machine lifecycle. OPNsense provides isolated routing, DHCP, DNS forwarding, and outbound NAT. Ansible will configure the operating systems and install K3s in the next phase.

## Architecture

```mermaid
flowchart TD
    Management["Management network — vmbr0"] --> Proxmox["Proxmox VE management"]
    Management --> Firewall["OPNsense VM 400"]
    Firewall --> Lab["Isolated lab — vmbr1 — 10.20.0.0/24"]
    Lab --> Nodes["K3s servers — VMs 401–403"]
```

OPNsense connects the two virtual networks:

- WAN interface on `vmbr0`
- LAN gateway at `10.20.0.1` on `vmbr1`
- DHCP and DNS services for the isolated lab
- Outbound NAT for updates and package installation

The K3s VMs attach only to `vmbr1`. Traffic between the VMs remains inside Proxmox and does not require a physical uplink on the lab bridge.

## Managed Nodes

| Node | VM ID | Reserved address | MAC address |
|---|---:|---|---|
| `k3s-server-01` | 401 | `10.20.0.101` | `02:00:00:00:04:01` |
| `k3s-server-02` | 402 | `10.20.0.102` | `02:00:00:00:04:02` |
| `k3s-server-03` | 403 | `10.20.0.103` | `02:00:00:00:04:03` |

Deterministic MAC addresses allow OPNsense DHCP reservations to provide stable addresses without embedding static network configuration inside the VM template.

## VM Configuration

Each node is provisioned with:

| Setting | Value |
|---|---|
| Operating system | Ubuntu 24.04 Noble |
| Template VM ID | 9100 |
| Clone type | Full clone |
| CPU | 2 cores, host CPU type |
| Memory | 3072 MB |
| Disk | 32 GB on `local-lvm` |
| Network bridge | `vmbr1` |
| Cloud-init user | `ansible` |
| QEMU guest agent | Enabled |
| Start on boot | Enabled |
| Startup order | 2 |
| Startup delay | 15 seconds |
| Shutdown delay | 60 seconds |
| Troubleshooting console | Serial socket with `VGA serial0` |

The source template was sanitized before conversion to a Proxmox template. It contains no embedded credentials, machine identity, SSH host keys, logs, or temporary files.

## Dependency-Aware Startup

OPNsense uses startup order `1`. The K3s nodes use startup order `2`.

This ensures the lab gateway starts before the cluster nodes. Proxmox reverses the ordering during shutdown so dependent cluster nodes stop before the firewall. Startup and shutdown delays give network services time to become available and guests time to stop cleanly.

## Scope Boundaries

This environment manages VMs `401–403`.

The following are prerequisites managed outside this OpenTofu environment:

- OPNsense VM `400`
- OPNsense DHCP reservations and firewall policy
- Ubuntu cloud-image template `9100`
- Proxmox storage and virtual bridges
- Proxmox API users, roles, tokens, and ACL assignments

OPNsense configuration exports and API-token secrets are sensitive and must never be committed to Git.

## Configuration Workflow

From `proxmox/opentofu/environments/k3s`, copy the sanitized example and protect the local configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
chmod 600 terraform.tfvars
```

Update the local file with environment-specific values. Real `terraform.tfvars` files are ignored by Git.

Initialize and validate:

```bash
tofu init
tofu fmt -check
tofu validate
```

Review the complete execution plan:

```bash
tofu plan
```

Apply only after resolving the exact target resources and reviewing every proposed action:

```bash
tofu apply
```

Saved plans, state files, provider caches, and real variable files must remain outside version control.

## Deployment Validation

Live validation confirmed:

- All three VMs were cloned successfully from template `9100`
- Guest-agent results matched the declared MAC and reserved IP mappings
- Hostnames matched the OpenTofu `for_each` keys
- Cloud-init completed successfully on every node
- QEMU guest agent was active on every node
- Default routes used the isolated OPNsense gateway
- Outbound connectivity through OPNsense NAT succeeded
- DNS resolution succeeded
- A final full OpenTofu plan reported no changes
- No targeted-planning warning appeared in the final plan

Detailed evidence and troubleshooting notes are recorded in [K3s Live Validation](../../docs/k3s-live-validation.md).

## Management Access

The management workstation does not have a direct route into `10.20.0.0/24`. Initial validation used an SSH jump through the Proxmox host.

Before routine Ansible automation, the environment will receive a dedicated unprivileged bastion identity using SSH-key authentication. This preserves isolation without modifying the upstream router or exposing the lab network directly.

## Security Practices

- K3s nodes attach only to the isolated lab bridge
- Real variable files and OpenTofu state are ignored
- The committed example contains placeholder credentials only
- Proxmox automation uses a dedicated service identity
- Provisioning permissions are assigned through a purpose-built role
- API authentication and authorization failures were diagnosed separately
- Serial-console access remains available for recovery
- A final full plan verifies that targeted recovery work introduced no drift

## Next Steps

1. Configure secure bastion access for Ansible
2. Add the three nodes to the Ansible inventory
3. Apply and re-run the Linux baseline to prove idempotency
4. Install the three-node K3s control plane
5. Validate embedded etcd membership and cluster health
6. Add persistent storage, monitoring, backups, and GitOps
