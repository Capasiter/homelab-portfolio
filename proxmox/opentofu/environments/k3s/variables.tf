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
  description = "Proxmox node on which the K3s VMs will run."
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "VM ID of the Ubuntu 24.04 cloud-init template."
  type        = number
  default     = 9100

  validation {
    condition     = var.template_vm_id >= 100
    error_message = "template_vm_id must be at least 100."
  }
}

variable "cpu_cores" {
  description = "Virtual CPU cores allocated to each K3s node."
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_cores >= 1
    error_message = "cpu_cores must be at least 1."
  }
}

variable "cpu_type" {
  description = "Proxmox CPU model exposed to each VM."
  type        = string
  default     = "host"
}

variable "memory" {
  description = "Memory allocated to each K3s node in megabytes."
  type        = number
  default     = 3072

  validation {
    condition     = var.memory >= 2048
    error_message = "memory must be at least 2048 MB for a K3s server."
  }
}

variable "datastore_id" {
  description = "Proxmox datastore for VM and cloud-init disks."
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Operating-system disk size for each node in gigabytes."
  type        = number
  default     = 32

  validation {
    condition     = var.disk_size >= 16
    error_message = "disk_size must be at least 16 GB."
  }
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
  description = "Proxmox network bridge attached to each VM."
  type        = string
  default     = "vmbr0"
}
