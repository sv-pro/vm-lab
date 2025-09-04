# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a VM management project transitioning from custom QEMU/Packer-based image building to Vagrant-based VM provisioning for Ubuntu 24.04 VMs with different roles:
- LXD host
- Docker host 
- Kubernetes host
- Kata host
- Observer host (monitoring/experiments with eBPF/Prometheus/Grafana)

## Architecture Transition

**Previous Approach (QEMU/Packer):**
- Custom vm-manage.sh script for VM lifecycle management
- Packer templates for building role-specific qcow2 images
- Manual image building and VM provisioning

**Current Approach (Vagrant):**
- Vagrant for VM provisioning and lifecycle management
- Multi-machine Vagrantfile supporting all VM roles
- Declarative VM configuration with automatic provisioning
- Provider flexibility (VirtualBox, libvirt, etc.)

## Current Project Structure

```
vm-lab/
├── Vagrantfile              # Multi-machine VM definitions
├── packer/                  # Legacy Packer configs (may be removed)
├── output/                  # VM artifacts and images
├── vm-manage.sh            # Legacy VM management script
└── Makefile                # Build automation
```

## Vagrant Commands

Basic VM operations:
```bash
# Start all VMs
vagrant up

# Start specific VM role
vagrant up docker
vagrant up k8s
vagrant up lxd
vagrant up kata
vagrant up observer

# SSH into VMs
vagrant ssh docker
vagrant ssh k8s

# Stop VMs
vagrant halt
vagrant halt docker

# Destroy VMs
vagrant destroy
vagrant destroy docker

# Check VM status
vagrant status
```

## VM Role Configurations

Each VM role should be configured in the Vagrantfile with:
- Role-specific provisioning scripts
- Appropriate resource allocation (CPU, memory, disk)
- Network configuration
- Port forwarding as needed
- Role-specific package installation

## Dependencies

- Vagrant 2.4.9+ 
- VirtualBox or libvirt provider
- Sufficient system resources for multiple VMs