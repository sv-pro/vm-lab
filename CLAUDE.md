# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modern VM management system using Vagrant-libvirt for provisioning Ubuntu 24.04 VMs. Currently supports 3 production-ready VM roles:

**✅ Production-Ready Roles (Tested & Working):**
- Base Ubuntu (clean development environment)
- Docker host (container runtime with docker-compose)
- Observer host (monitoring with eBPF tools)

**Note:** Previously included additional roles (k8s, lxd, kata, router, pfsense) but they were removed due to reliability issues. Focus is now on providing 100% working VM roles.

## Current Architecture

**Vagrant-libvirt Based System:**

- Primary provider: libvirt (KVM virtualization)
- Fallback provider: VirtualBox (when libvirt unavailable)
- Multi-machine Vagrantfile with 3 predefined VM roles
- Custom VM support with isolated directories and templates
- Unified Makefile interface for all operations

## Project Structure

```text
vm-lab/
├── Vagrantfile              # Multi-machine VM definitions (3 roles)
├── vm-vagrant.sh           # Vagrant wrapper for custom VMs  
├── Makefile                # Unified VM management interface
├── templates/              # Vagrantfile templates for custom VMs
├── vms/                    # Isolated custom VM directories
└── README.md               # Project documentation
```

## VM Management Commands

**Makefile Interface (Recommended):**
```bash
# VM Creation (all production-ready and tested)
make create-base [NAME=<name>]     # Create base Ubuntu VM
make create-docker [NAME=<name>]   # Create Docker host VM  
make create-observer [NAME=<name>] # Create Observer host VM

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
- **base**: 1GB RAM, 1 CPU - Minimal Ubuntu installation with development tools
- **docker**: 2GB RAM, 2 CPU - Docker runtime + docker-compose
- **observer**: 2GB RAM, 2 CPU - eBPF tools + monitoring stack (htop, bpftrace)

**Network Configuration:**
- Primary provider: libvirt with `vagrant-libvirt` management network
- Network range: `192.168.121.0/24` (default vagrant-libvirt)
- SSH access: Direct IP assignment via libvirt DHCP

## Dependencies

**Required:**
- Vagrant 2.4.9+
- vagrant-libvirt plugin (primary provider)
- libvirt/KVM support
- Sufficient system resources for multiple VMs (4GB+ RAM recommended for all 3 roles)

**Optional Fallback:**
- VirtualBox (when libvirt unavailable)
- vagrant-vbguest plugin (for VirtualBox)
