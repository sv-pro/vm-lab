# Cloud-based configuration for Ubuntu 24.04 Kata host VM image
# This uses pre-built Ubuntu cloud image as base and installs Kata runtime

image_name           = "ubuntu-24.04-cloud-kata"
disk_size           = "20G"
ssh_username        = "ubuntu"
ssh_private_key_file = "cloud-init/id_rsa"

# Kata specific packages
extra_packages = [
  "ca-certificates",
  "curl",
  "gnupg",
  "lsb-release",
  "apt-transport-https"
]

# Kata specific provisioning
provision_inline = [
  "echo 'Installing Docker for Kata runtime...'",
  "sudo install -m 0755 -d /etc/apt/keyrings",
  "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
  "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
  "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
  "sudo apt update",
  "sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
  "sudo usermod -aG docker ubuntu",
  "sudo systemctl enable docker",
  "sudo systemctl start docker",
  "echo 'Installing Kata containers...'",
  "wget -q https://github.com/kata-containers/kata-containers/releases/download/3.2.0/kata-static-3.2.0-x86_64.tar.xz",
  "sudo tar -xf kata-static-3.2.0-x86_64.tar.xz -C /",
  "sudo ln -sf /opt/kata/bin/kata-runtime /usr/local/bin/kata-runtime",
  "echo 'Configuring Docker for Kata runtime...'",
  "sudo mkdir -p /etc/docker",
  "echo '{\"default-runtime\": \"runc\", \"runtimes\": {\"kata-runtime\": {\"path\": \"/usr/local/bin/kata-runtime\"}}}' | sudo tee /etc/docker/daemon.json",
  "sudo systemctl restart docker",
  "echo 'Kata installation complete'"
]