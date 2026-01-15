packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}


locals {
  // OS and Template Versioning
  version    = "v0.0.1"
  build_date = formatdate("DD-MM-YYYY hh:mm ZZZ", "${timestamp()}")

  ubuntu_files = {
    "25.10" = "ubuntu-25.10-live-server-amd64.iso"
    "24.04" = "ubuntu-24.04.3-live-server-amd64.iso"
    "22.04" = "ubuntu-22.04.6-live-server-amd64.iso"
  }

  // url maps for remote iso files
  ubuntu_iso_urls = {
    "25.10" = "https://releases.ubuntu.com/releases/questing/ubuntu-25.10-live-server-amd64.iso"
    "24.04" = "https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso"
    "22.04" = "https://releases.ubuntu.com/jammy/ubuntu-22.04.6-live-server-amd64.iso"
  }

  ubuntu_iso_checksums = {
    "25.10" = "file:https://releases.ubuntu.com/25.10/SHA256SUM"
    "24.04" = "file:https://releases.ubuntu.com/noble/SHA256SUMS"
    "22.04" = "file:https://releases.ubuntu.com/jammy/SHA256SUMS"
  }

  common_packages = [
    "cloud-init",
    "openssh-server"
  ]

  additional_packages = {
    "25.10" = []
    "24.04" = ["qemu-guest-agent"]
    "22.04" = ["qemu-guest-agent"]
  }

  packages = concat(
    local.common_packages,
    lookup(local.additional_packages, var.ubuntu_version, [])
  )

  // Derived Variables
  template_name        = "ubuntu-packer-${var.ubuntu_version}-${local.version}"
  template_description = "Ubuntu ${var.ubuntu_version} \nTemplate Version:${local.version}\nbuilt on ${local.build_date}"
  vm_name              = "packer-build-ubuntu-${replace(var.ubuntu_version, ".", "-")}"

  iso_filename = lookup(local.ubuntu_files, var.ubuntu_version, "")
  iso_file     = var.download_iso == false ? "${var.common_iso_storage}:iso/${local.iso_filename}" : null
  iso_url      = var.download_iso ? lookup(local.ubuntu_iso_urls, var.ubuntu_version, "") : null
  iso_checksum = lookup(local.ubuntu_iso_checksums, var.ubuntu_version, "")

  autoinstall = contains(["25.10"], var.ubuntu_version) ? "ds='nocloud;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}'" : "ds='nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}'"

  // manifest output path
  manifest_date   = formatdate("YYYYMMDDhhmmss", timestamp())
  manifest_path   = "${abspath(path.cwd)}/packer/manifests/"
  manifest_output = "${local.manifest_path}${local.template_name}${local.manifest_date}.json"
}

source "proxmox-iso" "ubuntu" {
  // Proxmox Connection Settings and Credentials
  proxmox_url              = "https://${var.proxmox_hostname}:8006/api2/json"
  username                 = "${var.proxmox_user}"
  password                 = "${var.proxmox_password}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = false

  // Proxmox Settings
  node = "${var.proxmox_node}"

  // Virtual Machine Settings
  vm_name         = "${local.vm_name}"
  bios            = "seabios"
  sockets         = 1
  cores           = "${var.vm_cores}"
  cpu_type        = "host"
  memory          = "${var.vm_memory}"
  os              = "l26"
  scsi_controller = "virtio-scsi-pci"

  disks {
    type         = "virtio"
    disk_size    = "32G"
    storage_pool = "${var.vm_storage_pool}"
    format       = "raw"
  }

  ssh_username = "${var.build_username}"
  ssh_password = "${var.build_password}"
  ssh_timeout  = "20m"

  qemu_agent = true

  network_adapters {
    bridge = "${var.vm_bridge_interface}"
    model  = "virtio"
    mtu    = 1500
  }

  // Removable Media Settings
  http_content = {
    "/meta-data" = file("${abspath(path.root)}/data/meta-data")
    "/user-data" = templatefile("${abspath(path.root)}/data/user-data.pkrtpl.hcl", {
      // Timezone
      timezone = "${var.vm_timezone}"
      locale   = "${var.vm_locale}"
      keyboard = "${var.vm_keyboard}"
      // Identity info
      build_username           = "${var.build_username}"
      build_key                = "${var.build_key}"
      build_password_encrypted = "${var.build_password_encrypted}"
      // packages
      packages = "${local.packages}"
      // User info
      # ansible_username       = "${var.ansible_username}"
      # ansible_ssh_public_key = "${var.ansible_ssh_public_key}"
    })
  }

  // Boot and Provisioning Settings
  // http_directory = "http"
  boot_wait = "10s"
  boot      = "order=virtio0;ide2;net0"
  boot_command = [
    "c<wait5>",
    "linux /casper/vmlinuz --- autoinstall ${local.autoinstall}",
    "<enter><wait10>",
    "initrd /casper/initrd",
    "<enter><wait10>",
    "boot",
    "<enter>"
  ]

  boot_iso {
    iso_file         = local.iso_file
    iso_url          = local.iso_url
    iso_storage_pool = local.iso_file == null ? var.common_iso_storage : null
    unmount          = true
    iso_checksum     = local.iso_checksum
  }

  template_name           = local.template_name
  template_description    = local.template_description
  cloud_init              = true
  cloud_init_storage_pool = var.common_cloud_init_storage
}

// Provisioner Settings
build {
  name    = "release"
  sources = ["source.proxmox-iso.ubuntu"]

  provisioner "ansible" {
    user             = "${var.build_username}"
    playbook_file    = "${path.cwd}/ansible/${var.ansible_playbook_file}"
    galaxy_file      = "${path.cwd}/ansible/collections/requirements.yml"
    collections_path = "${path.cwd}/ansible/collections"
    roles_path       = "${path.cwd}/ansible/roles"
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.cwd}/ansible/ansible.cfg",
    ]
    extra_arguments = [
      # prevents "Failed to create tmp directory" errors
      "--extra-vars", "ansible_remote_temp='/tmp'",
      "--extra-vars", "ansible_sudo_pass='${var.build_password}'",
      "--extra-vars", "ansible_key='${var.build_key}'",
      "--extra-vars", "cloudinit=true"
    ]
  }

  # post-processor "manifest" {
  #   output     = local.manifest_output
  #   strip_path = true
  #   strip_time = true
  #   custom_data = {
  #     ansible_username = "${var.ansible_username}"
  #     build_username   = "${var.build_username}"
  #     build_date       = "${local.build_date}"
  #     build_version    = "${local.version}"
  #   }
  # }
}