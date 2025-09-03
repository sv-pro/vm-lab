# Cloud-based configuration for Ubuntu 24.04 LXD host VM image
# This uses pre-built Ubuntu cloud image as base and installs LXD

image_name           = "ubuntu-24.04-cloud-lxd"
disk_size           = "20G"
ssh_username        = "ubuntu"
ssh_private_key_file = "cloud-init/id_rsa"

# LXD specific packages
extra_packages = [
  "lxd",
  "lxd-client",
  "bridge-utils",
  "dnsmasq-base",
  "uidmap"
]

# LXD specific provisioning
provision_inline = [
  "echo 'Configuring LXD...'",
  "sudo usermod -aG lxd ubuntu",
  "sudo systemctl enable lxd",
  "sudo systemctl start lxd",
  "echo 'LXD installation complete'"
]