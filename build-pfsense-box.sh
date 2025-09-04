#!/bin/bash
# Script to build real pfSense Vagrant box using Packer

echo "🔥 Building Real pfSense Vagrant Box"

# Check prerequisites
command -v packer >/dev/null 2>&1 || { echo "Packer is required but not installed. Aborting." >&2; exit 1; }
command -v VBoxManage >/dev/null 2>&1 || { echo "VirtualBox is required but not installed. Aborting." >&2; exit 1; }

# Create build directory
mkdir -p pfsense-build && cd pfsense-build

# Download pfSense ISO (latest CE version)
PFSENSE_VERSION="2.7.2"
PFSENSE_ISO="pfSense-CE-${PFSENSE_VERSION}-RELEASE-amd64.iso"
PFSENSE_URL="https://atxfiles.netgate.com/mirror/downloads/${PFSENSE_ISO}"

if [ ! -f "$PFSENSE_ISO" ]; then
    echo "Downloading pfSense ISO..."
    wget "$PFSENSE_URL" || curl -O "$PFSENSE_URL"
fi

# Create Packer template for pfSense
cat > pfsense.pkr.hcl << 'EOF'
packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "iso_path" {
  type    = string
  default = "pfSense-CE-2.7.2-RELEASE-amd64.iso"
}

source "virtualbox-iso" "pfsense" {
  iso_url      = var.iso_path
  iso_checksum = "none"  # Skip checksum for local file
  
  vm_name              = "pfsense-vagrant"
  guest_os_type        = "FreeBSD_64"
  disk_size            = 8192
  memory               = 2048
  cpus                 = 2
  
  # Network settings
  nic_type             = "virtio"
  sound                = "none"
  usb                  = false
  
  # Boot configuration
  boot_wait            = "10s"
  boot_command = [
    # pfSense auto-install commands
    "<enter><wait10>",           # Accept copyright
    "<enter><wait5>",            # Install pfSense
    "<enter><wait5>",            # Continue with installation
    "<enter><wait5>",            # Select disk
    "<left><enter><wait5>",      # Confirm disk selection
    "<wait30>",                  # Wait for installation
    "<enter><wait5>",            # No manual configuration
    "<enter><wait5>",            # Reboot
  ]
  
  # SSH settings (pfSense doesn't have SSH enabled by default)
  ssh_username         = "admin"
  ssh_password         = "pfsense" 
  ssh_timeout          = "20m"
  ssh_port             = 22
  
  # Disable SSH for pfSense (it uses web interface)
  communicator         = "none"
  
  shutdown_command     = "shutdown -p now"
  shutdown_timeout     = "5m"
  
  # Export settings
  format               = "ovf"
  output_directory     = "output-pfsense"
}

build {
  sources = ["source.virtualbox-iso.pfsense"]
  
  # pfSense doesn't support typical provisioning
  # Configuration must be done post-build via web interface
  
  post-processor "vagrant" {
    output = "pfsense.box"
  }
}
EOF

echo "📦 Building pfSense box with Packer..."
echo "This may take 20-30 minutes..."
packer build pfsense.pkr.hcl

if [ $? -eq 0 ]; then
    echo "✅ pfSense box built successfully: pfsense.box"
    echo "Add it to Vagrant with: vagrant box add --name pfsense-custom pfsense.box"
else
    echo "❌ Build failed. Check the logs above."
fi