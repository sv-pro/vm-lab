# Cloud-based configuration for Ubuntu 24.04 VM image
# This uses pre-built Ubuntu cloud image as base

image_name           = "ubuntu-24.04-cloud-base"
disk_size           = "20G"
ssh_username        = "ubuntu"
ssh_private_key_file = "cloud-init/id_rsa"
extra_packages      = []
provision_inline    = []