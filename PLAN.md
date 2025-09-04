# VM Lab Implementation Plan

## Overview
VM management project transitioning from custom QEMU/Packer-based system to Vagrant-libvirt approach while maintaining the same Makefile interface.

## Phase 1: Legacy System (Completed) ✅
### Task 1.1: Custom VM Management System ✅
- [x] ~~Created vm-manage.sh script with QEMU/KVM backend~~
- [x] ~~Implemented bridge networking with TAP interfaces~~
- [x] ~~Added role-specific VM provisioning (base, docker, k8s, lxd, kata, observer)~~
- [x] ~~Created comprehensive Makefile wrapper interface~~
- [x] ~~Integrated cloud-init for VM customization~~

## Phase 2: Vagrant Migration (Current Phase) 🔄
### Task 2.1: Vagrant-libvirt Foundation ⏳
- [ ] Install and configure vagrant-libvirt plugin
- [ ] Create multi-machine Vagrantfile supporting all VM roles:
  - base (Ubuntu 24.04)
  - docker (Docker host)
  - k8s (Kubernetes host) 
  - lxd (LXD container host)
  - kata (Kata containers host)
  - observer (monitoring/eBPF host)
- [ ] Configure libvirt provider settings (memory, CPU, networking)
- [ ] Implement role-specific provisioning scripts

### Task 2.2: Makefile Interface Preservation ⏳
- [ ] Update Makefile to use Vagrant commands instead of vm-manage.sh
- [ ] Maintain exact same command interface:
  - `make create-{role} [NAME=<name>]` → `vagrant up <name>`
  - `make start [NAME=<name>]` → `vagrant up <name>`
  - `make stop [NAME=<name>]` → `vagrant halt <name>`
  - `make ssh [NAME=<name>]` → `vagrant ssh <name>`
  - `make delete NAME=<name>` → `vagrant destroy <name>`
  - `make list` → `vagrant status`
- [ ] Add VM name handling and role-based VM creation
- [ ] Preserve all existing convenience targets (dev-vm, web-vm, etc.)

## Phase 3: Image Flow Management System
### Task 3.1: Smart Image Resolution ⏳
- [ ] Implement role-dedicated image preference system
  - When creating VMs, check for role-specific images first (e.g., ubuntu-24.04-docker)
  - Fall back to generic base images if role-specific images unavailable
  - Auto-build missing role images when requested
- [ ] Add image dependency tracking
  - Maintain mapping between VM roles and preferred image names
  - Validate image availability before VM operations
- [ ] Create image build queue system
  - Queue missing images for automatic background building
  - Show build progress and ETA to users

### Task 3.2: VM-to-Image Export System ⏳
- [ ] Implement `export` command in vm-manage.sh
  - `make export NAME=my-vm TARGET=my-custom-image`
  - Stop VM, create qcow2 snapshot, compress and store
  - Update image registry with new custom image
- [ ] Add export validation and cleanup
  - Verify export integrity
  - Clean up temporary files
  - Update image metadata and size information

### Task 3.3: Image Registry & Lifecycle ⏳
- [ ] Create image registry system
  - Track all available images with metadata (creation date, size, role, source)
  - Implement `make images` command to list all managed images
  - Add image validation and cleanup commands
- [ ] Ensure VM-image consistency
  - Verify all listed VMs have corresponding images available
  - Auto-clean orphaned images
  - Warn about missing dependencies

### Task 3.4: Role-Specific Image Templates ⏳
- [ ] Complete role-specific configurations:
  - LXD Host: lxd, bridge-utils, lxd-client
  - Kubernetes Host: kubeadm, kubectl, kubelet, containerd
  - Kata Host: kata-runtime, Docker with kata configuration
  - Observer Host: monitoring tools, eBPF utilities
- [ ] Implement image inheritance system
  - Base image → Role image → Custom image hierarchy
  - Efficient layered building to minimize duplication

## Phase 4: Advanced VM Operations
### Task 4.1: VM Lifecycle Enhancement
- [ ] Add VM templates and cloning
  - Create VMs from templates with predefined configurations
  - Clone existing VMs with customization options
- [ ] Implement VM snapshots
  - Create, list, restore, and delete VM snapshots
  - Integrate with image export system

### Task 4.2: Multi-VM Management  
- [ ] Add VM groups and batch operations
  - Start/stop/manage multiple VMs simultaneously
  - Create VM environments (e.g., k8s cluster = 3 VMs)
- [ ] Implement resource management
  - Track CPU, memory, disk usage across VMs
  - Prevent resource over-allocation

## Phase 5: Integration & Testing
### Task 5.1: Image Flow Integration Testing
- [ ] Test complete image flow scenarios:
  - Create VM with auto-building missing role images
  - Export running VM to custom image
  - Create new VM from exported custom image
- [ ] Validate image consistency and registry accuracy
- [ ] Test role-specific functionality in generated images

### Task 5.2: Performance & Reliability
- [ ] Optimize image building and VM operations performance
- [ ] Add comprehensive error recovery mechanisms
- [ ] Implement progress reporting and logging systems

## Phase 6: Documentation & Production Readiness
### Task 6.1: Documentation Updates
- [ ] Update CLAUDE.md with complete image flow procedures
- [ ] Document all VM and image management commands
- [ ] Create troubleshooting guide for common scenarios

### Task 6.2: Production Polish
- [ ] Add configuration validation and health checks
- [ ] Implement backup and recovery procedures for image registry
- [ ] Add monitoring and alerting for long-running operations

## Prerequisites & Dependencies
- QEMU/KVM virtualization support
- Packer binary installation
- Ubuntu 24.04 Server ISO (will be downloaded)
- Sufficient disk space for build artifacts (~150GB recommended)
- Internet connectivity for package downloads

## Command Summary
```bash
# VM Management
make create-docker NAME=web-server    # Create role-specific VM
make start NAME=web-server            # Start VM with validation
make ssh NAME=web-server              # SSH with auto port detection
make stop NAME=web-server             # Stop VM safely
make delete NAME=web-server           # Delete VM with confirmation

# Image Management (Phase 3)
make images                          # List all managed images
make export NAME=my-vm TARGET=my-image  # Export VM to custom image
make build ROLE=docker               # Build role-specific image

# Advanced Operations (Phase 4)
make clone SOURCE=template TARGET=new-vm  # Clone VM
make snapshot NAME=vm ACTION=create   # VM snapshot management
```

## Expected Deliverables
- Complete VM lifecycle management system
- Smart image flow with auto-building and exports
- Role-specific image templates and inheritance
- Image registry with metadata tracking
- Advanced VM operations (cloning, snapshots, batch management)
- Production-ready tooling with comprehensive error handling