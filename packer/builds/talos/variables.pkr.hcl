# Variables for Talos Packer Build

# Proxmox variables
variable "proxmox_node" {
  description = "the proxmox node name"
  type        = string
  default     = "pve1"
}

variable "proxmox_hostname" {
  description = "The proxmox node IP or hostname"
  type        = string
  default     = "pve1.dc0.plsr.io"
}

variable "proxmox_password" {
  description = "The Proxmox password for the API token user"
  type        = string
  sensitive   = true
  default     = null
}

variable "proxmox_user" {
  description = "The Proxmox API token"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "The Proxmox API token"
  type        = string
  sensitive   = true
  default     = null
}

# talos specific variables
variable "talos_version" {
  description = "The Talos version to install"
  type        = string
  default     = "v1.11.6"
}

variable "iso_filename" {
  description = "The Talos ISO file to use"
  type        = string
}

# vm resource variables
variable "vm_memory" {
  description = "The memory size to allocate to the VM in MB"
  type        = number
  default     = 512
}

variable "vm_cores" {
  description = "The number of CPU cores to allocate to the VM"
  type        = number
  default     = 1
}

variable "vm_storage_pool" {
  description = "The storage pool to use for the VM disk"
  type        = string
  default     = "local-lvm"
}

# vm configuration variables
variable "vm_timezone" {
  description = "The timezone to set on the VM"
  type        = string
  default     = "America/Chicago"
}

variable "vm_bridge_interface" {
  description = "The lan network bridge to use for the VM"
  type        = string
  default     = "vmbr0"
}

variable "vm_locale" {
  description = "The locale to set on the VM"
  type        = string
  default     = "en_US"
}

variable "vm_keyboard" {
  description = "The keyboard layout to set on the VM"
  type        = string
  default     = "us"
}

# variable "vm_boot" {
#   type        = string
#   description = "The boot order for virtual machine devices. (e.g. 'order=virtio0;ide2;net0')"
# }

# build ssh access variables
variable "build_username" {
  description = "The user to use for the packer build"
  type        = string
}

variable "build_password" {
  description = "The password to use for the packer build user"
  type        = string
}

variable "build_key" {
  description = "The ssh public key to use for the packer build user"
  type        = string
}

variable "build_password_encrypted" {
  description = "The encrypted password to use for the packer build user"
  type        = string
}

// Common variables
variable "common_cloud_init_storage" {
  description = "The storage pool to use for the cloud-init data"
  type        = string
  default     = "local-lvm"
}

// Common variables
variable "common_iso_storage" {
  description = "The storage pool to use for ISO files"
  type        = string
  default     = "local-lvm"
}