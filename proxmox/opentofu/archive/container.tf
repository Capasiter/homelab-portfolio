resource "proxmox_virtual_environment_container" "ubuntu2404" {

  node_name = "pve"
  vm_id     = 999

  description = "Managed by OpenTofu"

  initialization {

    hostname = "ubuntu2404"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 16
  }

  operating_system {

    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

    type = "ubuntu"

  }

  network_interface {

    name   = "eth0"
    bridge = "vmbr0"

  }

}
