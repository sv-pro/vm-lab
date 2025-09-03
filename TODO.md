Instructions for Claude Code: VM image build project (QEMU + Packer)

Goal:
Build infrastructure for generating Ubuntu 24.04 qcow2 images for 5 roles:
- LXD host
- Docker host
- Kubernetes host
- Kata host
- Observer host (for monitoring/experiments with eBPF/Prometheus/Grafana)

Project structure (list of paths):
vm-images/
vm-images/packer/ubuntu-custom.pkr.hcl
vm-images/packer/values-base.hcl
vm-images/packer/values-lxd.hcl
vm-images/packer/values-docker.hcl
vm-images/packer/values-k8s.hcl
vm-images/packer/values-kata.hcl
vm-images/packer/values-observer.hcl
vm-images/output/ubuntu-24.04-base.qcow2
vm-images/output/ubuntu-24.04-lxd.qcow2
vm-images/output/ubuntu-24.04-docker.qcow2
vm-images/output/ubuntu-24.04-k8s.qcow2
vm-images/output/ubuntu-24.04-kata.qcow2
vm-images/output/ubuntu-24.04-observer.qcow2

Universal template ubuntu-custom.pkr.hcl (example content):
-----------------------------------------------------------
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
      length(var.extra_packages) > 0 ? ["sudo apt -y install ${join(\" \", var.extra_packages)}"] : [],
      var.provision_inline
    )
  }

  post-processor "shell-local" {
    inline = [
      "mv output/${var.image_name}/packer-qemu output/${var.image_name}.qcow2"
    ]
  }
}

Values files:
-----------------------------------------------------------

values-base.hcl
image_name   = "ubuntu-24.04-base"
disk_size    = "20G"
ssh_username = "ubuntu"
ssh_password = "ubuntu"
extra_packages = []
provision_inline = []

values-lxd.hcl
image_name   = "ubuntu-24.04-lxd"
disk_size    = "20G"
ssh_username = "ubuntu"
ssh_password = "ubuntu"
extra_packages = ["lxd","zfsutils-linux","prometheus-node-exporter"]
provision_inline = []

values-docker.hcl
image_name   = "ubuntu-24.04-docker"
disk_size    = "20G"
ssh_username = "ubuntu"
ssh_password = "ubuntu"
extra_packages = ["docker.io","docker-compose"]
provision_inline = ["sudo systemctl enable docker"]

values-k8s.hcl
image_name   = "ubuntu-24.04-k8s"
disk_size    = "30G"
ssh_username = "ubuntu"
ssh_password = "ubuntu"
extra_packages = ["snapd"]
provision_inline = [
  "sudo snap install microk8s --classic",
  "sudo usermod -aG microk8s ubuntu"
]

values-kata.hcl
image_name   = "ubuntu-24.04-kata"
disk_size    = "25G"
ssh_username = "ubuntu"
ssh_password = "ubuntu"
extra_packages = ["docker.io","qemu-system-x86","kata-runtime","kata-proxy","kata-shim"]
provision_inline = [
  "sudo mkdir -p /etc/docker",
  "printf '{\\n  \"runtimes\": {\"kata-runtime\": {\"path\": \"/usr/bin/kata-runtime\"}}\\n}\\n' | sudo tee /etc/docker/daemon.json",
  "sudo systemctl enable docker"
]

values-observer.hcl
image_name   = "ubuntu-24.04-observer"
disk_size    = "20G"
ssh_username = "ubuntu"
ssh_password = "ubuntu"
extra_packages = ["htop","iftop","nload","tcpdump","bpftrace","bpftool","bpfcc-tools","prometheus-node-exporter","grafana-agent"]
provision_inline = []

Build commands:
-----------------------------------------------------------
packer build -var-file=packer/values-lxd.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-docker.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-k8s.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-kata.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-observer.hcl packer/ubuntu-custom.pkr.hcl
