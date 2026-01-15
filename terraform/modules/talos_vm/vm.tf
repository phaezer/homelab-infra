resource "proxmox_virtual_environment_vm" "this" {
  node_name = var.proxmox_node

  name        = var.vm_name
  description = "Talos Kubernetes ${var.node_type}. Managed by Terraform"
  tags        = ["talos", var.node_type, "kubernetes", "terraform"]
  on_boot     = true
  vm_id       = var.vm_id

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
    floating  = var.memory_mb # Disable ballooning for k8s
  }

  disk {
    datastore_id = var.vm_datastore

    file_id     = proxmox_virtual_environment_download_file.this.id
    file_format = "raw"

    interface = "virtio0"
    iothread  = true
    cache     = "writethrough"
    discard   = "on"
    size      = var.disk_size_gb
  }

  # Management network interface
  network_device {
    bridge      = var.mgmt_network.bridge
    vlan_id     = var.mgmt_network.vlan
    mac_address = var.mgmt_network.mac
    model       = "virtio"
    mtu         = var.mgmt_network.mtu
  }

  # Ceph network interface
  network_device {
    bridge      = var.ceph_network.bridge
    vlan_id     = var.ceph_network.vlan
    mac_address = var.ceph_network.mac
    model       = "virtio"
    mtu         = var.ceph_network.mtu
  }

  # boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  serial_device {
    device = "socket"
  }

  # PCIe passthrough devices
  dynamic "hostpci" {
    for_each = var.pcie_passthrough != null ? toset(var.pcie_passthrough) : []
    content {
      device   = each.key
      id       = each.value.id
      mapping  = each.value.mapping
      mdev     = each.value.mdev
      rombar   = each.value.rombar
      rom_file = each.value.rom_file
      xvga     = each.value.xvga
    }
  }

  # TODO: cloud-init with cloud-init template file for both interfaces
  initialization {
    datastore_id = var.cloud_init_datastore
    # user_data_file_id      = proxmox_virtual_environment_file.this.id
    network_data_file_id = proxmox_virtual_environment_file.network_data.id
  }

  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_file.network_data,
      # proxmox_virtual_environment_file.meta_config
      # proxmox_virtual_environment_download_file.this
    ]
  }
}

# resource "proxmox_virtual_environment_file" "user_data" {
#   content_type = "snippets"
#   node_name    = var.proxmox_node
#   datastore_id = "local"
#   # file_mode    = "0700"

#   source_raw {
#     data =

#     file_name = "${var.vm_name}-user-data.yml"
#   }
# }


resource "proxmox_virtual_environment_file" "network_data" {
  content_type = "snippets"
  node_name    = var.proxmox_node
  datastore_id = "local"
  # file_mode    = "0700"

  source_raw {
    data = jsonencode({
      version : 1
      config : [
        {
          type : "physical"
          name : "mgmt"
          mac_address : var.mgmt_network.mac
          mtu : var.mgmt_network.mtu
          subnets : [
            {
              type : "static"
              address : var.mgmt_network.address
              dns_servers : var.nameservers
              gateway : var.mgmt_network.gateway
            }
          ]
        },
        {
          type : "physical"
          name : "ceph"
          mac_address : var.ceph_network.mac
          mtu : var.ceph_network.mtu
          subnets : [
            {
              type : "static"
              address : var.ceph_network.address
            }
          ]
        }
      ]
    })

    file_name = "${var.vm_name}-network-data.yml"
  }
}



# resource "proxmox_virtual_environment_file" "meta_config" {
#   content_type = "snippets"
#   node_name    = var.proxmox_node
#   datastore_id = "local"
#   # file_mode    = "0700"

#   source_raw {
#     data = yamlencode({
#       hostname : var.hostname
#       "local-hostname" : var.vm_name
#     })

#     file_name = "${var.vm_name}-meta-config.yml"
#   }
# }
