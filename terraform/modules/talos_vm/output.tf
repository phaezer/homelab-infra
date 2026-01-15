# Output the VM ID for reference
output "vm_id" {
  value = proxmox_virtual_environment_vm.this.vm_id
}

output "ipv4_mgmt_address" {
  value = var.mgmt_network.address
}
