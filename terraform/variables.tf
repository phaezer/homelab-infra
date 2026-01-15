# Proxmox Configuration
variable "proxmox_api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  sensitive   = true
}

# Talos Configuration
variable "talos_version" {
  description = "Talos OS version to install"
  type        = string
}

variable "talos_factory_url" {
  description = "The Talos factory URL to download images and schematics"
  type        = string
  default     = "https://factory.talos.dev"

  validation {
    condition     = can(regex("^https?://", var.talos_factory_url))
    error_message = "talos_factory_url must be a valid URL starting with http:// or https://"
  }
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
}

variable "calico_version" {
  description = "Calico version to install"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "talos-cluster"
}

variable "cluster_endpoint" {
  description = "The Kubernetes API server endpoint hostname or IP"
  type        = string
  default     = null

  validation {
    condition     = var.cluster_endpoint == null || can(regex("^https?://", var.cluster_endpoint))
    error_message = "cluster_endpoint must be a valid URL starting with http:// or https://"
  }
}

# Networking Configuration
variable "nameservers" {
  description = "List of DNS nameservers"
  type        = list(string)
}

variable "svc_subnet_cidrs" {
  description = "Kubernetes Service CIDR"
  type        = list(string)

  validation {
    condition     = length(var.svc_subnet_cidrs) > 0
    error_message = "svc_subnet_cidrs list must not be empty"
  }
}

variable "pod_subnet_cidrs" {
  description = "Pod Subnet CIDRs"
  type        = list(string)

  validation {
    condition     = length(var.pod_subnet_cidrs) > 0
    error_message = "pod_subnet_cidrs list must not be empty"
  }
}

variable "ceph_bridge" {
  description = "Bridge for Ceph network"
  type        = string
}

variable "ceph_subnet_cidr" {
  description = "Ceph Subnet CIDR"
  type        = string

  validation {
    condition     = can(cidrhost(var.ceph_subnet_cidr, 1))
    error_message = "ceph_subnet_cidr must be a valid CIDR notation"
  }
}

variable "mgmt_subnet_cidr" {
  description = "Management Subnet CIDR"
  type        = string

  validation {
    condition     = can(cidrhost(var.mgmt_subnet_cidr, 1))
    error_message = "mgmt_subnet_cidr must be a valid CIDR notation"
  }
}

variable "mgmt_vip_ip" {
  description = "Virtual IP address for the control plane"
  type        = string
}

variable "mgmt_gateway_ip" {
  description = "Gateway IP for the management subnet"
  type        = string
}

variable "mgmt_bridge" {
  description = "Proxmox bridge for management network"
  type        = string
}

variable "mgmt_mtu" {
  description = "MTU for management network"
  type        = number
  default     = 1500
}

variable "ceph_mtu" {
  description = "MTU for Ceph network"
  type        = number
  default     = 9000
}

variable "iso_datastore" {
  description = "The datastore where ISO images are stored"
  type        = string
}

variable "vm_datastore" {
  description = "The datastore where VM disks will be created"
  type        = string
}

variable "vm_timezone" {
  description = "Timezone to set inside the VMs"
  type        = string
  default     = "UTC"
}

variable "cloud_init_datastore" {
  description = "The datastore where cloud-init disks will be created"
  type        = string
}

variable "allow_scheduling_on_control_planes" {
  description = "Whether to allow scheduling workloads on control plane nodes"
  type        = bool
  default     = true
}

# TODO: add pcie passthrough object to node definitions
variable "control_plane_nodes" {
  description = "List of control plane node configurations"
  type = list(object({
    hostname     = string
    vm_id        = number
    proxmox_node = string
    mgmt_ip      = string
    ceph_ip      = string
    labels       = map(string)
    vm_cpu_cores = optional(number, 2)
    vm_memory_mb = optional(number, 2048)
  }))
}

variable "worker_nodes" {
  description = "List of control plane node configurations"
  type = list(object({
    hostname     = string
    vm_id        = number
    proxmox_node = string
    mgmt_ip      = string
    ceph_ip      = string
    labels       = map(string)
    vm_cpu_cores = optional(number, 2)
    vm_memory_mb = optional(number, 4096)
  }))
  default = []
}

locals {
  mgmt_net_prefix = parseint(regex("/(\\d+)$", var.mgmt_subnet_cidr)[0], 10)
  ceph_net_prefix = parseint(regex("/(\\d+)$", var.ceph_subnet_cidr)[0], 10)

  talos_templates_path = "${path.module}/../talos/templates"

  cluster_endpoint = var.cluster_endpoint != null ? var.cluster_endpoint : "https://${var.mgmt_vip_ip}:6443"

  nodes = {
    for node in concat(var.control_plane_nodes, var.worker_nodes) :
    node.vm_id => merge(node, {
      machine_type = contains(var.control_plane_nodes, node) ? "controlplane" : "worker"
      mgmt_address = "${node.mgmt_ip}/${local.mgmt_net_prefix}"
      ceph_address = "${node.ceph_ip}/${local.ceph_net_prefix}"
    })
  }

  bootstrap_node = var.control_plane_nodes[0].mgmt_ip
}

