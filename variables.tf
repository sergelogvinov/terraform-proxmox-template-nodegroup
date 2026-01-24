
variable "node" {
  description = "Proxmox node name where VM template will be created"
  type        = string
  default     = "node-name"
}

variable "node_numa_architecture" {
  description = "Proxmox node CPU architecture of the hypervisor node"
  type        = list(string)
  default     = [] # ["0-3,16-19", "4-7,20-23", "8-11,24-27", "12-15,28-31"]
}

variable "node_numa_shift" {
  description = "Proxmox node numa shift mapping of the hypervisor node"
  type        = number
  default     = 0
}

variable "template_id" {
  description = "ID of the template VM"
  type        = number
  default     = 1
}

variable "vms" {
  description = "Amount of VMs to create"
  type        = number
  default     = 2
}

variable "id" {
  description = "Start number of ID for the VM"
  type        = number
  default     = 1000
}

variable "name" {
  description = "Name of the VM"
  type        = string
  default     = "group-1"
}

variable "description" {
  description = "Description"
  type        = string
  default     = ""
}

variable "pool" {
  description = "Name of the VM pool"
  type        = string
  default     = ""
}

variable "bios" {
  description = "BIOS type for the VM"
  type        = string
  default     = "ovmf"

  validation {
    condition     = contains(["ovmf", "seabios"], var.bios)
    error_message = "The bios must be one of 'ovmf' or 'seabios'."
  }
}

variable "tpm" {
  description = "Whether to enable TPM for the VM"
  type        = bool
  default     = false
}

variable "cpus" {
  description = "CPUs for the VM"
  type        = number
  default     = 2
}

variable "cpu_flags" {
  description = "CPU flags for the VM"
  type        = list(string)
  default     = []
}

variable "memory" {
  description = "Memory size in MB"
  type        = number
  default     = 2048
}

variable "hugepages" {
  description = "Whether to enable hugepages for the VM"
  type        = string
  default     = ""

  validation {
    condition     = contains(["", "2", "1024", "any"], var.hugepages)
    error_message = "The hugepages must be one of '2', '1024', or 'any'."
  }
}

variable "boot_size" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 32
}

variable "boot_datastore" {
  description = "Datastore for the VM"
  type        = string
  default     = "local"
}

variable "network" {
  type = map(any)
  default = {
    # "vmbr0" = {
    #   firewall        = true
    #   firewall_groups = "kubernetes"
    #   mtu             = 1500
    #   ip6             = ""
    #   gw6             = "fe80::1"
    #   ip6subnet       = "fe80::1/64"
    #   ip6mask         = 64
    #   ip6index        = 100
    #   ip4             = ""
    #   gw4             = "192.168.1.1"
    #   ip4subnet       = "192.168.1.0/24"
    #   ip4mask         = 24
    #   ip4index        = 32
    # }
    # "vmbr1" = {
    #   mtu = 1500
    #   ip6 = "auto"
    #   gw6 = "fe80::1"
    #   ip4 = "dhcp"
    #   gw4 = "192.168.1.1"
    # }
  }
}

variable "network_dns" {
  type    = list(string)
  default = []
}

variable "cloudinit_userdata_id" {
  description = "Userdata file ID for cloud-init image"
  type        = string
  default     = ""
}

variable "cloudinit_userdata" {
  description = "Userdata for cloud-init image"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudinit_datastore" {
  description = "Datastore for the userdata file"
  type        = string
  default     = "local"
}

variable "cloudinit_zone" {
  description = "Zone for the metadata file"
  type        = string
  default     = ""
}

variable "cloudinit_region" {
  description = "Region for the metadata file"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to be applied to the VM"
  type        = list(string)
  default     = []
}
