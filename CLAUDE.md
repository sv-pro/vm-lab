# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a VM image build project using QEMU and Packer to create Ubuntu 24.04 qcow2 images for different roles:
- LXD host
- Docker host 
- Kubernetes host
- Kata host
- Observer host (monitoring/experiments with eBPF/Prometheus/Grafana)

## Architecture

The project uses a template-based approach with:
- Single universal Packer template: `vm-images/packer/ubuntu-custom.pkr.hcl`
- Role-specific values files: `vm-images/packer/values-{role}.hcl`
- Generated images stored in: `vm-images/output/`

The template uses variables for customization:
- `extra_packages`: List of packages to install for each role
- `provision_inline`: Custom shell commands for role-specific configuration
- `image_name`, `disk_size`: Image configuration

## Build Commands

Build individual role images:
```bash
packer build -var-file=packer/values-lxd.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-docker.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-k8s.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-kata.hcl packer/ubuntu-custom.pkr.hcl
packer build -var-file=packer/values-observer.hcl packer/ubuntu-custom.pkr.hcl
```

All builds are executed from the repository root directory.

## Project Structure

The current implementation is planned but not yet created. All files should be created under the `vm-images/` directory structure as outlined in TODO.md:154.

## Dependencies

- Packer (HashiCorp Packer with QEMU plugin)
- QEMU/KVM for virtualization
- Ubuntu 24.04 ISO image (specified via iso_url and iso_checksum variables)