
resource "proxmox_virtual_environment_firewall_options" "instances" {
  for_each = local.instances

  node_name = var.node
  vm_id     = each.value.id
  enabled   = length(each.value.firewall) > 0

  dhcp          = false
  ipfilter      = false
  log_level_in  = "nolog"
  log_level_out = "nolog"
  macfilter     = false
  ndp           = true
  input_policy  = "DROP"
  output_policy = "ACCEPT"
  radv          = false

  depends_on = [proxmox_virtual_environment_vm.instances]
}

resource "proxmox_virtual_environment_firewall_rules" "instances" {
  for_each = { for k in flatten([
    for i, v in local.instances : [
      for net, group in v.firewall : {
        id    = v.id
        name  = "${i}-${net}"
        group = group
      } if group != ""
    ]
  ]) : k.name => k }

  node_name = var.node
  vm_id     = each.value.id

  dynamic "rule" {
    for_each = split(",", each.value.group)
    content {
      enabled        = true
      security_group = each.value.group
    }
  }

  depends_on = [proxmox_virtual_environment_vm.instances, proxmox_virtual_environment_firewall_options.instances]
}
