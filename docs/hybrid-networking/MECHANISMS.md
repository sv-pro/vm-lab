# Hybrid Networking: How It Works

This document explains the technical mechanisms, principles, and tools that power VM Lab's hybrid networking system.

## Overview

Hybrid networking allows VMs and Docker containers to communicate seamlessly on a shared network (10.0.1.0/24) with DNS service discovery, creating a unified infrastructure where containers and VMs can interact as if they were on the same physical network.

## Core Architecture

### Network Layer Stack
```
┌─────────────────────────────────────────────────────┐
│                  Application Layer                  │
│         VMs ←→ DNS ←→ Containers                    │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                  DNS Service Layer                  │
│    hostname.hybrid.local → IP Resolution           │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                Network Bridge Layer                 │
│         hybr0 Bridge (10.0.1.0/24)                 │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│              Virtualization Layer                  │
│    Docker veth pairs  │  libvirt vnet interfaces   │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                 Physical Layer                      │
│              Host Network Stack                     │
└─────────────────────────────────────────────────────┘
```

## Key Components

### 1. Linux Bridge (hybr0)
**Technology**: Linux kernel bridge
**Purpose**: Layer 2 switching between VMs and containers
**Configuration**:
- Bridge name: `hybr0`
- Network: `10.0.1.0/24`
- Gateway: `10.0.1.1` (bridge IP)

**How it works**:
```bash
# Created by host
ip link add name hybr0 type bridge
ip addr add 10.0.1.1/24 dev hybr0
ip link set hybr0 up

# Automatic forwarding table management
# Bridge learns MAC addresses and forwards frames intelligently
```

### 2. Docker Integration
**Technology**: Docker custom bridge networks
**Mechanism**: Docker creates veth pairs, connects one end to hybr0

```bash
# Docker network using existing bridge
docker network create \
    --driver bridge \
    --subnet=10.0.1.0/24 \
    --gateway=10.0.1.1 \
    --opt com.docker.network.bridge.name=hybr0 \
    hybrid-net
```

**Container connection process**:
1. Container created with `--network hybrid-net`
2. Docker creates veth pair (vethXXX ↔ container eth0)
3. Host end (vethXXX) attached to hybr0 bridge
4. Container gets IP from 10.0.1.0/24 subnet
5. Container can now communicate with anything on hybr0

### 3. libvirt VM Integration
**Technology**: libvirt bridge mode networking
**Mechanism**: VM gets second network interface connected to hybr0

```xml
<!-- libvirt network definition -->
<network>
  <name>hybrid-network</name>
  <forward mode='bridge'/>
  <bridge name='hybr0'/>
</network>
```

**VM connection process**:
1. VM defined with two network interfaces:
   - eth0: Management network (192.168.121.x) for SSH
   - eth1: Hybrid network (10.0.1.x) for container communication
2. libvirt creates vnet interface (vnetXX)
3. vnet interface attached to hybr0 bridge
4. VM's eth1 configured with static IP via netplan

### 4. DNS Service Discovery
**Technology**: dnsmasq running in Docker container
**Purpose**: Hostname resolution between VMs and containers

#### DNS Container Setup
```bash
# DNS server container on hybrid network
docker run -d \
    --name hybrid-dns \
    --network hybrid-net \
    --ip 10.0.1.2 \
    --cap-add=NET_ADMIN \
    strm/dnsmasq
```

#### DNS Configuration
```bash
# dnsmasq.conf
domain=hybrid.local
expand-hosts
server=8.8.8.8        # Upstream DNS
listen-address=10.0.1.2
bind-interfaces
```

#### Dynamic Host Records
```bash
# /etc/hosts format in DNS container
10.0.1.1   gateway gateway.hybrid.local
10.0.1.2   dns dns.hybrid.local hybrid-dns
10.0.1.50  test-container test-container.hybrid.local
10.0.1.100 web-server web-server.hybrid.local
```

## Modern Linux Networking Tools

### netplan
**Role**: Network configuration management
**Why important**: Declarative, hot-reloadable network config

```yaml
# /etc/netplan/60-hybrid-network.yaml
network:
  version: 2
  ethernets:
    eth1:                          # Hybrid network interface
      addresses:
        - 10.0.1.10/24            # Static IP assignment
      nameservers:
        addresses:
          - 10.0.1.2              # Hybrid DNS server
          - 8.8.8.8               # Fallback DNS
        search:
          - hybrid.local          # Search domain
```

**Process**:
1. `netplan apply` reads YAML config
2. Generates systemd-networkd configuration
3. systemd-networkd applies settings to interfaces
4. systemd-resolved updates DNS configuration
5. Changes take effect immediately (no reboot)

### systemd-resolved
**Role**: Modern DNS resolution with per-interface configuration
**Why crucial**: Enables split DNS for hybrid networking

**Key features**:
- **Per-interface DNS**: Different interfaces use different DNS servers
- **Domain routing**: `.hybrid.local` queries → hybrid DNS (10.0.1.2)
- **DNS caching**: Improves performance and reduces DNS traffic
- **Stub resolver**: Manages `/etc/resolv.conf` transparently

**Configuration flow**:
```bash
# Netplan → systemd-networkd → systemd-resolved
netplan apply
↓
systemd-networkd configures eth1
↓
systemd-resolved learns: eth1 uses 10.0.1.2 for hybrid.local
↓
Application queries test-container.hybrid.local
↓
systemd-resolved routes query to 10.0.1.2
↓
dnsmasq responds with 10.0.1.50
```

### resolvectl
**Role**: Control and debug systemd-resolved
**Essential commands**:

```bash
# View current DNS configuration
resolvectl status

# Configure DNS server for specific interface
resolvectl dns eth1 10.0.1.2

# Configure domain routing
resolvectl domain eth1 hybrid.local

# Flush DNS cache
resolvectl flush-caches

# Query specific DNS server
resolvectl query test-container.hybrid.local
```

## Packet Flow Examples

### VM → Container Communication
```
1. VM application: ping test-container.hybrid.local
2. systemd-resolved: Query 10.0.1.2 for test-container.hybrid.local
3. DNS response: 10.0.1.50
4. VM eth1 (10.0.1.10) → hybr0 → container eth0 (10.0.1.50)
5. ICMP packet flow over layer 2 bridge
6. Container responds: eth0 → hybr0 → VM eth1
```

### Container → VM Communication
```
1. Container: curl http://database-vm.hybrid.local
2. Container DNS (via Docker): Query 10.0.1.2
3. DNS response: 10.0.1.200
4. Container eth0 (10.0.1.100) → hybr0 → VM eth1 (10.0.1.200)
5. VM application responds via same bridge path
```

## Security and Isolation

### Network Isolation
- Hybrid network (10.0.1.0/24) completely isolated from:
  - Docker default networks (172.x.x.x)
  - libvirt management network (192.168.121.x)
  - Host networks
  - Other VM networks

### DNS Security
- DNS queries for .hybrid.local stay within hybrid network
- External DNS queries use fallback servers (8.8.8.8)
- No DNS leakage between network domains

### Firewall Integration
```bash
# iptables rules (automatically managed)
ACCEPT all -- * hybr0 ctstate RELATED,ESTABLISHED
ACCEPT all -- hybr0 !hybr0 
ACCEPT all -- hybr0 hybr0
```

## Performance Characteristics

### Latency
- VM ↔ Container: 0.2-0.6ms (excellent)
- DNS resolution: <1ms (cached)
- Bridge forwarding: Hardware-accelerated (kernel space)

### Throughput
- Limited by bridge capacity: ~10Gbps+ (modern kernels)
- No virtualization overhead for layer 2 switching
- Near-native performance for container networking

### Scalability
- Bridge supports 1024 interfaces by default
- DNS server handles thousands of queries/sec
- Memory usage: ~5MB per VM, ~2MB per container

## Troubleshooting Tools

### Network Diagnostics
```bash
# Bridge status
ip addr show hybr0
brctl show hybr0              # or: bridge link show

# Bridge forwarding table
brctl showmacs hybr0          # or: bridge fdb show br hybr0

# Network connectivity
ping 10.0.1.1                # Gateway connectivity
nmap -sn 10.0.1.0/24         # Network discovery
```

### DNS Diagnostics
```bash
# Direct DNS queries
nslookup container.hybrid.local 10.0.1.2
dig @10.0.1.2 vm.hybrid.local

# systemd-resolved status
resolvectl status eth1
resolvectl query test.hybrid.local
```

### Container Diagnostics
```bash
# Docker network inspection
docker network inspect hybrid-net
docker exec container ip addr show

# Container connectivity
docker exec container ping 10.0.1.1
docker exec container nslookup vm.hybrid.local
```

## Advanced Features

### Automatic IP Management
- Static IP assignment prevents conflicts
- IP range coordination between Docker and libvirt
- Persistent IP allocation across restarts

### Service Discovery Integration
- Containers automatically registered in DNS
- VM hostname resolution
- Dynamic DNS record updates

### Hot Configuration
- Network changes apply immediately
- No service restarts required
- Zero-downtime configuration updates

## Comparison with Alternatives

### vs Docker Compose Networks
- **Advantage**: VM integration, cross-platform communication
- **Use case**: When you need VMs and containers together

### vs Kubernetes Networking
- **Advantage**: Simpler setup, direct VM integration
- **Use case**: Development environments, hybrid infrastructure

### vs Traditional VPN
- **Advantage**: No encryption overhead, native performance
- **Use case**: Local development, testing environments

## Future Enhancements

### Potential Improvements
- IPv6 support for dual-stack networking
- Network policies for fine-grained access control  
- Integration with service mesh technologies
- Load balancing and high availability features
- Monitoring and metrics collection
- Multi-host networking with VXLAN/overlay networks

### Technology Evolution
- Integration with newer networking standards
- Container runtime agnostic design
- Cloud-native orchestration support
- Enhanced security with micro-segmentation

## Conclusion

VM Lab's hybrid networking represents a significant advancement in local development infrastructure, combining the simplicity of Linux bridges with modern DNS service discovery to create a seamless development environment where VMs and containers coexist naturally.

The system leverages mature, well-tested Linux networking technologies while incorporating modern tools like systemd-resolved and netplan for configuration management. This results in a robust, performant, and maintainable networking solution that bridges the gap between traditional virtualization and container orchestration platforms.