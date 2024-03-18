#### das Name von vSphere Server eingeben ####
variable "vsphere_server" {
  type    = string
}
#### das Username von vSphere  eingeben ####

variable "vsphere_user" {
  type    = string
}
#### das Password von vSphere  eingeben ####

variable "vsphere_password" {
  type      = string
  sensitive = true
}
#### das Name von vSphere Datacenter eingeben ####

variable "datacenter" {
  default = "Datacenter"
  type    = string
}
#### das Name von vSphere Cluster eingeben ####

variable "cluster" {
  default = "192.168.44.2"
  type    = string
}
#### das Name von vSphere Datastore eingeben ####

variable "datastore" {
  default = "datastore1"
  type    = string
}
#### Die Netzwerkeinstellung eingeben ####
variable "network_name" {
  default = "LabNet"
  type    = string
}
variable "default_gateway" {
  type = string
  default = "192.168.44.254"
}

variable "default_DNS" {
  type = list(string)
  default = ["8.8.8.8",
  "4.4.4.4", ]
}

variable "ipv4_address" {
  description = "Avaliable IP"
  type        = list(string)
  default = [
    "192.168.44.15",
    "192.168.44.16",
    
  ]
}
#### OS Template ####
variable "template" {
  description = "OS Template"
  type = string
  default = "UbuntuVorlage"
  
}
#### Das Linux der Einstellung eingeben ####
variable "linux_cpu" {
  default = "2"
}
variable "linux_mem" {
  default = "2048"
}
variable "linux_folder" {
  default = "linux"
}
variable "linux_vm_name" {
  default = "mailserver"
}
variable "linux_domain" {
  default = "test.loc"
}
variable "linux_instance" {
  default = "2"
}
variable "linux_user" {
  default = "goerkem"

}
variable "linux_template_password" {
    type = string
}

variable "linux_os" {
  default = "Ubuntu"

}
variable "linux_job" {
  default = "group job"
}
variable "time_zone" {
  default = "Europe/Berlin"

}