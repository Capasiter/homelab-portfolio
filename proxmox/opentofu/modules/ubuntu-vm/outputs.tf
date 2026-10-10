output "vm_id" {
  description = "Proxmox identifier of the virtual machine."
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "Name of the virtual machine."
  value       = proxmox_virtual_environment_vm.vm.name
}

output "node_name" {
  description = "Proxmox node hosting the virtual machine."
  value       = proxmox_virtual_environment_vm.vm.node_name
}
