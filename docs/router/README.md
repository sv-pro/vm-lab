# Virtual Router Documentation

This directory contains comprehensive documentation for the VM Lab Virtual Router, a Linux-based software router built on Ubuntu 24.04 with enterprise-grade routing capabilities.

## Documentation Structure

### 📖 Quick Start
- **[Quick Start Guide](quickstart/README.md)** - Get your router running in 5 minutes
- **[Basic Configuration](quickstart/basic-config.md)** - Essential setup steps
- **[Network Interfaces](quickstart/interfaces.md)** - Configure network connections

### 📚 Tutorials
- **[BGP Configuration](tutorials/bgp.md)** - Border Gateway Protocol setup
- **[OSPF Setup](tutorials/ospf.md)** - Dynamic routing with OSPF
- **[VPN Configuration](tutorials/vpn.md)** - Site-to-site and remote access VPNs
- **[Load Balancing](tutorials/load-balancing.md)** - HAProxy and traffic distribution
- **[Firewall Rules](tutorials/firewall.md)** - iptables and security policies

### 🏗️ Examples
- **[Network Lab Scenarios](examples/lab-scenarios.md)** - Real-world network topologies
- **[Multi-Router Setup](examples/multi-router.md)** - Creating complex networks
- **[Service Provider Edge](examples/sp-edge.md)** - ISP-style configurations

### 📋 Reference
- **[Command Reference](reference/commands.md)** - Complete command listing
- **[Configuration Files](reference/config-files.md)** - File locations and formats
- **[Troubleshooting](reference/troubleshooting.md)** - Common issues and solutions

## Router Capabilities

### Routing Protocols
- **BGP** - Internet routing and peering
- **OSPF** - Enterprise internal routing  
- **Static Routes** - Manual route configuration
- **Policy Routing** - Advanced traffic engineering

### Network Services
- **NAT/PAT** - Network address translation
- **DHCP** - Dynamic IP assignment
- **DNS** - Domain name resolution
- **VPN** - IPSec and OpenVPN tunnels

### Load Balancing & HA
- **HAProxy** - Layer 4/7 load balancing
- **Keepalived** - VRRP high availability
- **Traffic Shaping** - Bandwidth management

### Security Features
- **iptables** - Stateful firewall
- **IPSec** - Encrypted tunnels
- **Access Control** - Network policies
- **Monitoring** - Traffic analysis

## Getting Started

1. **Deploy Router VM:**
   ```bash
   make create-router NAME=gateway
   make ssh NAME=gateway
   ```

2. **Follow Quick Start Guide:** [quickstart/README.md](quickstart/README.md)

3. **Choose Your Use Case:**
   - Enterprise networking → [OSPF Tutorial](tutorials/ospf.md)
   - Internet connectivity → [BGP Tutorial](tutorials/bgp.md) 
   - Remote access → [VPN Tutorial](tutorials/vpn.md)
   - Load balancing → [HAProxy Tutorial](tutorials/load-balancing.md)

## Support

- **Issues:** Report problems in the main repository
- **Discussions:** Network configuration questions
- **Contributions:** Documentation improvements welcome

---

*Virtual Router powered by FRRouting, BIRD2, and Linux networking stack*