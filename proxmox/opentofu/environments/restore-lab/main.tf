module "restore_lab" {
  source = "../../modules/ubuntu-vm"

  node_name          = var.node_name
  vm_id              = var.vm_id
  name               = var.name
  description        = "Disposable isolated K3s etcd restore-validation VM managed by OpenTofu"
  tags               = ["disposable", "k3s", "opentofu", "restore-lab"]
  startup_order      = 0
  startup_up_delay   = 0
  startup_down_delay = 0

  template_vm_id = var.template_vm_id
  cpu_cores      = var.cpu_cores
  cpu_type       = var.cpu_type
  agent_enabled  = false
  agent_trim     = false
  memory         = var.memory
  datastore_id   = var.datastore_id
  disk_size      = var.disk_size

  ip_address = "dhcp"
  username   = var.username

  ssh_public_keys = [
    trimspace(file(pathexpand(var.ssh_public_key_path)))
  ]

  bridge               = var.bridge
  network_disconnected = var.network_disconnected
  mac_address          = var.mac_address
}
