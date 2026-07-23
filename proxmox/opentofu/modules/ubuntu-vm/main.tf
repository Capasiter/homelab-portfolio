resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description
  tags        = var.tags

  started         = true
  on_boot         = true
  stop_on_destroy = true
  scsi_hardware   = "virtio-scsi-single"
  timeout_clone   = 1800
  timeout_create  = 1800

  agent {
    enabled = true
    trim    = true
    type    = "virtio"
  }

  clone {
    vm_id        = var.template_vm_id
    node_name    = var.node_name
    datastore_id = var.datastore_id
    full         = true
    retries      = 3
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      username = var.username
      keys     = var.ssh_public_keys
    }
  }

  network_device {
    bridge      = var.bridge
    model       = "virtio"
    mac_address = var.mac_address
  }

  operating_system {
    type = "l26"
  }
}
