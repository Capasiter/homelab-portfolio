output "container_id" {
  description = "The Proxmox virtual machine ID assigned to the LXC container."
  value       = proxmox_virtual_environment_container.lxc.vm_id
}

output "container_name" {
  description = "The hostname assigned to the LXC container."
  value       = var.hostname
}
