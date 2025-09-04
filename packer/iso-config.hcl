# Ubuntu 24.04.3 LTS Server ISO Configuration
# This file contains the base ISO configuration for Ubuntu 24.04.3 LTS Server

# Ubuntu 24.04.3 LTS Server (Noble Numbat)
iso_url      = "https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso"
iso_checksum = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"

# Default credentials for Ubuntu Server
ssh_username = "ubuntu"
ssh_password = "ubuntu"

# Boot wait time to allow system to initialize
boot_wait = "5s"