/*
  Packer Template for Building Talos OS VM Templates on Proxmox
*/
packer {
  required_plugins {
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

  // Derived Variables
  template_name        = "talos-packer-${var.talos_version}-${local.version}"
  template_description = "Talos Linux ${var.talos_version} \nTemplate Version:${local.version}\nbuilt on ${local.build_date}"
  vm_name              = "packer-build-talos-${replace(var.talos_version, ".", "-")}"

  iso_file = "${var.common_iso_storage}:iso/${var.iso_filename}"

  // manifest output path
  manifest_date   = formatdate("YYYYMMDDhhmmss", timestamp())
  manifest_path   = "${abspath(path.cwd)}/packer-manifests/"
  manifest_output = "${local.manifest_path}${local.template_name}${local.manifest_date}.json"
}

source "proxmox-iso" "talos" {
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
    "/preseed.cfg" = templatefile("${abspath(path.root)}/data/preseed.pkrtpl.hcl", {
      // Timezone
      timezone = "${var.vm_timezone}"
      locale   = "${var.vm_locale}"
      keyboard = "${var.vm_keyboard}"
      // Identity info
      build_username           = "${var.build_username}"
      build_key                = "${var.build_key}"
      build_password_encrypted = "${var.build_password_encrypted}"
      // network
      network_device = "ens18"
      // disk
      # disk_device = "sda"
    })
  }

  // Boot and Provisioning Settings
  // http_directory = "http"
  boot_wait = "10s"
  boot      = "order=virtio0;ide2;net0"
  boot_command = [
    "<wait><wait><wait><esc><wait><wait><wait>",
    "/install.amd/vmlinuz ",
    "initrd=/install.amd/initrd.gz ",
    "auto=true ",
    "url=http://{{.HTTPIP}}:{{.HTTPPort}}/preseed.cfg ",
    "netcfg/get_hostname=debian netcfg/get_domain=example.com ",
    "interface=auto ",
    "vga=788 noprompt quiet --<enter>"
  ]

  boot_iso {
    iso_file = local.iso_file
    unmount  = true
  }

  template_name           = local.template_name
  template_description    = local.template_description
  cloud_init              = true
  cloud_init_storage_pool = var.common_cloud_init_storage
}

// Provisioner Settings
build {
  name    = "release"
  sources = ["source.proxmox-iso.talos"]

  provisioner "file" {
    source      = "${abspath(path.root)}/data/schematic.yaml"
    destination = "/tmp/schematic.yaml"
  }

  provisioner "shell" {
    inline = [
      "echo 'Requesting build image from Talos Factory'",
      "ID=$(curl -kLX POST --data-binary @/tmp/schematic.yaml https://factory.talos.dev/schematics | grep -o '\"id\":\"[^\"]*' | sed 's/\"id\":\"//')",
      "URL=https://pxe.factory.talos.dev/image/$ID/${var.talos_version}/nocloud-amd64.raw.xz",
      "echo 'Downloading build image from Talos Factory: ' + $URL",
      "curl -kL \"$URL\" -o /tmp/talos.raw.xz",
      "echo 'Writing build image to disk'",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/vda && sync",
      "echo 'Done'"
    ]
  }
}