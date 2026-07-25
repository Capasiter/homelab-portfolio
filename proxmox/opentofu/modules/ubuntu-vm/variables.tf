variable "node_name" {
  description = "Proxmox node on which the VM will run."
  type        = string
}

variable "vm_id" {
  description = "Unique Proxmox VM identifier."
  type        = number

  validation {
    condition     = var.vm_id >= 100 && var.vm_id == floor(var.vm_id)
    error_message = "vm_id must be a whole number of at least 100."
  }
}

variable "name" {
  description = "Name and hostname of the virtual machine."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9.-]*$", var.name))
    error_message = "name may contain letters, numbers, periods, and hyphens."
  }
}

variable "description" {
  description = "Description displayed in Proxmox."
  type        = string
  default     = "Ubuntu VM managed by OpenTofu"
}

variable "tags" {
  description = "Tags assigned to the Proxmox VM."
  type        = list(string)
  default     = ["opentofu", "ubuntu"]
}

variable "template_vm_id" {
  description = "VM ID of the Ubuntu cloud-init template to clone."
  type        = number

  validation {
    condition     = var.template_vm_id >= 100 && var.template_vm_id == floor(var.template_vm_id)
    error_message = "template_vm_id must be a whole number of at least 100."
  }
}

variable "cpu_cores" {
  description = "Number of virtual CPU cores."
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_cores >= 1 && var.cpu_cores == floor(var.cpu_cores)
    error_message = "cpu_cores must be a positive whole number."
  }
}

variable "cpu_type" {
  description = "Proxmox CPU model exposed to the VM."
  type        = string
  default     = "host"
}

variable "memory" {
  description = "Dedicated VM memory in megabytes."
  type        = number
  default     = 3072

  validation {
    condition     = var.memory >= 1024
    error_message = "memory must be at least 1024 MB."
  }
}

variable "datastore_id" {
  description = "Proxmox datastore used for the cloned VM disk and cloud-init disk."
  type        = string
}

variable "disk_size" {
  description = "VM operating-system disk size in gigabytes."
  type        = number
  default     = 32

  validation {
    condition     = var.disk_size >= 8
    error_message = "disk_size must be at least 8 GB."
  }
}

variable "ip_address" {
  description = "IPv4 address in CIDR notation, or dhcp."
  type        = string
  default     = "dhcp"

  validation {
    condition     = lower(var.ip_address) == "dhcp" || can(cidrnetmask(var.ip_address))
    error_message = "ip_address must be dhcp or a valid IPv4 CIDR address."
  }
}

variable "gateway" {
  description = "IPv4 gateway for static addressing; leave null when using DHCP."
  type        = string
  default     = null
}

variable "username" {
  description = "Cloud-init administrative account created in the VM."
  type        = string
  default     = "ansible"
}

variable "ssh_public_keys" {
  description = "SSH public keys installed for the cloud-init account."
  type        = list(string)

  validation {
    condition     = length(var.ssh_public_keys) > 0
    error_message = "At least one SSH public key must be provided."
  }
}

variable "bridge" {
  description = "Proxmox network bridge attached to the VM."
  type        = string
  default     = "vmbr0"
}

variable "mac_address" {
  description = "Deterministic MAC address assigned to the VM."
  type        = string

  validation {
    condition     = can(regex("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", var.mac_address))
    error_message = "mac_address must use six colon-separated hexadecimal octets."
  }
}

variable "startup_order" {
  description = "Proxmox automatic-start order; lower values start first and stop last."
  type        = number
  default     = 0

  validation {
    condition     = var.startup_order >= 0 && var.startup_order == floor(var.startup_order)
    error_message = "startup_order must be a non-negative whole number."
  }
}

variable "startup_up_delay" {
  description = "Seconds to wait after starting this VM before starting the next VM."
  type        = number
  default     = 0

  validation {
    condition     = var.startup_up_delay >= 0 && var.startup_up_delay == floor(var.startup_up_delay)
    error_message = "startup_up_delay must be a non-negative whole number."
  }
}

variable "startup_down_delay" {
  description = "Seconds to wait after stopping this VM before stopping the next VM."
  type        = number
  default     = 0

  validation {
    condition     = var.startup_down_delay >= 0 && var.startup_down_delay == floor(var.startup_down_delay)
    error_message = "startup_down_delay must be a non-negative whole number."
  }
}
