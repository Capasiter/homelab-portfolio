# Proxmox Ubuntu VM Module

Reusable OpenTofu module for cloning and configuring Ubuntu cloud-init virtual machines on Proxmox VE.

## Capabilities

- Performs a full clone from an existing Proxmox VM template
- Configures CPU, memory, and operating-system disk resources
- Enables the QEMU guest agent
- Creates a non-root cloud-init administrative account
- Installs one or more SSH public keys
- Supports DHCP or static IPv4 configuration
- Assigns a deterministic MAC address
- Starts the VM automatically and enables startup on host boot
- Reports guest IP and MAC addresses through OpenTofu outputs

## Requirements

- OpenTofu 1.10 or newer
- `bpg/proxmox` provider version 0.66.0
- Proxmox VE API credentials with appropriate VM permissions
- Ubuntu cloud-init VM template
- QEMU guest agent installed and enabled in the template

The module clones an existing template. It does not create or prepare the source template.

## Example

```hcl
module "ubuntu_vm" {
  source = "../../modules/ubuntu-vm"

  node_name     = "pve"
  vm_id         = 401
  name          = "k3s-server-01"
  template_vm_id = 9100

  datastore_id = "local-lvm"
  cpu_cores    = 2
  memory       = 3072
  disk_size    = 32

  ip_address = "dhcp"
  username   = "ansible"

  ssh_public_keys = [
    trimspace(file(pathexpand("~/.ssh/homelab_ansible_ed25519.pub")))
  ]

  bridge      = "vmbr0"
  mac_address = "02:00:00:00:04:01"
}
```
