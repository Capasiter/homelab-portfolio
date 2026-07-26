# Proxmox K3s Infrastructure Live Validation

- **Validation date:** July 25, 2026
- **Environment:** K3s infrastructure
- **Result:** Passed
- **Deployment state:** Three Ubuntu VMs deployed; K3s installation pending

## Purpose

This validation confirmed that OpenTofu could provision and reconcile three Ubuntu virtual machines on an isolated Proxmox network while preserving deterministic addressing, dependency-aware startup, serial-console recovery, and secure credential handling.

The validation covered the infrastructure layer only. Ansible configuration and K3s installation are separate milestones.

See the [K3s environment guide](../environments/k3s/README.md) for the reusable configuration and architecture.

## Validated Stack

| Component | Version or value |
|---|---|
| Proxmox VE | 9.2.x |
| OpenTofu | 1.12.4 |
| Proxmox provider | `bpg/proxmox` 0.66.0 |
| Environment | `environments/k3s` |
| Module | `modules/ubuntu-vm` |
| Operating system | Ubuntu 24.04 Noble |
| Template VM ID | 9100 |
| Firewall and lab gateway | OPNsense VM 400 |
| Isolated subnet | `10.20.0.0/24` |
| Isolated bridge | `vmbr1` |

## Scope and Architecture

The OpenTofu environment manages only K3s VMs `401–403`.

OPNsense VM `400`, the Ubuntu template, Proxmox bridges, DHCP reservations, and API authorization are external prerequisites. Keeping these boundaries explicit prevents OpenTofu from unintentionally changing shared management infrastructure.

The K3s VMs connect only to `vmbr1`. OPNsense connects its LAN interface to `vmbr1` and provides:

- Gateway service at `10.20.0.1`
- DHCP reservations
- DNS forwarding
- Outbound NAT
- Separation from the Proxmox management network

The isolated bridge carries VM-to-VM traffic internally and does not require a connected physical uplink.

## Pre-Deployment Safety Controls

Before provisioning:

- A current Proxmox Backup Server backup of OPNsense was created
- The existing Proxmox management bridge and default gateway were left unchanged
- The isolated bridge was verified without adding a gateway
- The physical lab interface remained disconnected
- The Ubuntu template checksum was verified against Ubuntu’s published checksum
- The template was sanitized before conversion to a reusable cloud-init template
- Real variable files and state files were excluded from Git
- The local `terraform.tfvars` file was restricted to owner read/write permissions

No upstream-router configuration was changed.

## Deterministic Node Mapping

| Node | VM ID | Reserved address | MAC address |
|---|---:|---|---|
| `k3s-server-01` | 401 | `10.20.0.101` | `02:00:00:00:04:01` |
| `k3s-server-02` | 402 | `10.20.0.102` | `02:00:00:00:04:02` |
| `k3s-server-03` | 403 | `10.20.0.103` | `02:00:00:00:04:03` |

The OpenTofu `for_each` map binds each hostname to a stable VM ID and MAC address. OPNsense DHCP reservations then provide predictable addresses without placing environment-specific static networking inside the template.

## Deployment Strategy

### Canary Deployment

`k3s-server-01` was deployed first as a canary.

This limited the initial blast radius while validating:

- Template cloning
- Cloud-init behavior
- API permissions
- Storage allocation
- Isolated networking
- DHCP reservation matching
- QEMU guest-agent reporting
- SSH reachability through a jump host

Targeted planning and application were used only for the controlled canary and recovery work. A normal full plan was required afterward to validate the complete environment.

### Remaining Nodes

After the canary path was validated, `k3s-server-02` and `k3s-server-03` were provisioned.

The successful apply summary was:

```console
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### Final Reconciliation

After all recovery and targeted operations, a standard full plan refreshed all three resources. This ensured the environment was evaluated as a whole and removed any ambiguity created by targeted operations.

## Authentication and Authorization Troubleshooting

The first live request returned HTTP `401 Authentication failed`.

The local configuration referenced an obsolete API-token identity. It was corrected to use the dedicated provisioning token associated with the OpenTofu service account. No token secret was committed or copied into documentation.

After authentication succeeded, cloning began but VM configuration returned:

```console
Permission check failed (/, Sys.Modify)
```

This was an authorization failure rather than an authentication failure.

`Sys.Modify` was added to the purpose-built `OpenTofuVMProvisioner` role. Because the provisioning token uses privilege separation, its effective permissions are the intersection of the parent user’s ACLs and the token’s ACLs. The custom role therefore also had to be available through the parent identity.

The effective provisioning permissions were then verified directly. They cover:

- Datastore allocation and auditing
- SDN and network use
- System auditing and required system modification
- VM allocation, audit, and cloning
- CPU, memory, disk, network, cloud-init, CD-ROM, and option configuration
- Guest-agent auditing
- VM power management

This troubleshooting distinguished three separate failure classes:

| Failure | Meaning | Resolution |
|---|---|---|
| HTTP `401` | Invalid or obsolete credentials | Correct the local token identity |
| HTTP `403` | Authenticated but unauthorized | Add the missing role privilege |
| Privilege-intersection failure | Token ACL exceeded parent ACL | Correct both sides of the privilege-separated identity |

### Authorization Hardening Follow-Up

The parent service account temporarily retains a broader `PVEAdmin` assignment while both the read-only portfolio token and provisioning token are verified.

Future cleanup will:

1. Add the required audit role to the parent identity
2. Verify effective permissions for both tokens
3. Confirm read-only and provisioning workflows independently
4. Remove the broader parent assignment only after those tests pass

This avoids breaking either token by removing permissions blindly.

## Tainted-Resource Recovery

The canary clone completed before the provider encountered the missing `Sys.Modify` permission. This left the canary resource requiring controlled recovery.

Before retrying:

- The exact VM and OpenTofu resource address were resolved
- The proposed recovery action was reviewed
- Authorization was corrected before another apply
- Recovery remained limited to the identified canary resource

After recovery, the normal full plan confirmed that all three VMs matched configuration. This final reconciliation was required before considering the deployment complete.

## Runtime Validation

Each guest was validated through Proxmox guest-agent results and SSH through a temporary jump path.

The following checks passed on all three nodes:

| Check | Result |
|---|---|
| Expected VM ID | Passed |
| Expected hostname | Passed |
| Expected MAC address | Passed |
| Reserved IPv4 address | Passed |
| Cloud-init status | `done` |
| QEMU guest agent | `active` |
| Default gateway | `10.20.0.1` |
| Outbound ICMP through NAT | Passed with 0% packet loss |
| DNS resolution | Passed |
| Automatic startup | Enabled |
| Serial troubleshooting console | Available |

## Startup and Shutdown Validation

OPNsense is assigned startup order `1`. The K3s nodes are assigned startup order `2`.

Each K3s node also receives:

```text
startup_order      = 2
startup_up_delay   = 15
startup_down_delay = 60
```

This preserves the network dependency during startup and reverses it during shutdown so the cluster nodes stop before their gateway.

## Final Drift Check

The final non-targeted OpenTofu plan refreshed every managed VM:

```console
module.k3s_nodes["k3s-server-01"].proxmox_virtual_environment_vm.vm: Refreshing state... [id=401]
module.k3s_nodes["k3s-server-02"].proxmox_virtual_environment_vm.vm: Refreshing state... [id=402]
module.k3s_nodes["k3s-server-03"].proxmox_virtual_environment_vm.vm: Refreshing state... [id=403]

No changes. Your infrastructure matches the configuration.
```

No targeting warning appeared in the final plan.

This confirms:

- All declared resources exist
- Live settings match the committed configuration
- Recovery work did not leave configuration drift
- No additional changes or replacements were pending

## Security Controls

- Real `terraform.tfvars` files are ignored by Git
- The local variable file uses owner-only permissions
- API-token secrets are absent from tracked files
- The committed example contains placeholder values only
- OpenTofu state and saved plans are excluded from Git
- Temporary K3s plan files were reviewed and deleted
- OPNsense configuration exports remain outside the repository
- The Ubuntu template contains no embedded credentials or machine identity
- K3s nodes attach only to the isolated lab bridge
- Provisioning uses a dedicated service identity and custom role
- A broader parent ACL is documented as temporary security debt

## Current Management Limitation

The management workstation does not currently route directly into `10.20.0.0/24`.

Initial SSH validation used the Proxmox host as a temporary jump point and required interactive authentication. Routine automation will not depend on that path.

Before Ansible configuration begins, a dedicated unprivileged jump identity will be created with:

- SSH-key-only authentication
- No root login
- No unnecessary interactive privileges
- Access limited to forwarding management connections into the lab

This preserves network isolation without modifying the upstream router.

## Validation Outcome

The infrastructure phase passed.

OpenTofu now reproducibly manages three isolated Ubuntu VMs with deterministic identities, dependency-aware startup, guest-agent visibility, serial recovery access, and a drift-free final state.

The next milestone is to establish secure bastion access, apply the Ansible Linux baseline twice to prove idempotency, and then deploy the three-node K3s control plane.
