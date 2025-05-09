resource "proxmox_vm_qemu" "master-0" {
  vmid             = var.master0_id
  agent            = var.master0_agent
  name             = var.master0_name
  qemu_os          = var.master0_qemu_os
  desc             = var.master0_description
  target_node      = var.master0_target_node
  os_type          = var.master0_os_type
  full_clone       = var.master0_full_clone
  clone            = var.master0_template
  memory           = var.master0_memory
  cpu              = var.master0_cpu
  sockets          = var.master0_socket
  cores            = var.master0_cores
  scsihw           = var.master0_scsihw
  ssh_user         = var.master0_ssh_user
  ciuser           = var.master0_ssh_user
  ipconfig0        = "ip=${var.master0_ip_address}/32,gw=${var.master0_gateway}"
  cipassword       = var.master0_cloud_init_pass
  automatic_reboot = var.master0_automatic_reboot
  nameserver       = var.master0_dns_servers

  disk {
    storage = var.master0_storage_dev
    type    = var.master0_disk_type
    size    = var.master0_storage
  }

  network {
    bridge   = var.master0_network_bridge_type
    model    = var.master0_network_model
    mtu      = 0
    queues   = 0
    rate     = 0
    firewall = var.master0_network_firewall
  }
    #creates ssh connection to check when the CT is ready for deckhouse provisioning
  connection {
    host = var.master0_ip_address
    user = "root"
    private_key = file(var.ssh_keys["priv"])
    agent = false
    timeout = "3m"
  }

  provisioner "remote-exec" {
	  # Leave this here so we know when to start with Ansible local-exec
    inline = [ "echo 'Cool, we are ready for provisioning'"]
  }
  # Updates and initial VM preparation
  provisioner "local-exec" {
    command = "ansible-playbook -u root --key-file ${var.ssh_keys["priv"]} -i ${var.master0_ip_address}, -e 'node_name=${self.name}' ./deckhouse/host_preparation.yml"
  }
  # Domain and A record verification
  provisioner "local-exec" {
    command = "ansible-playbook -u root --key-file ${var.ssh_keys["priv"]} -i ${var.master0_ip_address}, ./deckhouse/create-domains.yaml"
  }
  # Starting Deckhouse installation on master-0
  provisioner "local-exec" {
    command = "./deckhouse/master0-install.sh ${var.master0_ip_address}"
  }
  # Running the post-install playbook on master-0
  provisioner "local-exec" {
    command = "ansible-playbook -u root --key-file ${var.ssh_keys["priv"]} -i ${var.master0_ip_address}, ./deckhouse/master-0-post-install.yaml"
  }

}

resource "proxmox_vm_qemu" "virtual_machines" {
  for_each         = var.virtual_machines
  agent            = each.value.agent
  vmid             = each.value.id
  name             = each.value.name
  qemu_os          = each.value.qemu_os
  desc             = each.value.description
  target_node      = each.value.target_node
  os_type          = each.value.os_type
  full_clone       = each.value.full_clone
  clone            = each.value.template
  memory           = each.value.memory
  cpu              = each.value.cpu
  sockets          = each.value.socket
  cores            = each.value.cores
  scsihw           = each.value.scsihw
  ssh_user         = each.value.ssh_user
  ciuser           = each.value.ssh_user
  ipconfig0        = "ip=${each.value.ip_address}/32,gw=${each.value.gateway}"
  cipassword       = each.value.cloud_init_pass
  automatic_reboot = each.value.automatic_reboot
  nameserver       = each.value.dns_servers

  disk {
    storage = each.value.storage_dev
    type    = each.value.disk_type
    size    = each.value.storage
  }

  network {
    bridge   = each.value.network_bridge_type
    model    = each.value.network_model
    mtu      = 0
    queues   = 0
    rate     = 0
    firewall = each.value.network_firewall
  }
    #creates ssh connection to check when the CT is ready for deckhouse provisioning
  connection {
    host = each.value.ip_address
    user = "core"
    private_key = file(var.ssh_keys["priv"])
    agent = false
    timeout = "5m"
  }

  provisioner "remote-exec" {
	  # Leave this here so we know when to start with Ansible local-exec
    inline = [ "echo 'Cool, we are ready for provisioning'"]
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u root --key-file ${var.ssh_keys["priv"]} -i ${each.value.ip_address}, -e 'node_name=${self.name}' ./deckhouse/host_preparation.yml"
  }

  provisioner "local-exec" {
        command = "ansible-playbook -u root --key-file ${var.ssh_keys["priv"]} -i ${each.value.ip_address}, -e 'node_group=${each.value.node_group}' ${each.value.ansible_playbook} || true"
  }
  depends_on = [proxmox_vm_qemu.master-0]
}
resource "null_resource" "cluster_setup_post_install" {
    depends_on = [
      proxmox_vm_qemu.master-0,
      proxmox_vm_qemu.virtual_machines,
  ]
  provisioner "local-exec" {
    command = "ansible-playbook -u root --key-file ${var.ssh_keys["priv"]} -i ${var.master0_ip_address}, ./deckhouse/cluster-setup-post-install.yaml"
  }
}
