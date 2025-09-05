# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modern VM management system using Vagrant-libvirt for provisioning Ubuntu 24.04 VMs. Currently supports 3 production-ready VM roles:

**✅ Production-Ready Roles (Tested & Working):**
- Base Ubuntu (clean development environment)
- Docker host (container runtime with docker-compose)
- Observer host (monitoring with eBPF tools)

**Note:** Also includes 5 experimental roles (k8s, lxd, kata, router, pfsense) that are available but hidden from help due to known issues. Use with caution - these are undocumented "advanced user" features.

## Current Architecture

**Vagrant-libvirt Based System with Advanced Hybrid Networking:**

- Primary provider: libvirt (KVM virtualization)
- Fallback provider: VirtualBox (when libvirt unavailable)
- Multi-machine Vagrantfile with 8 predefined VM roles (3 production + 5 experimental)
- Custom VM support with isolated directories and templates
- Unified Makefile interface for all operations
- **🚀 Hybrid Networking**: VMs and Docker containers communicate on shared network (10.0.1.0/24)
- **🔍 DNS Service Discovery**: hostname.hybrid.local resolution between all components
- **📊 Network Monitoring**: Real-time traffic monitoring and comprehensive diagnostics

## Project Structure

```text
vm-lab/
├── Vagrantfile              # Multi-machine VM definitions (3 production + 5 experimental)
├── vm-vagrant.sh           # Vagrant wrapper for custom VMs  
├── Makefile                # Unified VM management interface
├── templates/              # Vagrantfile templates for custom VMs
├── vms/                    # Isolated custom VM directories
└── README.md               # Project documentation
```

## VM Management Commands

**Makefile Interface (Recommended):**
```bash
# VM Creation (production-ready and tested - shown in help)
make create-base [NAME=<name>]     # Create base Ubuntu VM
make create-docker [NAME=<name>]   # Create Docker host VM  
make create-observer [NAME=<name>] # Create Observer host VM

# 🚀 Hybrid Networking (VM + Docker Container Communication)
make create-hybrid-network         # Create shared bridge network (10.0.1.0/24)
make hybrid-base [NAME=<name>]     # Create base VM with hybrid networking
make hybrid-docker [NAME=<name>]   # Create Docker VM with hybrid networking
make hybrid-status                 # Show hybrid network status

# 🔍 DNS Service Discovery
make hybrid-enable-dns             # Enable hostname resolution (containers ↔ VMs)
make hybrid-update-dns             # Update DNS records for all components

# 📊 Network Monitoring & Debugging
make hybrid-monitor                # Real-time traffic monitoring
make hybrid-debug                  # Comprehensive network diagnostics  
make hybrid-logs                   # DNS container logs

# Experimental VM Creation (hidden from help - use with caution)
make create-k8s [NAME=<name>]      # Create Kubernetes host VM (snap issues)
make create-lxd [NAME=<name>]      # Create LXD host VM (snap timeout)
make create-kata [NAME=<name>]     # Create Kata host VM (creation timeout)
make create-router [NAME=<name>]   # Create Virtual Router VM (provisioning timeout)
make create-pfsense [NAME=<name>]  # Create pfSense-style VM (heavy provisioning)

# VM Management
make start NAME=<name>             # Start VM
make stop NAME=<name>              # Stop VM
make ssh NAME=<name>               # SSH into VM
make delete NAME=<name>            # Delete VM
make status                        # Check all VM status
make list                          # List all VMs
```

**Direct Vagrant Commands:**
```bash
# Predefined VMs (from main Vagrantfile)
vagrant up docker              # Start predefined docker VM
vagrant ssh docker             # SSH to predefined VM
vagrant halt docker            # Stop predefined VM
vagrant destroy docker         # Destroy predefined VM

# Custom VMs (created via templates)
./vm-vagrant.sh create docker web-server   # Create custom VM
./vm-vagrant.sh up web-server              # Start custom VM
./vm-vagrant.sh ssh web-server             # SSH to custom VM
./vm-vagrant.sh destroy web-server         # Destroy custom VM
```

## VM Role Specifications

**Resource Allocation:**

*Production-Ready Roles:*
- **base**: 1GB RAM, 1 CPU - Minimal Ubuntu installation with development tools
- **docker**: 2GB RAM, 2 CPU - Docker runtime + docker-compose
- **observer**: 2GB RAM, 2 CPU - eBPF tools + monitoring stack (htop, bpftrace)

*Experimental Roles (use with caution):*
- **k8s**: 4GB RAM, 2 CPU - MicroK8s cluster (snap installation issues)
- **lxd**: 2GB RAM, 2 CPU - LXD + ZFS (snap timeout issues)
- **kata**: 4GB RAM, 2 CPU - Kata containers + Docker (creation timeout)
- **router**: 1GB RAM, 1 CPU - Virtual routing (provisioning timeout)
- **pfsense**: 2GB RAM, 2 CPU - Ubuntu-based firewall (heavy provisioning)

**Network Configuration:**
- Primary provider: libvirt with `vagrant-libvirt` management network
- Management network: `192.168.121.0/24` (SSH access)
- **🚀 Hybrid network**: `10.0.1.0/24` (VM-Container communication)
- **🔍 DNS service**: hostname.hybrid.local resolution between all components
- SSH access: Direct IP assignment via libvirt DHCP

## Dependencies

**Required:**
- Vagrant 2.4.9+
- vagrant-libvirt plugin (primary provider)
- libvirt/KVM support
- Sufficient system resources for multiple VMs (4GB+ RAM for production roles, 8GB+ if using experimental roles)

**Optional Fallback:**
- VirtualBox (when libvirt unavailable)
- vagrant-vbguest plugin (for VirtualBox)
