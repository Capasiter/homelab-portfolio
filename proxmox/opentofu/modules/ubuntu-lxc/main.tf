resource "proxmox_virtual_environment_container" "lxc" {
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description

  started       = true
  start_on_boot = true
  unprivileged  = true

  features {
    nesting = true
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip_address
      }
    }
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = "ubuntu"
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }
}
