# control plane node MAC addresses
resource "macaddress" "mgmt" {
  for_each = local.nodes
}

resource "macaddress" "ceph" {
  for_each = local.nodes
}
