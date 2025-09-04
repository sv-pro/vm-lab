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
  "sudo apt update",
  "sudo apt -y install ca-certificates curl",
  "sudo install -m 0755 -d /etc/apt/keyrings",
  "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
  "sudo chmod a+r /etc/apt/keyrings/docker.asc",
  "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
  "sudo apt update",
  "sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
  "sudo usermod -aG docker ubuntu",
  "sudo usermod -aG docker dev",
  "sudo systemctl enable docker",
  "sudo systemctl start docker",
  "echo 'Docker installation complete'"
]