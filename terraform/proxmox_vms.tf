# controlplane vms
module "talos_vm" {
  for_each = local.nodes

  source = "./modules/talos_vm"

  proxmox_node = each.value.proxmox_node

  talos_version     = var.talos_version
  talos_factory_url = var.talos_factory_url
  talos_schematic   = file("${path.module}/../talos/schematic.yaml")

  node_type = each.value.machine_type

  iso_datastore        = var.iso_datastore
  vm_datastore         = var.vm_datastore
  cloud_init_datastore = var.cloud_init_datastore

  vm_id   = each.value.vm_id
  vm_name = "${var.cluster_name}-${each.value.machine_type}-${each.value.vm_id}"

  cpu_cores = each.value.vm_cpu_cores
  memory_mb = each.value.vm_memory_mb

  hostname    = each.value.hostname
  timezone    = var.vm_timezone
  nameservers = var.nameservers

  mgmt_network = {
    bridge  = var.mgmt_bridge
    address = each.value.mgmt_address
    mac     = macaddress.mgmt[each.key].address
    gateway = var.mgmt_gateway_ip
    mtu     = var.mgmt_mtu
  }

  ceph_network = {
    bridge  = var.ceph_bridge
    address = each.value.ceph_address
    mac     = macaddress.ceph[each.key].address
  }
}
