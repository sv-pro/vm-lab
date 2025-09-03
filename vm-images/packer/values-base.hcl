# Base configuration for Ubuntu 24.04 VM image
# This configuration creates a minimal Ubuntu 24.04 image

iso_url          = "https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso"
iso_checksum     = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
image_name       = "ubuntu-24.04-base"
disk_size        = "20G"
ssh_username     = "ubuntu"
ssh_password     = "ubuntu"
extra_packages   = []
provision_inline = []