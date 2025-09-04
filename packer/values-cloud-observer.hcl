# Cloud-based configuration for Ubuntu 24.04 Observer host VM image
# This uses pre-built Ubuntu cloud image as base and installs monitoring/observability tools

image_name           = "ubuntu-24.04-cloud-observer"
disk_size           = "20G"
ssh_username        = "ubuntu"
ssh_private_key_file = "cloud-init/id_rsa"

# Observer specific packages
extra_packages = [
  "htop",
  "iotop",
  "tcpdump",
  "wireshark-common",
  "strace",
  "ltrace",
  "sysstat",
  "perf-tools-unstable",
  "bpfcc-tools",
  "linux-tools-generic",
  "prometheus-node-exporter",
  "curl",
  "wget",
  "jq",
  "tree",
  "net-tools",
  "dnsutils"
]

# Observer specific provisioning
provision_inline = [
  "echo 'Configuring system monitoring tools...'",
  "sudo systemctl enable prometheus-node-exporter",
  "sudo systemctl start prometheus-node-exporter",
  "echo 'Installing additional eBPF tools...'",
  "sudo apt -y install python3-bpfcc",
  "echo 'Setting up user for monitoring tools...'",
  "sudo usermod -aG adm ubuntu",
  "sudo usermod -aG systemd-journal ubuntu",
  "echo 'Creating monitoring directories...'",
  "mkdir -p /home/ubuntu/monitoring",
  "mkdir -p /home/ubuntu/scripts",
  "echo 'Observer tools installation complete'"
]