locals {
  k3s_nodes = {
    k3s-server-01 = {
      vm_id       = 401
      mac_address = "02:00:00:00:04:01"
    }

    k3s-server-02 = {
      vm_id       = 402
      mac_address = "02:00:00:00:04:02"
    }

    k3s-server-03 = {
      vm_id       = 403
      mac_address = "02:00:00:00:04:03"
    }
  }
}

module "k3s_nodes" {
  source   = "../../modules/ubuntu-vm"
  for_each = local.k3s_nodes

  node_name   = var.node_name
  vm_id       = each.value.vm_id
  name        = each.key
  description = "K3s control-plane node managed by OpenTofu"
  tags        = ["k3s", "control-plane", "opentofu"]

  template_vm_id = var.template_vm_id
  cpu_cores      = var.cpu_cores
  cpu_type       = var.cpu_type
  memory         = var.memory
  datastore_id   = var.datastore_id
  disk_size      = var.disk_size

  ip_address = "dhcp"
  username   = var.username

  ssh_public_keys = [
    trimspace(file(pathexpand(var.ssh_public_key_path)))
  ]

  bridge      = var.bridge
  mac_address = each.value.mac_address
}
