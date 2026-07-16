output "container_id" {
  value = proxmox_virtual_environment_container.ubuntu2404.vm_id
}

output "container_name" {
  value = proxmox_virtual_environment_container.ubuntu2404.initialization[0].hostname
}
