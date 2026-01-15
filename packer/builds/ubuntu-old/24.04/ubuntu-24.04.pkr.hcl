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

  // url maps for remote iso files
  ubuntu_iso_urls = {
    "25.10" = "https://releases.ubuntu.com/releases/questing/ubuntu-25.10-live-server-amd64.iso"
    "24.04" = "https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso"
    "22.04" = "https://releases.ubuntu.com/jammy/ubuntu-22.04.6-live-server-amd64.iso"
  }

  ubuntu_iso_checksums = {
    "25.10" = "https://releases.ubuntu.com/25.10/SHA256SUM"
    "24.04" = "https://releases.ubuntu.com/noble/SHA256SUMS"
    "22.04" = "https://releases.ubuntu.com/jammy/SHA256SUMS"
  }

  common_packages = [
    "cloud-init",
    "qemu-guest-agent"
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
  template_name        = "ubuntu-${var.ubuntu_version}-lts-${local.version}"
  template_description = "Ubuntu ${var.ubuntu_version} LTS\nVersion:${local.version}\nbuilt on ${local.build_date}"

  vm_name = "packer-ubuntu-${replace(var.ubuntu_version, ".", "-")}"

  iso_file = "${var.common_iso_storage}:iso/${var.iso_file_name}"

  // manifest output path
  manifest_date   = formatdate("YYYYMMDDhhmmss", timestamp())
  manifest_path   = "${abspath(path.cwd)}/packer-manifests/"
  manifest_output = "${local.manifest_path}${local.manifest_date}.json"
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
  # ssh_private_key_file = "${var.build_private_key_file}"
  ssh_timeout = "15m"

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
      // Identity info
      build_username           = "${var.build_username}"
      build_key                = "${var.build_key}"
      build_password_encrypted = "${var.build_password_encrypted}"

      // User info
      ansible_username       = "${var.ansible_username}"
      ansible_ssh_public_key = "${var.ansible_ssh_public_key}"
    })
  }

  // Boot and Provisioning Settings
  // http_directory = "http"
  boot_wait = "10s"
  boot      = "order=virtio0;ide2;net0"
  boot_command = [
    "c<wait5>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}'",
    "<enter><wait10>",
    "initrd /casper/initrd",
    "<enter><wait10>",
    "boot",
    "<enter>"
  ]

  boot_iso {
    iso_file     = "${var.common_iso_storage}:iso/ubuntu-24.04.3-live-server-amd64.iso"
    unmount      = true
    iso_checksum = "https://releases.ubuntu.com/noble/SHA256SUMS"
  }

  template_name        = "${local.template_name}"
  template_description = "${local.template_description}"

  //  VM Cloud Init Settings
  cloud_init              = true
  cloud_init_storage_pool = "${var.common_cloud_init_storage}"
}

// Provisioner Settings
build {
  sources = ["source.proxmox-iso.ubuntu"]

  provisioner "ansible" {
    user             = "${var.ansible_username}"
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
      "--extra-vars", "ansible_key='${var.ansible_ssh_public_key}'",
      "--extra-vars", "cloudinit=true"
    ]
  }

  post-processor "manifest" {
    output     = local.manifest_output
    strip_path = true
    strip_time = true
    custom_data = {
      ansible_username = "${var.ansible_username}"
      build_username   = "${var.build_username}"
      build_date       = "${local.build_date}"
      build_version    = "${local.version}"
    }
  }
}