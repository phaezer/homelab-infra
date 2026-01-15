# talos module variables
variable "proxmox_node" {
  description = "The Proxmox node where the VM will be created"
  type        = string
}

variable "talos_factory_url" {
  description = "The Talos factory URL to download images and schematics"
  type        = string
  default     = "https://factory.talos.dev"
}

variable "talos_version" {
  description = "The Talos version to use for the VM"
  type        = string
  default     = "v1.4.5"
}

variable "talos_schematic" {
  description = "The Talos schematic to use for the VM"
  type        = string
}

variable "node_type" {
  description = "The type of node: controlplane or worker"
  type        = string

  validation {
    condition     = contains(["controlplane", "worker"], var.node_type)
    error_message = "node_type must be 'controlplane' or 'worker'"
  }
}

variable "iso_datastore" {
  description = "The datastore where ISO files are stored"
  type        = string
}

variable "cloud_init_datastore" {
  description = "The datastore where cloud-init disks will be created"
  type        = string
}

variable "vm_datastore" {
  description = "The datastore where VM disks will be created"
  type        = string
}

variable "vm_id" {
  description = "the VM id"
  type        = number
}

variable "vm_name" {
  description = "The name of the VM"
  type        = string
}

variable "cpu_cores" {
  description = "Number of CPU cores for the VM"
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "The CPU type for the VM"
  type        = string
  default     = "host"
}

variable "disk_size_gb" {
  description = "Size of the VM disk in GB"
  type        = number
  default     = 50
}

variable "memory_mb" {
  description = "Amount of memory (in MB) for the VM"
  type        = number
  default     = 2048
}

variable "hostname" {
  description = "The hostname to set inside the VM"
  type        = string
}

variable "nameservers" {
  description = "List of nameserver IP addresses for the VM"
  type        = list(string)
  default     = []

  validation {
    condition = length(var.nameservers) > 0
    error_message = "At least one nameserver must be provided"
  }
}

variable "timezone" {
  description = "The timezone to set inside the VM"
  type        = string
  default     = "UTC"
}

variable "mgmt_network" {
  description = "Management network configuration"
  type = object({
    bridge  = string
    address = string
    vlan    = optional(number, null)
    mac     = string
    gateway = string
    mtu     = optional(number, 1500)
  })
}

variable "ceph_network" {
  description = "Ceph network configuration"
  type = object({
    bridge  = string
    address = string
    vlan    = optional(number, null)
    mac     = string
    mtu     = optional(number, 9000)
  })
}
# variable "ceph_network" {
#   description = "Ceph network configuration"
#   type = object({
#     bridge = string
#     vlan   = optional(number, null)
#     mac    = string
#     mtu    = optional(number, 9000)
#   })
# }

variable "pcie_passthrough" {
  description = "PCIe devices to passthrough to the VM"
  type = set(object({
    id       = optional(string, null)
    mapping  = optional(string, null)
    mdev     = optional(string, null)
    pcie     = optional(bool, true)
    rombar   = optional(bool, true)
    rom_file = optional(string, null)
    xvga     = optional(bool, false)
  }))
  default = null
}
