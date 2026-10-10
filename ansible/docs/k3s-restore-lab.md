# Isolated K3s Restore Lab Staging

This playbook stages a disposable restore target only. It never targets the production K3s inventory.

## Target

- VM: k3s-restore-lab-01 (Proxmox VM 404)
- Temporary staging address: DHCP on vmbr0
- Restore network state: NIC disconnected before the restore command
- K3s version: v1.36.4+k3s1
- K3s state during staging: installed and checksum-verified, but stopped

## Safety Sequence

1. Run the staging playbook only while the VM is on the temporary vmbr0 staging network.
2. Copy the selected production snapshot and matching server-token backup to the VM.
3. Disconnect the VM NIC through the restore-lab OpenTofu environment.
4. Use the Proxmox console for the restore command and verification.
5. Do not connect the restored VM to vmbr1.

## Staging Command

~~~bash
ANSIBLE_HOST_KEY_CHECKING=True ansible-playbook \
  -i '192.168.0.182,' \
  -u ansible \
  --private-key ~/.ssh/homelab_ansible_ed25519 \
  ansible/playbooks/k3s_restore_lab_stage.yml
~~~
