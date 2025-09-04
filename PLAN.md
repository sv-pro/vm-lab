# VM Lab Implementation Plan

## Overview
Build infrastructure for generating Ubuntu 24.04 qcow2 images for 5 specialized roles using QEMU and Packer.

## Phase 1: Project Foundation ✅
### Task 1.1: Directory Structure Setup ✅
- [x] ~~Create `vm-images/` root directory~~
- [x] ~~Create `vm-images/packer/` directory for Packer templates and values~~
- [x] ~~Create `vm-images/output/` directory for generated qcow2 images~~
- [x] ~~Add `.gitignore` entries for output directory and temporary files~~

### Task 1.2: Ubuntu ISO Configuration ✅
- [x] ~~Research and identify Ubuntu 24.04 server ISO download URL~~
- [x] ~~Generate/obtain SHA256 checksum for the ISO~~
- [x] ~~Create base configuration with ISO details~~

## Phase 2: VM Management Infrastructure ✅
### Task 2.1: Core VM Management ✅
- [x] ~~Restructure project layout (move vm-images/ to root)~~
- [x] ~~Create comprehensive vm-manage.sh script with:~~
  - VM creation with name conflict resolution
  - VM lifecycle management (start/stop with validation)
  - SSH integration with auto port detection
  - VM deletion with safety checks
- [x] ~~Add Makefile wrapper for all vm-manage.sh operations~~
- [x] ~~Implement hostname customization (VM name becomes system hostname)~~
- [x] ~~Enable dual authentication (SSH keys + password login)~~
- [x] ~~Fix Docker installation configuration~~
- [x] ~~Add comprehensive error handling and user feedback~~

### Task 2.2: Cloud Image Template ✅
- [x] ~~Switch to cloud-init based approach using Ubuntu cloud images~~
- [x] ~~Create `packer/ubuntu-cloud-base.pkr.hcl` template~~
- [x] ~~Implement role-specific configurations (Docker, K8s, LXD, etc.)~~
- [x] ~~Add SSH key management and cloud-init user-data templates~~
- [x] ~~Test and validate VM creation and management~~

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