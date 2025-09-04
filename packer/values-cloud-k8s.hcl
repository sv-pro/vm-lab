# Cloud-based configuration for Ubuntu 24.04 Kubernetes host VM image
# This uses pre-built Ubuntu cloud image as base and installs kubeadm, kubectl, kubelet

image_name           = "ubuntu-24.04-cloud-k8s"
disk_size           = "20G"
ssh_username        = "ubuntu"
ssh_private_key_file = "cloud-init/id_rsa"

# Kubernetes specific packages
extra_packages = [
  "ca-certificates",
  "curl",
  "gnupg",
  "lsb-release",
  "apt-transport-https"
]

# Kubernetes specific provisioning
provision_inline = [
  "echo 'Installing containerd...'",
  "sudo apt -y install containerd",
  "sudo mkdir -p /etc/containerd",
  "containerd config default | sudo tee /etc/containerd/config.toml",
  "sudo systemctl restart containerd",
  "sudo systemctl enable containerd",
  "echo 'Installing Kubernetes components...'",
  "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
  "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
  "sudo apt update",
  "sudo apt -y install kubelet kubeadm kubectl",
  "sudo apt-mark hold kubelet kubeadm kubectl",
  "echo 'net.bridge.bridge-nf-call-iptables = 1' | sudo tee -a /etc/sysctl.conf",
  "echo 'net.bridge.bridge-nf-call-ip6tables = 1' | sudo tee -a /etc/sysctl.conf",
  "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf",
  "echo 'Kubernetes installation complete'"
]