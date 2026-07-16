variable "node_name" {
  description = "Proxmox node used for the container."
  type        = string
}

variable "vm_id" {
  description = "Numeric Proxmox VM ID."
  type        = number

  validation {
    condition     = var.vm_id >= 100
    error_message = "vm_id must be at least 100."
  }
}

variable "description" {
  description = "Container description displayed in Proxmox."
  type        = string
  default     = "Managed by OpenTofu"
}

variable "hostname" {
  description = "Hostname assigned to the LXC container."
  type        = string
}

variable "ip_address" {
  description = "IPv4 address with prefix length, or dhcp."
  type        = string
  default     = "dhcp"
}

variable "cpu_cores" {
  description = "Number of CPU cores allocated to the container."
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_cores >= 1
    error_message = "cpu_cores must be at least 1."
  }
}

variable "memory" {
  description = "Dedicated container memory in megabytes."
  type        = number
  default     = 2048

  validation {
    condition     = var.memory >= 512
    error_message = "memory must be at least 512 MB."
  }
}

variable "swap" {
  description = "Container swap memory in megabytes."
  type        = number
  default     = 512

  validation {
    condition     = var.swap >= 0
    error_message = "swap cannot be negative."
  }
}

variable "datastore_id" {
  description = "Proxmox datastore used for the container disk."
  type        = string
}

variable "disk_size" {
  description = "Container disk size in gigabytes."
  type        = number

  validation {
    condition     = var.disk_size >= 4
    error_message = "disk_size must be at least 4 GB."
  }
}

variable "template_file_id" {
  description = "Proxmox LXC template file ID."
  type        = string
}

variable "bridge" {
  description = "Proxmox network bridge attached to the container."
  type        = string
  default     = "vmbr0"
}
