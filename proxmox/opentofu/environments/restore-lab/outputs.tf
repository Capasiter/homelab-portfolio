output "restore_lab_vm_id" {
  description = "Proxmox VM ID of the disposable restore lab."
  value       = module.restore_lab.vm_id
}

output "restore_lab_vm_name" {
  description = "Name of the disposable restore lab."
  value       = module.restore_lab.vm_name
}

output "restore_lab_network_disconnected" {
  description = "Whether the restore-lab NIC is disconnected from its bridge."
  value       = var.network_disconnected
}
