# Hybrid Networking Implementation Tasks

## Overview
Implementation of Docker + VM hybrid networking for VM Lab, allowing Docker containers and VMs to communicate on the same network subnets.

## Phase 1: Research & Discovery

### 1.1 Network Architecture Research
- [ ] **Investigate libvirt bridge networking details**
  - Current vagrant-libvirt network: `192.168.121.0/24`
  - Bridge interface: `virbr1` (typical vagrant-libvirt bridge)
  - DHCP range and static IP allocation methods
  
- [ ] **Research Docker bridge networking**
  - Default docker0 bridge: `172.17.0.0/16`
  - Custom bridge networks with docker-compose
  - Bridge driver configuration options
  
- [ ] **Analyze bridge-to-bridge connectivity**
  - Linux bridge linking mechanisms
  - iptables rules for bridge forwarding
  - Network namespace considerations

### 1.2 Current System Analysis
- [ ] **Document existing VM networking**
  - Map current libvirt network configuration
  - Document VM IP allocation patterns
  - Test inter-VM connectivity

- [ ] **Test Docker networking in current docker VMs**
  - Create test containers in docker VM role
  - Document default networking behavior
  - Test container-to-host connectivity

### 1.3 Technical Feasibility Study
- [ ] **Bridge integration experiments**
  - Create custom bridge network
  - Connect Docker containers to custom bridge
  - Connect libvirt VMs to same bridge
  - Test bidirectional connectivity

## Phase 2: Proof of Concept

### 2.1 Basic Hybrid Network
- [ ] **Create shared bridge network**
  - Define common subnet (e.g., `10.0.1.0/24`)
  - Configure bridge with proper routing
  - Ensure DHCP/static IP coordination

- [ ] **VM Integration**
  - Modify VM templates to use custom bridge
  - Test VM startup with new networking
  - Validate VM-to-VM communication

- [ ] **Docker Integration**
  - Create Docker custom network on shared bridge
  - Test container startup and networking
  - Validate container-to-container communication

### 2.2 Cross-Platform Connectivity
- [ ] **VM-to-Container Communication**
  - Test ping between VM and container
  - Test service discovery mechanisms
  - Document IP allocation conflicts

- [ ] **Container-to-VM Communication**
  - Test reverse connectivity
  - Validate port exposure and access
  - Test service mesh scenarios

## Phase 3: Implementation

### 3.1 Makefile Integration
- [ ] **Add hybrid networking commands**
  - `make create-hybrid-network` - Create shared bridge
  - `make hybrid-docker NAME=<name>` - Docker VM with hybrid networking
  - `make hybrid-base NAME=<name>` - Base VM with hybrid networking

### 3.2 Template Updates
- [ ] **Create hybrid VM templates**
  - `templates/Vagrantfile.hybrid-docker`
  - `templates/Vagrantfile.hybrid-base`
  - Configure bridge networking in templates

### 3.3 Docker Integration Scripts
- [ ] **Docker network management**
  - Scripts for creating shared Docker networks
  - Integration with VM bridge configuration
  - Automated IP range management

## Phase 4: Advanced Features

### 4.1 Service Discovery
- [ ] **DNS resolution between containers and VMs**
  - Implement custom DNS server or dnsmasq integration
  - Container hostname resolution from VMs
  - VM hostname resolution from containers

### 4.2 Network Policies
- [ ] **Security and isolation**
  - iptables rules for controlled access
  - Network segmentation options
  - Firewall integration

### 4.3 Monitoring and Debugging
- [ ] **Network troubleshooting tools**
  - Bridge status monitoring commands
  - Connectivity testing utilities
  - Network topology visualization

## Success Criteria

### Minimum Viable Implementation
- [ ] VMs and Docker containers can communicate on shared subnet
- [ ] IP address conflicts are avoided/managed
- [ ] Basic service connectivity (ping, TCP/UDP) works bidirectionally

### Production-Ready Implementation  
- [ ] Robust IP allocation without conflicts
- [ ] DNS resolution between containers and VMs
- [ ] Network policies for security
- [ ] Clear documentation and examples

## Research Questions

1. **Bridge Compatibility**: Can libvirt and Docker share the same Linux bridge reliably?
2. **IP Management**: How to prevent IP conflicts between libvirt DHCP and Docker DHCP?
3. **Performance Impact**: Does bridge-to-bridge routing introduce significant latency?
4. **Security Implications**: What are the isolation boundaries in shared networking?

## Implementation Notes

- Start with single-host implementation (local Docker + local VMs)
- Focus on reliability over performance initially
- Document all networking configurations for troubleshooting
- Test with production-ready VM roles (base, docker, observer)

## Timeline Estimate

- **Phase 1 (Research)**: 1-2 weeks
- **Phase 2 (PoC)**: 1-2 weeks  
- **Phase 3 (Implementation)**: 2-3 weeks
- **Phase 4 (Advanced)**: 2-4 weeks

**Total: 6-11 weeks** for complete implementation