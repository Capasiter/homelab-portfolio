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

variable "hostname" {
  description = "Hostname assigned to the LXC container."
  type        = string
}

variable "description" {
  description = "Container description in Proxmox."
  type        = string
  default     = "Managed by OpenTofu"
}

variable "ip_address" {
  description = "IPv4 address with prefix, or dhcp."
  type        = string
  default     = "dhcp"
}

variable "cpu_cores" {
  description = "CPU cores allocated to the container."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Container memory in megabytes."
  type        = number
  default     = 2048
}

variable "swap" {
  description = "Container swap in megabytes."
  type        = number
  default     = 512
}

variable "datastore_id" {
  description = "Proxmox datastore for the container disk."
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
  description = "Proxmox network bridge."
  type        = string
  default     = "vmbr0"
}
