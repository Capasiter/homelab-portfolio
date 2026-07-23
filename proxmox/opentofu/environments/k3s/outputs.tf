output "k3s_node_ids" {
  description = "Proxmox VM IDs keyed by K3s node name."
  value = {
    for name, node in module.k3s_nodes : name => node.vm_id
  }
}

output "k3s_node_ipv4_addresses" {
  description = "IPv4 addresses reported by each node's QEMU guest agent."
  value = {
    for name, node in module.k3s_nodes : name => node.ipv4_addresses
  }
}

output "k3s_node_mac_addresses" {
  description = "MAC addresses keyed by K3s node name."
  value = {
    for name, node in module.k3s_nodes : name => node.mac_addresses
  }
}
