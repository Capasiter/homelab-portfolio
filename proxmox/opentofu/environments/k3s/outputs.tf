output "k3s_node_ids" {
  description = "Proxmox VM IDs keyed by K3s node name."
  value = {
    for name, node in module.k3s_nodes : name => node.vm_id
  }
}
