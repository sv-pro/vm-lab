# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VM Lab is a comprehensive virtualization platform for building enterprise-grade network infrastructures. It supports multiple VM roles for learning, testing, and development:

- **Base**: Clean Ubuntu 24.04 foundation
- **LXD host**: System container management 
- **Docker host**: Container runtime and orchestration
- **Kubernetes host**: MicroK8s cluster deployment
- **Kata host**: Secure container isolation
- **Observer host**: Network monitoring with eBPF/Prometheus/Grafana
- **Router**: FRRouting with BGP/OSPF/ISIS support
- **pfSense**: Web-managed firewall and gateway

## Architecture

**Current Implementation:**
- Vagrant with libvirt provider for VM lifecycle management
- Multi-machine Vagrantfile supporting all VM roles  
- Role-specific provisioning scripts and templates
- Makefile wrapper providing consistent command interface
- Dynamic VM naming with custom workspace support

## Project Structure

```
vm-lab/
├── Makefile                 # Main command interface
├── Vagrantfile              # Multi-machine VM definitions  
├── vm-vagrant.sh           # VM management wrapper script
├── templates/              # Role-specific VM templates
│   ├── Vagrantfile.docker  # Docker host template
│   ├── Vagrantfile.k8s     # Kubernetes template
│   └── Vagrantfile.router  # Router template
├── docs/                   # Comprehensive documentation
├── vms/                    # Custom VM workspaces
└── output/                 # VM artifacts and logs
```

## Command Interface

VM Lab uses a consistent Makefile interface that wraps Vagrant commands:

### VM Creation
```bash
# Create role-specific VMs with optional custom names
make create-base [NAME=<name>]      # Clean Ubuntu foundation
make create-docker [NAME=<name>]    # Docker container host
make create-k8s [NAME=<name>]       # Kubernetes cluster node
make create-lxd [NAME=<name>]       # LXD system containers
make create-kata [NAME=<name>]      # Kata secure containers
make create-observer [NAME=<name>]  # Network monitoring
make create-router [NAME=<name>]    # FRRouting BGP/OSPF
make create-pfsense [NAME=<name>]   # pfSense firewall

# Shorthand aliases (use default names)
make docker    # Creates "docker" VM
make k8s       # Creates "k8s" VM
make router    # Creates "router" VM
```

### VM Management
```bash
make list                    # List all VMs and their status
make start [NAME=<name>]     # Start specific or all VMs
make stop [NAME=<name>]      # Stop specific or all VMs
make ssh [NAME=<name>]       # SSH into running VM
make delete NAME=<name>      # Delete VM (requires confirmation)
make status                  # Check overall VM status
```

### Examples
```bash
# Create infrastructure with custom names
make create-router NAME=core-gateway
make create-pfsense NAME=perimeter-fw  
make create-docker NAME=web-cluster
make create-observer NAME=monitoring

# Manage VMs
make start NAME=core-gateway
make ssh NAME=web-cluster
make delete NAME=old-test-vm
```

## VM Role Configurations

Each VM role includes:
- **Base**: Minimal Ubuntu 24.04 with essential tools
- **Docker**: Docker Engine, Docker Compose, container registry
- **K8s**: MicroK8s cluster, kubectl, Helm ready
- **LXD**: LXD daemon, ZFS storage, system container tools
- **Kata**: Kata runtime, secure container isolation
- **Observer**: Prometheus, Grafana, eBPF tools, network analyzers
- **Router**: FRRouting suite (BGP, OSPF, ISIS), network tools
- **pfSense**: FreeBSD-based firewall with web management interface

## Architecture Details

### Dynamic VM Naming
- Custom workspace creation in `vms/<name>/` directory
- Role-specific Vagrantfile templating
- Isolated VM configurations and networking
- Support for multiple VMs of same role

### Network Configuration
- Libvirt default network with DHCP
- SSH key-based authentication
- Automatic hostname resolution
- Internet connectivity through host bridge

### Provisioning System
- Shell-based provisioning for each role
- Role-specific package installation
- Service configuration and startup
- Network and security hardening

## Dependencies

### Host Requirements
- **Virtualization**: QEMU/KVM with hardware acceleration
- **Vagrant**: Version 2.4.9 or higher
- **Provider**: vagrant-libvirt plugin
- **Resources**: Minimum 8GB RAM, 50GB disk space
- **Network**: Internet connectivity for package downloads

### Installation Commands
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install vagrant libvirt-daemon-system qemu-kvm

# Install vagrant-libvirt plugin
vagrant plugin install vagrant-libvirt

# Verify installation
vagrant --version
libvirtd --version
```