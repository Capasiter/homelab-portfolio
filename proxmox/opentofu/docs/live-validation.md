# Proxmox OpenTofu Live Validation

- **Validation date:** July 17, 2026
- **Environment:** Development
- **Result:** Passed

## Purpose

This validation confirmed that the OpenTofu configuration could authenticate to Proxmox VE, refresh the managed resource, compare configuration with live infrastructure, and verify the resulting Ubuntu LXC container.

## Validated Stack

| Component | Version or Value |
|---|---|
| Proxmox VE | 9.2.x |
| OpenTofu | 1.11.6 |
| Proxmox provider | `bpg/proxmox` 0.66.0 |
| Environment | `environments/dev` |
| Module | `modules/ubuntu-lxc` |
| Resource | Ubuntu 24.04 LXC |
| Proxmox VM ID | 337 |
| Hostname | `ubuntu-dev-01` |

## OpenTofu Validation

Formatting and configuration validation completed successfully:

```console
tofu fmt -check -recursive
tofu validate
```

The local state contains the expected managed resource:

```console
module.ubuntu_lxc.proxmox_virtual_environment_container.lxc
```

The configured outputs returned:

```console
container_id = 337
container_name = "ubuntu-dev-01"
```

A refreshed execution plan completed successfully:

```console
module.ubuntu_lxc.proxmox_virtual_environment_container.lxc: Refreshing state... [id=337]

No changes. Your infrastructure matches the configuration.
```

This no-change plan confirms that the live container matches the OpenTofu configuration and that no configuration drift was detected during validation.

## Proxmox Runtime Verification

The container was also inspected directly from the Proxmox host with:

```console
pct status 337
pct config 337
pct exec 337 -- hostname
pct exec 337 -- ip -4 -brief address show eth0
pct exec 337 -- uptime -p
```

The runtime checks confirmed:

- Container status was `running`
- Hostname was `ubuntu-dev-01`
- Two CPU cores were assigned
- Memory was set to 3072 MB
- Swap was set to 512 MB
- Root disk was 16 GB
- Networking used DHCP on bridge `vmbr0`
- The network interface was up
- Start-on-boot was enabled
- The container was unprivileged
- Nesting was enabled

## Authentication and Authorization Troubleshooting

The first plan attempt returned an HTTP `401 Authentication failed` response. The local configuration referenced an invalid or previously rotated API-token secret.

A dedicated Proxmox service identity and API token were configured, after which the request authenticated successfully but returned HTTP `403 Permission check failed` for `VM.Audit`.

The required ACL permissions were then assigned to the service identity. A subsequent plan refreshed the container successfully and returned no changes.

This troubleshooting distinguished between:

- `401`: invalid authentication credentials
- `403`: valid identity with insufficient authorization

No API-token secret is stored in this repository.

## Security Controls

- A dedicated Proxmox API identity is used for OpenTofu
- The API token is marked sensitive in the OpenTofu configuration
- Real variable files are excluded from Git
- Local state files are excluded from Git
- Provider caches are excluded from Git
- The public example file contains placeholders only
- Previously exposed credentials were revoked and replaced

## Current Limitations

- State is stored locally
- Only the development environment has been deployed
- The project currently manages one Ubuntu LXC container
- Self-signed TLS certificates are permitted in the development environment
- Automated CI validation has not yet been implemented

## Next Milestone

The next project phase will use Ansible to apply a repeatable Linux server baseline to OpenTofu-provisioned infrastructure.
