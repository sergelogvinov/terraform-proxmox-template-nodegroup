# Terraform module for Proxmox VE

This Terraform module allows you to create and manage a group of virtual machines (VMs) in Proxmox VE using a single predefined template.

## Overview

The concept is similar to node groups in well-known cloud providers.
You define one VM template and one cloud-init configuration that are shared by all VMs in the group.

You can specify:
* The number of VMs to create
* Their common CPU, memory, and storage resources
* Their network configuration

To scale your infrastructure up or down, you only need to change the number of VMs.

The module also supports VM optimizations such as `CPU affinity`, `hugepages`, and `NUMA` topology awareness.
You just need to provide the CPU architecture of the Proxmox node (node_numa_architecture) where the VMs will be created.

The optimization logic follows the same approach used in [Karpenter for Proxmox](https://github.com/sergelogvinov/karpenter-provider-proxmox),
but is designed for static environments, where VMs are managed declaratively and remain fully under your control.

## IP Addressing

The module can provide IPv4 and IPv6 addressing for the VMs using index-based addressing.
You need to provide network configuration in the following way:

```hcl
  network_dns = ["1.1.1.1", "2001:4860:4860::8888"]
  network = {
    "vmbr0" = {
      mtu = 1400

      # If you need to enable firewall for the VM network interface, firewall_groups should be existed on the Proxmox cluster
      firewall        = true,
      firewall_groups = "kubernetes",

      ip6       = ""
      ip6subnet = cidrsubnet("fd60:172:16::/64", 16, index(local.zones, each.key))
      ip6mask   = 64
      ip6index  = 384 + lookup(try(var.instances[each.key], {}), "worker_id", 9000)
      gw6       = "fe80::1"

      ip4       = ""
      ip4subnet = "172.16.0.128/28"
      ip4mask   = 24
      ip4index  = 7
      gw4       = cidrhost(local.subnets[each.key], 0)
    }
  }
```

network - is a map of network interfaces where each interface can have its own configuration.
You can specify ip6 and ip4 as empty strings to enable index-based addressing.

* `ip6subnet` and `ip4subnet` - are the subnets from which IP addresses will be allocated.
* `ip6index` and `ip4index` - are the indexes used to calculate the final IP address based on the worker ID or other unique identifier.
* `ip6mask` and `ip4mask` - are the final subnet masks for the allocated IP addresses.
* `gw4`, `gw6` - are the gateway address for IPv4 and IPv6 respectively.

The IP address will alloceted from `ip4subnet` (172.16.0.128/28) + `ip4index` (7) = 172.16.0.135, for example. Next VM with index 8 will get 172.16.0.136.
The finel IP address will be `172.16.0.135/24` based on `ip4mask` value.

## Usage Example

```hcl
variable "instances" {
  description = "Map of VMs launched on proxmox hosts"
  type        = map(any)
  default = {
    "hvm-1" = {
      enabled         = true,

      worker_id       = 11030,
      worker_count    = 2,
      worker_cpu      = 4,
      worker_mem      = 4 * 2 * 1024,
    },
  }
}

locals {
  zones   = [for k, v in var.instances : k]
  subnets = { for inx, zone in local.zones : zone => cidrsubnet("172.16.0.0/24", 4, 8 + inx - 1) }
}

module "proxmox_nodegroup" {
  source = "github.com/sergelogvinov/terraform-proxmox-template-nodegroup"

  vms         = lookup(try(var.instances[each.key], {}), "worker_count", 0)
  id          = lookup(try(var.instances[each.key], {}), "worker_id", 9000)
  name        = "worker-${format("%02d", index(local.zones, each.key))}"
  description = "Worker node managed by Terraform"
  cpus        = lookup(try(var.instances[each.key], {}), "worker_cpu", 1)
  memory      = lookup(try(var.instances[each.key], {}), "worker_mem", 2048)
  tags        = ["kubernetes", "worker"]

  # If you need to enable hugepages for the VM or speed up your VM performance
  # you can set hugepages to some value like 1024 or 2
  hugepages   = 1024

  # If your need to pin VM vCPU to specific CPU cores on the Proxmox host
  # you need to provide CPU architecture of the Proxmox host node
  # use command on the host machine - lscpu | grep NUMA
  node_numa_architecture = ["0-3,16-19", "4-7,20-23", "8-11,24-27", "12-15,28-31"]

  template_id = var.template_id

  # Size of the boot disk in GB
  boot_size      = 64
  boot_datastore = lookup(try(var.nodes[each.key], {}), "storage", "local")

  network_dns = ["1.1.1.1", "2001:4860:4860::8888"]
  network = {
    "vmbr0" = {
      mtu       = 1400
      ip6       = ""
      ip6subnet = cidrsubnet("fd60:172:16::/64", 16, index(local.zones, each.key))
      ip6mask   = 64
      ip6index  = 384 + lookup(try(var.instances[each.key], {}), "worker_id", 9000)

      ip4       = ""
      ip4subnet = 172.16.0.0/24
      ip4mask   = 24
      ip4index  = 7
      gw4       = cidrhost(local.subnets[each.key], 0)
    }
  }
}
```

How the module optimizes VMs you can read on articles:
* https://dev.to/sergelogvinov/proxmox-cpu-affinity-for-vms-4dhb
* https://dev.to/sergelogvinov/proxmox-hugepages-for-vms-1fh3

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.83.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >= 0.83.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_affinity"></a> [affinity](#module\_affinity) | github.com/sergelogvinov/terraform-proxmox-cpuaffinity | n/a |

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_file.metadata](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.userdata](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_firewall_options.instances](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_options) | resource |
| [proxmox_virtual_environment_firewall_rules.instances](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_rules) | resource |
| [proxmox_virtual_environment_vm.instances](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bios"></a> [bios](#input\_bios) | BIOS type for the VM | `string` | `"ovmf"` | no |
| <a name="input_boot_datastore"></a> [boot\_datastore](#input\_boot\_datastore) | Datastore for the VM | `string` | `"local"` | no |
| <a name="input_boot_size"></a> [boot\_size](#input\_boot\_size) | Size of the boot disk in GB | `number` | `32` | no |
| <a name="input_cloudinit_datastore"></a> [cloudinit\_datastore](#input\_cloudinit\_datastore) | Datastore for the userdata file | `string` | `"local"` | no |
| <a name="input_cloudinit_region"></a> [cloudinit\_region](#input\_cloudinit\_region) | Region for the metadata file | `string` | `""` | no |
| <a name="input_cloudinit_userdata"></a> [cloudinit\_userdata](#input\_cloudinit\_userdata) | Userdata for cloud-init image | `string` | `""` | no |
| <a name="input_cloudinit_userdata_id"></a> [cloudinit\_userdata\_id](#input\_cloudinit\_userdata\_id) | Userdata file ID for cloud-init image | `string` | `""` | no |
| <a name="input_cloudinit_zone"></a> [cloudinit\_zone](#input\_cloudinit\_zone) | Zone for the metadata file | `string` | `""` | no |
| <a name="input_cpu_flags"></a> [cpu\_flags](#input\_cpu\_flags) | CPU flags for the VM | `list(string)` | `[]` | no |
| <a name="input_cpus"></a> [cpus](#input\_cpus) | CPUs for the VM | `number` | `2` | no |
| <a name="input_description"></a> [description](#input\_description) | Description | `string` | `""` | no |
| <a name="input_hugepages"></a> [hugepages](#input\_hugepages) | Whether to enable hugepages for the VM | `string` | `""` | no |
| <a name="input_id"></a> [id](#input\_id) | Start number of ID for the VM | `number` | `1000` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory size in MB | `number` | `2048` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the VM | `string` | `"group-1"` | no |
| <a name="input_network"></a> [network](#input\_network) | n/a | `map(any)` | `{}` | no |
| <a name="input_network_dns"></a> [network\_dns](#input\_network\_dns) | n/a | `list(string)` | `[]` | no |
| <a name="input_node"></a> [node](#input\_node) | Proxmox node name where VM template will be created | `string` | `"node-name"` | no |
| <a name="input_node_numa_architecture"></a> [node\_numa\_architecture](#input\_node\_numa\_architecture) | Proxmox node CPU architecture of the hypervisor node | `list(string)` | `[]` | no |
| <a name="input_node_numa_shift"></a> [node\_numa\_shift](#input\_node\_numa\_shift) | Proxmox node numa shift mapping of the hypervisor node | `number` | `0` | no |
| <a name="input_pool"></a> [pool](#input\_pool) | Name of the VM pool | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to the VM | `list(string)` | `[]` | no |
| <a name="input_template_id"></a> [template\_id](#input\_template\_id) | ID of the template VM | `number` | `1` | no |
| <a name="input_tpm"></a> [tpm](#input\_tpm) | Whether to enable TPM for the VM | `bool` | `false` | no |
| <a name="input_vms"></a> [vms](#input\_vms) | Amount of VMs to create | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instances"></a> [instances](#output\_instances) | ID of the VM |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags of the VM |
<!-- END_TF_DOCS -->