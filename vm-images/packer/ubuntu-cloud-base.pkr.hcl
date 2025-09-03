packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">=1.0.0"
    }
  }
}

variable "base_image_url" {
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}
variable "base_image_checksum" {
  default = "sha256:834af9cd766d1fd86eca156db7dff34c3713fbbc7f5507a3269be2a72d2d1820"
}
variable "ssh_username" { default = "ubuntu" }
variable "ssh_private_key_file" { default = "" }
variable "disk_size" { default = "20G" }
variable "image_name" { default = "ubuntu-custom" }
variable "extra_packages" {
  type    = list(string)
  default = []
}
variable "provision_inline" {
  type    = list(string)
  default = []
}

source "qemu" "ubuntu-cloud" {
  # Use existing cloud image instead of ISO
  disk_image        = true
  iso_url           = var.base_image_url
  iso_checksum      = var.base_image_checksum
  output_directory  = "../output/${var.image_name}"
  disk_size         = var.disk_size
  format            = "qcow2"
  
  # SSH configuration for cloud image
  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "10m"
  
  # VM settings
  headless      = true
  memory        = 2048
  cpus          = 2
  net_device    = "virtio-net"
  disk_interface = "virtio"
  
  # No boot commands needed - cloud image boots directly
  boot_wait = "30s"
  
  # Cloud-init user data for SSH key setup
  cd_content = {
    "user-data" = templatefile("cloud-init/user-data.yml", {
      ssh_public_key = file("cloud-init/id_rsa.pub")
    })
    "meta-data" = file("cloud-init/meta-data.yml")
  }
  cd_label = "cidata"
}

build {
  sources = ["source.qemu.ubuntu-cloud"]

  # Wait for cloud-init to complete
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait"
    ]
  }

  # System updates and basic packages
  provisioner "shell" {
    inline = concat(
      [
        "sudo apt update",
        "sudo apt -y upgrade",
        "sudo apt -y install qemu-guest-agent"
      ],
      length(var.extra_packages) > 0 ? ["sudo apt -y install ${join(" ", var.extra_packages)}"] : [],
      var.provision_inline
    )
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "sudo apt -y autoremove",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -rf /var/lib/cloud/instances/*"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "ls -la ../output/${var.image_name}/",
      "if [ -f '../output/${var.image_name}/packer-ubuntu-cloud' ]; then mv ../output/${var.image_name}/packer-ubuntu-cloud ../output/${var.image_name}.qcow2; else echo 'No packer-ubuntu-cloud file found, checking for other files:'; ls -la ../output/${var.image_name}/; fi"
    ]
  }
}