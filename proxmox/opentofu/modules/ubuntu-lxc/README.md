# Proxmox Ubuntu LXC Module

Reusable OpenTofu module for deploying an Ubuntu LXC container on Proxmox VE.

The module creates an unprivileged container with configurable compute, storage, and networking. Nesting is enabled to support container-based workloads and future lab services.

## Requirements

- OpenTofu 1.10 or newer
- Proxmox VE
- `bpg/proxmox` provider version 0.66.0
- Ubuntu LXC template available in Proxmox storage

## Usage

    module "ubuntu_lxc" {
      source = "../../modules/ubuntu-lxc"

      node_name        = "pve"
      vm_id            = 337
      hostname         = "ubuntu-dev-01"
      description      = "OpenTofu-managed Ubuntu development container"
      ip_address       = "dhcp"
      cpu_cores        = 2
      memory           = 2048
      swap             = 512
      datastore_id     = "local-lvm"
      disk_size        = 16
      template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
      bridge           = "vmbr0"
    }

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `node_name` | Proxmox node used for the container | `string` | — | Yes |
| `vm_id` | Numeric Proxmox VM ID | `number` | — | Yes |
| `hostname` | Hostname assigned to the container | `string` | — | Yes |
| `description` | Description displayed in Proxmox | `string` | `"Managed by OpenTofu"` | No |
| `ip_address` | IPv4 address with prefix length, or DHCP | `string` | `"dhcp"` | No |
| `cpu_cores` | Number of allocated CPU cores | `number` | `2` | No |
| `memory` | Dedicated memory in megabytes | `number` | `2048` | No |
| `swap` | Swap memory in megabytes | `number` | `512` | No |
| `datastore_id` | Datastore used for the container disk | `string` | — | Yes |
| `disk_size` | Container disk size in gigabytes | `number` | — | Yes |
| `template_file_id` | Proxmox LXC template file ID | `string` | — | Yes |
| `bridge` | Proxmox network bridge | `string` | `"vmbr0"` | No |

## Outputs

| Name | Description |
|---|---|
| `container_id` | Proxmox VM ID assigned to the container |
| `container_name` | Hostname assigned to the container |

## Container Behavior

The module creates an unprivileged container, enables nesting, starts the container after creation, and configures it to start automatically with the Proxmox node.

## Security

Credentials, API tokens, state files, and environment-specific variable files must not be committed to version control.
