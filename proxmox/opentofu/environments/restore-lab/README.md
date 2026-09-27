# Isolated K3s Restore Lab

This environment creates a disposable single-node VM for validating K3s embedded-etcd restore procedures. It is intentionally separate from the production K3s control plane.

## Safety Boundary

- Uses VM ID 404, which was verified unused before this environment was added.
- Clones the sanitized Ubuntu 24.04 template (9100).
- Defaults to vmbr0 only as a temporary staging bridge; it must never use the production vmbr1 bridge.
- Keeps its NIC disconnected by default.
- Uses a distinct deterministic MAC address.
- Disables QEMU guest-agent integration during the offline phase so OpenTofu does not wait for an unavailable DHCP address.
- Is not joined to the production K3s cluster and must not use the production K3s configuration directory.

## Two-Phase Workflow

1. Copy the example values into ignored terraform.tfvars, set network_disconnected = false, and apply only to stage the VM with a newer K3s patch and copies of the snapshot and server token.
2. Set network_disconnected = true, apply the network-disconnect change, then use the Proxmox console to run the restore drill. Do not reconnect the VM to vmbr1.

The staging phase is intentionally not a restore. The restore begins only after the NIC is disconnected and the production snapshot and token have been copied locally.

## Validation Commands

~~~bash
tofu -chdir=proxmox/opentofu/environments/restore-lab init -backend=false
tofu -chdir=proxmox/opentofu/environments/restore-lab validate
tofu -chdir=proxmox/opentofu/environments/restore-lab plan
~~~

The initial configuration remains safe to review because the default network state is disconnected. Creating the VM still requires an explicit reviewed apply.
