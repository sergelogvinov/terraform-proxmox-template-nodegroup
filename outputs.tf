
output "instances" {
  description = "ID of the VM"
  value       = proxmox_virtual_environment_vm.instances
}

output "tags" {
  description = "Tags of the VM"
  value       = var.tags
}
