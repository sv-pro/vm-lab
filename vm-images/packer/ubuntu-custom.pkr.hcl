packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">=1.0.0"
    }
  }
}

variable "iso_url" {}
variable "iso_checksum" {}
variable "ssh_username" { default = "ubuntu" }
variable "ssh_password" { default = "ubuntu" }
variable "disk_size"    { default = "20G" }
variable "image_name"   { default = "ubuntu-custom" }
variable "extra_packages" {
  type    = list(string)
  default = []
}
variable "provision_inline" {
  type    = list(string)
  default = []
}

source "qemu" "ubuntu" {
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  output_directory = "output/${var.image_name}"
  disk_size        = var.disk_size
  format           = "qcow2"
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  headless         = true
  
  # Boot commands for Ubuntu Server autoinstall
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' <wait>",
    "<enter><wait>",
    "initrd /casper/initrd <wait>",
    "<enter><wait>",
    "boot<enter>"
  ]
  
  # HTTP server for autoinstall configuration
  http_directory = "http"
  http_port_min  = 8000
  http_port_max  = 9000
  
  # SSH configuration
  ssh_timeout = "20m"
  
  # Boot wait
  boot_wait = "5s"
  
  # VM settings
  memory    = 2048
  cpus      = 2
  net_device = "virtio-net"
  disk_interface = "virtio"
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = concat(
      [
        "sudo apt update",
        "sudo apt -y upgrade",
        "sudo apt -y install qemu-guest-agent cloud-init"
      ],
      length(var.extra_packages) > 0 ? ["sudo apt -y install ${join(" ", var.extra_packages)}"] : [],
      var.provision_inline
    )
  }

  post-processor "shell-local" {
    inline = [
      "mv output/${var.image_name}/packer-qemu output/${var.image_name}.qcow2"
    ]
  }
}