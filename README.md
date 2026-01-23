# Terraform module for Proxmox VE

This Terraform module allows you to create a group of virtual machines (VMs) in Proxmox VE using a specified template.

## Usage Example

```hcl
module "proxmox_nodegroup" {
  source = "github.com/sergelogvinov/terraform-proxmox-template-nodegroup"

  vms         = 2
  id          = 1000
  name        = "worker-node"
  node        = "node-name"
  description = "Worker nodes for node-name zone"
  cpus        = 4
  memory      = 4*1024
  tags        = ["kubernetes", "worker"]

  template_id = var.template_id

  # boot_size      = 64
  boot_datastore = lookup(try(var.nodes[each.key], {}), "storage", "local")

  network_dns = ["1.1.1.1", "2001:4860:4860::8888"]
  network = {
    "vmbr0" = {
      firewall        = true
      firewall_groups = "kubernetes"
      ip6             = "auto"
      ip4             = "dhcp"
    }
  }
}
```

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
| <a name="input_node_numa_shuft"></a> [node\_numa\_shuft](#input\_node\_numa\_shuft) | Proxmox node numa shuft mapping of the hypervisor node | `number` | `0` | no |
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