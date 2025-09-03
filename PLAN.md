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

## Phase 2: Core Packer Template ✅
### Task 2.1: Main Template Creation ✅
- [x] ~~Create `vm-images/packer/ubuntu-custom.pkr.hcl` with:~~
  - ~~Packer plugin requirements (QEMU >= 1.0.0)~~
  - ~~Variable declarations (iso_url, iso_checksum, ssh credentials, disk_size, image_name, extra_packages, provision_inline)~~
  - ~~QEMU source configuration with proper boot commands~~
  - ~~Build block with shell provisioner~~
  - ~~Post-processor for file renaming~~
- [x] ~~Install Packer binary (v1.14.1)~~
- [x] ~~Create autoinstall HTTP configuration files~~

### Task 2.2: Base Configuration Testing 🔄
- [x] ~~Create minimal `values-base.hcl` for testing~~
- [x] ~~Validate Packer template syntax~~
- [x] ~~Test base image build process~~ (failed: SSH timeout after 25min)
- [x] ~~Fix autoinstall configuration issues~~
  - Fixed network config to use wildcard matching (`e*`)
  - Simplified storage layout (direct vs LVM)
  - Fixed boot commands and password hash
- [x] ~~Retry build with corrected configuration~~ (in progress: 7min waiting for SSH)
  - VM actively running with 28% CPU usage
  - Network and boot configuration working correctly
  - Build process much more stable than first attempt
- [ ] Complete SSH connection and provisioning (ongoing)
- [ ] Verify output qcow2 file generation

## Phase 3: Role-Specific Configurations
### Task 3.1: LXD Host Configuration
- [ ] Create `values-lxd.hcl` with:
  - Package list: lxd, zfsutils-linux, prometheus-node-exporter
  - LXD initialization commands
  - ZFS storage pool setup (if applicable)

### Task 3.2: Docker Host Configuration  
- [ ] Create `values-docker.hcl` with:
  - Package list: docker.io, docker-compose
  - Docker service enablement
  - User group configuration for docker access

### Task 3.3: Kubernetes Host Configuration
- [ ] Create `values-k8s.hcl` with:
  - Package list: snapd
  - MicroK8s installation via snap
  - User group configuration for microk8s
  - Increased disk size (30G)

### Task 3.4: Kata Containers Host Configuration
- [ ] Create `values-kata.hcl` with:
  - Package list: docker.io, qemu-system-x86, kata-runtime, kata-proxy, kata-shim
  - Docker daemon configuration for kata-runtime
  - Docker service enablement
  - Increased disk size (25G)

### Task 3.5: Observer Host Configuration
- [ ] Create `values-observer.hcl` with:
  - Package list: htop, iftop, nload, tcpdump, bpftrace, bpftool, bpfcc-tools, prometheus-node-exporter, grafana-agent
  - Monitoring tools configuration

## Phase 4: Build Automation & Scripts
### Task 4.1: Build Scripts
- [ ] Create `build-all.sh` script for building all images
- [ ] Create individual build scripts for each role
- [ ] Add error handling and logging
- [ ] Add build validation checks

### Task 4.2: Makefile Creation
- [ ] Create Makefile with targets for:
  - Individual role builds
  - Clean output directory
  - Validate all configurations
  - Build all images sequentially

## Phase 5: Testing & Validation
### Task 5.1: Image Testing
- [ ] Create QEMU test scripts to verify each image boots
- [ ] Validate installed packages for each role
- [ ] Test role-specific functionality:
  - LXD: Container creation
  - Docker: Container running
  - K8s: MicroK8s status
  - Kata: Runtime availability
  - Observer: Monitoring tools accessibility

### Task 5.2: CI/CD Preparation
- [ ] Create GitHub Actions workflow (optional)
- [ ] Document system requirements
- [ ] Create troubleshooting guide

## Phase 6: Documentation & Cleanup
### Task 6.1: Documentation Updates
- [ ] Update CLAUDE.md with build procedures
- [ ] Update TODO.md with completion status
- [ ] Create detailed README for vm-images directory

### Task 6.2: Final Validation
- [ ] Test complete build process from scratch
- [ ] Verify all 5 role images build successfully
- [ ] Clean up temporary files and optimize .gitignore

## Prerequisites & Dependencies
- QEMU/KVM virtualization support
- Packer binary installation
- Ubuntu 24.04 Server ISO (will be downloaded)
- Sufficient disk space for build artifacts (~150GB recommended)
- Internet connectivity for package downloads

## Build Commands Summary
```bash
# Individual builds
packer build -var-file=packer/values-lxd.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-docker.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-k8s.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-kata.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-observer.hcl packer/ubuntu-custom.pkr.hcl

# Automated build
./build-all.sh
# or
make all
```

## Expected Deliverables
- 5 specialized Ubuntu 24.04 qcow2 images
- Reusable Packer infrastructure
- Build automation scripts
- Comprehensive documentation