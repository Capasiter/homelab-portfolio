output "container_id" {
  description = "The Proxmox virtual machine ID assigned to the LXC container."
  value       = module.ubuntu_lxc.container_id
}

output "container_name" {
  description = "The hostname assigned to the LXC container."
  value       = module.ubuntu_lxc.container_name
}
