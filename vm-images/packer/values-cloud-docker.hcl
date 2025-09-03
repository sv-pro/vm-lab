# Cloud-based configuration for Ubuntu 24.04 Docker host VM image
# This uses pre-built Ubuntu cloud image as base and installs Docker

image_name           = "ubuntu-24.04-cloud-docker"
disk_size           = "20G"
ssh_username        = "ubuntu"
ssh_private_key_file = "cloud-init/id_rsa"

# Docker specific packages
extra_packages = [
  "ca-certificates",
  "gnupg",
  "lsb-release",
  "apt-transport-https"
]

# Docker specific provisioning
provision_inline = [
  "echo 'Installing Docker...'",
  "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
  "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
  "sudo apt update",
  "sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
  "sudo usermod -aG docker ubuntu",
  "sudo systemctl enable docker",
  "sudo systemctl start docker",
  "echo 'Docker installation complete'"
]