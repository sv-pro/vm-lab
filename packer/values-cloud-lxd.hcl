# Cloud-based configuration for Ubuntu 24.04 LXD host VM image
# This uses pre-built Ubuntu cloud image as base and installs LXD

image_name           = "ubuntu-24.04-cloud-lxd"
disk_size           = "20G"
ssh_username        = "ubuntu"
ssh_private_key_file = "cloud-init/id_rsa"

# LXD specific packages (snapd is already installed in Ubuntu cloud images)
extra_packages = [
  "bridge-utils",
  "dnsmasq-base",
  "uidmap"
]

# LXD specific provisioning (install via snap in Ubuntu 24.04)
provision_inline = [
  "echo 'Installing LXD via snap...'",
  "sudo snap install lxd --channel=latest/stable",
  "sudo usermod -aG lxd ubuntu",
  "echo 'Waiting for LXD to initialize...'",
  "sleep 10",
  "echo 'LXD installation complete'"
]