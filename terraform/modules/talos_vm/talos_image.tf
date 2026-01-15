# tofu/talos/image.tf
locals {
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]
}

data "http" "schematic_id" {
  url          = "${var.talos_factory_url}/schematics"
  method       = "POST"
  request_body = var.talos_schematic
}

resource "proxmox_virtual_environment_download_file" "this" {
  node_name    = var.proxmox_node
  content_type = "iso"
  datastore_id = var.iso_datastore

  file_name               = "talos-linux-${local.schematic_id}-${var.talos_version}-nocloud-amd64.img"
  url                     = "${var.talos_factory_url}/image/${local.schematic_id}/${var.talos_version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
