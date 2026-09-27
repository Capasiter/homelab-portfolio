variable "proxmox_endpoint" {
  description = "URL of the Proxmox VE API endpoint."
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow a self-signed Proxmox TLS certificate."
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Proxmox node hosting the restore-lab VM."
  type        = string
  default     = "pve"
}

variable "vm_id" {
  description = "Unique Proxmox VM identifier for the disposable restore lab."
  type        = number
  default     = 404
}

variable "name" {
  description = "Name and hostname of the disposable restore-lab VM."
  type        = string
  default     = "k3s-restore-lab-01"
}

variable "template_vm_id" {
  description = "VM ID of the sanitized Ubuntu 24.04 cloud-init template."
  type        = number
  default     = 9100
}

variable "cpu_cores" {
  description = "Virtual CPU cores allocated to the restore lab."
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "Proxmox CPU model exposed to the restore lab."
  type        = string
  default     = "host"
}

variable "memory" {
  description = "Memory allocated to the restore lab in megabytes."
  type        = number
  default     = 4096
}

variable "datastore_id" {
  description = "Proxmox datastore for the restore-lab VM."
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Operating-system disk size for the restore lab in gigabytes."
  type        = number
  default     = 32
}

variable "username" {
  description = "Cloud-init administrative account."
  type        = string
  default     = "ansible"
}

variable "ssh_public_key_path" {
  description = "Local path to the SSH public key installed by cloud-init."
  type        = string
  default     = "~/.ssh/homelab_ansible_ed25519.pub"
}

variable "bridge" {
  description = "Temporary staging bridge. Do not set this to vmbr1."
  type        = string
  default     = "vmbr0"
}

variable "network_disconnected" {
  description = "Keep the restore-lab NIC disconnected. Set false only for deliberate staging, then return it to true before restore."
  type        = bool
  default     = true
}

variable "mac_address" {
  description = "Deterministic MAC address assigned to the restore-lab VM."
  type        = string
  default     = "02:00:00:00:04:04"
}
