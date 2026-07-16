module "ubuntu_lxc" {
  source = "../../modules/ubuntu-lxc"

  node_name        = var.node_name
  vm_id            = var.vm_id
  hostname         = var.hostname
  description      = var.description
  ip_address       = var.ip_address
  cpu_cores        = var.cpu_cores
  memory           = var.memory
  swap             = var.swap
  datastore_id     = var.datastore_id
  disk_size        = var.disk_size
  template_file_id = var.template_file_id
  bridge           = var.bridge
}
