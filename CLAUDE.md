# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modern VM management system using Vagrant-libvirt for provisioning Ubuntu 24.04 VMs with different roles:

- Base Ubuntu (minimal installation)
- LXD host (container platform)
- Docker host (container runtime)
- Kubernetes host (microk8s cluster)
- Kata host (secure containers)
- Observer host (monitoring with eBPF/Prometheus/Grafana)
- Router (virtual networking)
- pfSense-style (Ubuntu-based firewall/gateway)

## Current Architecture

**Vagrant-libvirt Based System:**

- Primary provider: libvirt (KVM virtualization)
- Fallback provider: VirtualBox (when libvirt unavailable)
- Multi-machine Vagrantfile with 8 predefined VM roles
- Custom VM support with isolated directories and templates
- Unified Makefile interface for all operations

## Project Structure

```text
vm-lab/
├── Vagrantfile              # Multi-machine VM definitions (8 roles)
├── vm-vagrant.sh           # Vagrant wrapper for custom VMs  
├── Makefile                # Unified VM management interface
├── templates/              # Vagrantfile templates for custom VMs
├── vms/                    # Isolated custom VM directories
└── README.md               # Project documentation
```

## VM Management Commands

**Makefile Interface (Recommended):**
```bash
# VM Creation (predefined roles)
make create-base [NAME=<name>]     # Create base Ubuntu VM
make create-docker [NAME=<name>]   # Create Docker host VM
make create-k8s [NAME=<name>]      # Create Kubernetes host VM
make create-lxd [NAME=<name>]      # Create LXD host VM
make create-kata [NAME=<name>]     # Create Kata host VM
make create-observer [NAME=<name>] # Create Observer host VM
make create-router [NAME=<name>]   # Create Virtual Router VM  
make create-pfsense [NAME=<name>]  # Create pfSense-style VM

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
- **base**: 1GB RAM, 1 CPU - Minimal Ubuntu installation
- **docker**: 2GB RAM, 2 CPU - Docker runtime + docker-compose
- **k8s**: 4GB RAM, 2 CPU - MicroK8s cluster ready
- **lxd**: 2GB RAM, 2 CPU - LXD + ZFS + monitoring
- **kata**: 4GB RAM, 2 CPU - Kata containers + Docker
- **observer**: 2GB RAM, 2 CPU - eBPF tools + monitoring stack
- **router**: 1GB RAM, 1 CPU - Virtual routing (Bird2, FRR, etc.)
- **pfsense**: 2GB RAM, 2 CPU - Ubuntu-based firewall/gateway

**Network Configuration:**
- Primary provider: libvirt with `vagrant-libvirt` management network
- Network range: `192.168.121.0/24` (default vagrant-libvirt)
- SSH access: Direct IP assignment via libvirt DHCP

## Dependencies

**Required:**
- Vagrant 2.4.9+
- vagrant-libvirt plugin (primary provider)
- libvirt/KVM support
- Sufficient system resources for multiple VMs (8GB+ RAM recommended)

**Optional Fallback:**
- VirtualBox (when libvirt unavailable)
- vagrant-vbguest plugin (for VirtualBox)
