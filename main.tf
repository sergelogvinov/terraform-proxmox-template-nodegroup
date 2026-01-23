
locals {
  instances = { for i in flatten([
    for inx in range(var.vms) : {
      inx : inx
      id : var.id + inx
      name : "${var.name}${format("%x", 10 + inx)}"
      firewall : {
        for k, v in var.network : k => lookup(v, "firewall_groups", "") if lookup(v, "firewall", false)
      }
    }
    ]
  ) : i.name => i }

  affinity = length(var.node_numa_architecture) > 0
}

module "affinity" {
  count  = local.affinity ? 1 : 0
  source = "github.com/sergelogvinov/terraform-proxmox-cpuaffinity"

  cpu_affinity = var.node_numa_architecture
  vms          = var.vms
  cpus         = var.cpus
}

resource "proxmox_virtual_environment_vm" "instances" {
  for_each = local.instances

  name      = each.value.name
  vm_id     = each.value.id
  node_name = var.node

  pool_id             = var.pool
  reboot              = false
  reboot_after_update = false
  description         = var.description

  bios = var.bios
  dynamic "efi_disk" {
    for_each = var.bios == "ovmf" ? [1] : []
    content {
      datastore_id = var.boot_datastore
      type         = "4m"
    }
  }
  smbios {
    serial = "h=${each.value.name};i=${each.value.id}"
  }

  cpu {
    cores    = var.cpus
    affinity = local.affinity ? join(",", module.affinity[0].arch[each.value.inx].cpus) : null
    sockets  = 1
    numa     = true
    type     = "host"
    flags    = sort(flatten([var.cpu_flags, var.hugepages == "1024" ? ["+pdpe1gb"] : []]))
  }
  memory {
    dedicated = var.memory
    floating  = 0
    hugepages = var.hugepages == "" ? null : var.hugepages
    # Kernel may not allocate memory if hugepages are released, so we keep them allocated
    # Better to allocate 1G hugepages on boot time, kernel cmdline: default_hugepagesz=1G hugepagesz=1G hugepages=xx
    keep_hugepages = var.hugepages == "1024" ? true : false
  }

  dynamic "numa" {
    for_each = local.affinity ? { for idx, numa in module.affinity[0].arch[each.value.inx].numa : idx => {
      device = "numa${index(keys(module.affinity[0].arch[each.value.inx].numa), idx)}"
      cpus   = "${index(keys(module.affinity[0].arch[each.value.inx].numa), idx) * (var.cpus / length(module.affinity[0].arch[each.value.inx].numa))}-${(index(keys(module.affinity[0].arch[each.value.inx].numa), idx) + 1) * (var.cpus / length(module.affinity[0].arch[each.value.inx].numa)) - 1}"
      mem    = var.memory / length(module.affinity[0].arch[each.value.inx].numa)
    } } : {}
    content {
      device    = numa.value.device
      cpus      = numa.value.cpus
      hostnodes = numa.key
      memory    = numa.value.mem
      policy    = "bind"
    }
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    datastore_id = var.boot_datastore
    interface    = "scsi0"
    backup       = false
    iothread     = true
    ssd          = true
    cache        = "none"
    size         = var.boot_size
    file_format  = "raw"
  }
  clone {
    vm_id = var.template_id
  }

  dynamic "network_device" {
    for_each = var.network
    content {
      bridge   = network_device.key
      firewall = lookup(network_device.value, "firewall", false)
      mtu      = lookup(network_device.value, "mtu", null)
      queues   = var.cpus
    }
  }

  initialization {
    dynamic "dns" {
      for_each = length(var.network_dns) > 0 ? [1] : []
      content {
        servers = var.network_dns
      }
    }

    dynamic "ip_config" {
      for_each = var.network
      content {
        dynamic "ipv4" {
          for_each = contains(keys(ip_config.value), "ip4") ? [1] : []
          content {
            address = lookup(ip_config.value, "ip4") == "" ? "${cidrhost(ip_config.value.ip4subnet, ip_config.value.ip4index + each.value.inx)}/${ip_config.value.ip4mask}" : ip_config.value.ip4
            gateway = lookup(ip_config.value, "gw4", null)
          }
        }
        dynamic "ipv6" {
          for_each = contains(keys(ip_config.value), "ip6") ? [1] : []
          content {
            address = lookup(ip_config.value, "ip6") == "" ? "${cidrhost(ip_config.value.ip6subnet, ip_config.value.ip6index + each.value.inx)}/${ip_config.value.ip6mask}" : ip_config.value.ip6
            gateway = lookup(ip_config.value, "gw6", null)
          }
        }
      }
    }

    datastore_id      = var.boot_datastore
    meta_data_file_id = proxmox_virtual_environment_file.metadata[each.key].id
    user_data_file_id = var.cloudinit_userdata != "" ? proxmox_virtual_environment_file.userdata[0].id : var.cloudinit_userdata_id
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
  vga {
    type = "serial0"
  }

  lifecycle {
    ignore_changes = [
      started,
      clone,
      ipv4_addresses,
      ipv6_addresses,
      network_interface_names,
      initialization,
      disk,
      cpu,
      memory,
      numa,
    ]
  }

  tags = var.tags
}

resource "proxmox_virtual_environment_file" "metadata" {
  for_each = local.instances

  node_name    = var.node
  content_type = "snippets"
  datastore_id = var.cloudinit_datastore

  source_raw {
    data = templatefile("${path.module}/templates/metadata.yaml", {
      hostname : each.value.name,
      id : each.value.id,
      providerID : "proxmox://${var.cloudinit_region}/${each.value.id}",
      type : "${var.cpus}VCPU-${floor(var.memory / 1024)}GB",
      zone : var.cloudinit_zone == "" ? var.node : var.cloudinit_zone,
      region : var.cloudinit_region,
    })
    file_name = "${each.value.name}.metadata.yaml"
  }
}

resource "proxmox_virtual_environment_file" "userdata" {
  count = var.cloudinit_userdata != "" ? 1 : 0

  node_name    = var.node
  content_type = "snippets"
  datastore_id = var.cloudinit_datastore

  source_raw {
    data      = var.cloudinit_userdata
    file_name = "${var.name}.userdata.yaml"
  }
}
