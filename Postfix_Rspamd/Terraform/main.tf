#### Providers einrichten ####
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">=2"
    }
  }
}
provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = true
}
#### Die Daten von vSphere sammeln ####
data "vsphere_datacenter" "datacenter" {
  name = var.datacenter

}
data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
data "vsphere_virtual_machine" "template" {
  name          = var.template
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
#### VMs erstellen ####
resource "vsphere_virtual_machine" "vm" {
  count            = var.linux_instance
  name             = "${var.linux_vm_name}-${count.index + 1}"
  resource_pool_id = data.vsphere_host.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.linux_cpu
  memory           = var.linux_mem
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  firmware         = data.vsphere_virtual_machine.template.firmware

  #### die Netzwerkinterfaces einrichten ####

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  wait_for_guest_net_timeout  = 10000000000000000
  wait_for_guest_net_routable = false
  wait_for_guest_ip_timeout   = 10000000000000000
  shutdown_wait_timeout       = 10
  migrate_wait_timeout        = 10000000000000000
  force_power_off             = false

#### Die Fesplatten einrichten ####
  dynamic "disk" {
    for_each = [for s in data.vsphere_virtual_machine.template.disks : {
      label            = index(data.vsphere_virtual_machine.template.disks, s)
      unit_number      = index(data.vsphere_virtual_machine.template.disks, s)
      size             = s.size
      eagerly_scrub    = s.eagerly_scrub
      thin_provisioned = contains(keys(s), "thin_provisioned") ? s.thin_provisioned : "true"
    }]
    content {
      label            = disk.value.label
      unit_number      = disk.value.unit_number
      size             = disk.value.size
      datastore_id     = data.vsphere_datastore.datastore.id
      eagerly_scrub    = disk.value.eagerly_scrub
      thin_provisioned = disk.value.thin_provisioned
    }
  }
#### Das Template festlegen ####
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

#### Die Linuxeinstellung festlegen ####
    customize {
      linux_options {
        host_name = "${var.linux_vm_name}-${count.index + 1}"
        domain    = var.linux_domain
        time_zone = var.time_zone

      }
      timeout = 60
#### Der Netzadapter einrichten ####
      network_interface {
        ipv4_address = var.ipv4_address[count.index]
        ipv4_netmask = "24"
      }

      ipv4_gateway    = var.default_gateway
      dns_server_list = var.default_DNS
    }

  }
}
#### Wir sollen warten,um die Ansible-Playbooks auszuführen ####
resource "null_resource" "wait" {
 depends_on = [vsphere_virtual_machine.vm]
    provisioner "local-exec" {
   command = "sleep 120"
    }
}
#### Die Ansible Playbooks ausführen ####
resource "null_resource" "run_ansible" {
  depends_on = [ null_resource.wait , vsphere_virtual_machine.vm]
  triggers = {always_run = timestamp()}   
  # übergabe an Ansible
  provisioner "local-exec" {
   command = "ansible-playbook -i /home/goerkem/Automation/Ansible/inventory.ini /home/goerkem/Automation/Ansible/site.yml "
    
  }
 }
   
