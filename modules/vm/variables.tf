variable "virtual_machines" {
  type        = map
  default     = {}
  description = "Identifies the object of virtual machines."
}
variable "ssh_keys" {
	type = map
     default = {
       pub  = "~/.ssh/id_rsa.pub"
       priv = "~/.ssh/id_rsa"
     }
}
variable "master0_id" {
  type = string
  default = "200"
}
variable "master0_agent" {
  type = string
}
variable "master0_name" {
  type = string
  default = "master-0"
}
variable "master0_qemu_os" {
  type = string
  default = "other"
}
variable "master0_description" {
  type = string
  default = "master 0 node"
}
variable "master0_target_node" {
  type = string
  default = "pve-pr"
}
variable "master0_os_type" {
  type = string
  default = "cloud-init"
}
variable "master0_full_clone" {
  type = bool
  default = true
}
variable "master0_template" {
  type = string
  default = "ubuntu-cloud-init"
}
variable "master0_memory" {
  type = string
  default = "16384"
}
variable "master0_cpu" {
  type = string
  default = "1"
}
variable "master0_socket" {
  type = string
  default = "1"
}
variable "master0_cores" {
  type = string
  default = "8"
}
variable "master0_scsihw" {
  type = string
  default = "virtio-scsi-pci"
}
variable "master0_ssh_user" {
  type = string
  default = "admin"
}
variable "master0_ip_address" {
  type = string
  default = "192.168.4.200"
}
variable "master0_gateway" {
  type = string
  default = "192.168.4.1"
}
variable "master0_cloud_init_pass" {
  type = string
  default = "password"
}
variable "master0_automatic_reboot" {
  type = bool
  default = true
}
variable "master0_dns_servers" {
  type = string
  default = "8.8.8.8 127.0.0.1"
}
variable "master0_storage_dev" {
  type = string
  default = "fast"
}
variable "master0_disk_type" {
  type = string
  default = "virtio"
}
variable "master0_storage" {
  type = string
  default = "100G"
}
variable "master0_network_bridge_type" {
  type = string
  default = "vmbr0"
}
variable "master0_network_model" {
  type = string
  default = "virtio"
}
variable "master0_network_firewall" {
  type = bool
  default = false
}
