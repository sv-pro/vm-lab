# Networking Tools Reference Guide

A comprehensive reference for the networking tools used in VM Lab's hybrid infrastructure. From basic network troubleshooting to advanced eBPF monitoring.

## Quick Reference Table

| Tool | Purpose | Skill Level | VM Lab Usage |
|------|---------|-------------|--------------|
| `ping` | Basic connectivity test | Beginner | Test VM↔Container communication |
| `nslookup` | DNS resolution testing | Beginner | Test .hybrid.local domains |
| `ip` | Network interface management | Intermediate | Configure bridge interfaces |
| `netplan` | Network configuration | Intermediate | VM network setup |
| `systemd-resolved` | Modern DNS resolution | Intermediate | Split DNS configuration |
| `resolvectl` | DNS resolver control | Intermediate | Domain routing setup |
| `dig` | Advanced DNS queries | Intermediate | DNS server testing |
| `nmap` | Network discovery/scanning | Intermediate | Find hybrid network devices |
| `iptables` | Firewall configuration | Advanced | Bridge traffic rules |
| `brctl` | Bridge management | Advanced | Bridge status and MAC tables |
| `virsh` | Libvirt virtualization | Advanced | VM network configuration |
| `bpftrace` | eBPF system tracing | Expert | Network monitoring |

---

## Basic Connectivity Tools

### ping - Network Connectivity Testing
**Purpose**: Test network reachability and latency  
**Skill Level**: Beginner  

```bash
# Basic connectivity test
ping 10.0.1.1                           # Test gateway
ping 10.0.1.2                           # Test DNS server
ping test-container.hybrid.local         # Test DNS resolution

# Advanced options
ping -c 3 10.0.1.50                     # Send only 3 packets
ping -W 1 10.0.1.100                    # 1 second timeout
ping -i 0.2 10.0.1.1                    # 200ms interval (faster)
```

**VM Lab Examples**:
```bash
# Test hybrid networking from VM
ping 10.0.1.1                           # Gateway connectivity
ping test-container.hybrid.local         # DNS + container connectivity

# Test from container
docker exec test-container ping 10.0.1.10  # VM connectivity
```

**Common Issues**:
- No response = Network/firewall issue
- "Name or service not known" = DNS issue
- High latency = Performance issue

---

## DNS Tools

### nslookup - Basic DNS Resolution
**Purpose**: Query DNS servers directly  
**Skill Level**: Beginner  

```bash
# Basic DNS lookup
nslookup google.com                      # Use system DNS
nslookup test-container.hybrid.local     # Use system DNS for hybrid domain

# Query specific DNS server
nslookup google.com 8.8.8.8            # Use Google DNS
nslookup test-container.hybrid.local 10.0.1.2  # Use hybrid DNS

# Interactive mode
nslookup
> server 10.0.1.2                       # Set DNS server
> test-container.hybrid.local            # Query domain
> exit
```

**VM Lab Examples**:
```bash
# Test hybrid DNS resolution
nslookup gateway.hybrid.local 10.0.1.2
nslookup dns.hybrid.local 10.0.1.2
nslookup test-container.hybrid.local 10.0.1.2
```

### dig - Advanced DNS Queries
**Purpose**: Detailed DNS information and debugging  
**Skill Level**: Intermediate  

```bash
# Basic queries
dig google.com                           # A record lookup
dig google.com MX                        # Mail server lookup
dig google.com NS                        # Name server lookup

# Query specific DNS server
dig @10.0.1.2 test-container.hybrid.local
dig @8.8.8.8 google.com

# Detailed output
dig +trace google.com                    # Show full resolution path
dig +short google.com                    # Only show IP address
dig +noall +answer google.com            # Clean output format
```

**VM Lab Examples**:
```bash
# Test hybrid DNS server
dig @10.0.1.2 gateway.hybrid.local
dig @10.0.1.2 test-container.hybrid.local

# Compare with external DNS
dig @8.8.8.8 google.com
dig @10.0.1.2 google.com                 # Should forward to 8.8.8.8
```

**Advanced Features**:
```bash
# Reverse DNS lookup
dig -x 10.0.1.2                         # PTR record for IP

# Query all records
dig test-container.hybrid.local ANY

# DNS server performance test
time dig @10.0.1.2 gateway.hybrid.local
```

---

## Modern Network Configuration

### ip - Network Interface Management
**Purpose**: Configure and display network interfaces  
**Skill Level**: Intermediate  

```bash
# Show interfaces
ip addr show                             # All interfaces
ip addr show eth1                        # Specific interface
ip -4 addr show                          # IPv4 only
ip -br addr show                         # Brief format

# Show routing
ip route show                            # Routing table
ip route show table all                  # All routing tables
ip route get 10.0.1.1                   # Route to specific IP

# Show neighbors (ARP table)
ip neigh show                            # ARP entries
ip neigh show dev eth1                   # ARP for specific interface
```

**VM Lab Examples**:
```bash
# Check hybrid network interface
ip addr show eth1                        # VM hybrid interface
ip route show | grep 10.0.1             # Hybrid network routes

# Bridge interface on host
ip addr show hybr0                       # Bridge configuration
ip route show dev hybr0                  # Bridge routes
```

**Interface Configuration** (usually done via netplan):
```bash
# Temporary configuration (lost on reboot)
sudo ip addr add 10.0.1.100/24 dev eth1
sudo ip link set eth1 up
sudo ip route add 10.0.1.0/24 dev eth1
```

### netplan - Declarative Network Configuration  
**Purpose**: Modern Ubuntu network configuration  
**Skill Level**: Intermediate  

**Configuration Files**: `/etc/netplan/*.yaml`

```yaml
# Example: /etc/netplan/60-hybrid-network.yaml
network:
  version: 2
  ethernets:
    eth1:                                # Interface name
      addresses:
        - 10.0.1.10/24                  # Static IP
      routes:
        - to: 10.0.1.0/24               # Route definition
          via: 10.0.1.1                 # Gateway
      nameservers:
        addresses:
          - 10.0.1.2                    # DNS servers
          - 8.8.8.8
        search:
          - hybrid.local                 # Search domains
```

**Commands**:
```bash
# Apply configuration
sudo netplan apply                       # Apply all configs
sudo netplan --debug apply              # Debug mode

# Validate configuration
sudo netplan try                         # Test config (auto-rollback)
netplan get                             # Show current config
netplan status                          # Show interface status
```

**VM Lab Usage**:
- VM templates use netplan for hybrid network configuration
- Configures eth1 interface with static IP
- Sets up DNS servers and search domains
- Enables hot-reloadable network changes

### systemd-resolved - Modern DNS Resolution
**Purpose**: DNS resolver with per-interface configuration  
**Skill Level**: Intermediate  

**Key Features**:
- Per-interface DNS servers
- Split DNS (different domains → different servers)
- DNS caching
- DNSSEC validation

**Configuration**: Managed by systemd-networkd (via netplan)

```bash
# Show resolver status
systemd-resolve --status                 # Overall status
systemd-resolve --status eth1           # Interface-specific status

# DNS cache operations
systemd-resolve --flush-caches          # Clear DNS cache
systemd-resolve --statistics            # Cache statistics

# Query testing
systemd-resolve --resolve=google.com    # Test resolution
systemd-resolve --resolve=test-container.hybrid.local
```

**VM Lab Integration**:
- Routes `.hybrid.local` queries to 10.0.1.2
- Routes other domains to upstream DNS (8.8.8.8)
- Provides seamless DNS experience in VMs

### resolvectl - DNS Resolver Control
**Purpose**: Control and debug systemd-resolved  
**Skill Level**: Intermediate  

```bash
# Show current status
resolvectl status                        # All interfaces
resolvectl status eth1                   # Specific interface

# Configure DNS (temporary)
resolvectl dns eth1 10.0.1.2           # Set DNS server
resolvectl domain eth1 hybrid.local     # Set search domain
resolvectl default-route eth1 false     # Disable default routing

# Query operations
resolvectl query google.com              # Resolve domain
resolvectl query test-container.hybrid.local
resolvectl query --type=MX google.com   # Specific record type

# Cache operations
resolvectl flush-caches                  # Clear cache
resolvectl reset-statistics             # Reset stats
```

**VM Lab Examples**:
```bash
# Check hybrid DNS configuration
resolvectl status eth1                   # Should show 10.0.1.2 DNS server
resolvectl query test-container.hybrid.local

# Debug DNS issues
resolvectl query --verbose test-container.hybrid.local
```

---

## Network Discovery & Analysis

### nmap - Network Discovery and Security Scanning
**Purpose**: Network discovery, port scanning, service detection  
**Skill Level**: Intermediate  

```bash
# Network discovery
nmap -sn 10.0.1.0/24                    # Ping scan (find live hosts)
nmap -sn 192.168.121.0/24               # Scan management network

# Port scanning
nmap 10.0.1.2                           # Default port scan
nmap -p 53,80,443 10.0.1.2             # Specific ports
nmap -p- 10.0.1.2                      # All ports (slow)

# Service detection
nmap -sV 10.0.1.2                      # Version detection
nmap -sS 10.0.1.2                      # SYN scan (stealth)
nmap -A 10.0.1.2                       # Aggressive scan
```

**VM Lab Examples**:
```bash
# Discover hybrid network devices
nmap -sn 10.0.1.0/24

# Check DNS server services
nmap -p 53 10.0.1.2                    # DNS port
nmap -sV -p 53 10.0.1.2               # DNS service version

# Full network audit
nmap -A 10.0.1.0/24                   # All devices, all services
```

**Advanced Features**:
```bash
# OS detection
nmap -O 10.0.1.2                       # Operating system detection

# Script scanning
nmap --script=dns-brute 10.0.1.2       # DNS enumeration
nmap --script=http-enum 10.0.1.100     # HTTP service enumeration

# Output formats
nmap -oN scan.txt 10.0.1.0/24          # Normal output
nmap -oX scan.xml 10.0.1.0/24          # XML output
```

---

## Advanced Network Management

### iptables - Firewall Configuration
**Purpose**: Linux firewall and packet filtering  
**Skill Level**: Advanced  

```bash
# List current rules
iptables -L                              # All chains
iptables -L -v -n                       # Verbose with packet counts
iptables -t nat -L                      # NAT table

# Basic filtering rules
iptables -A INPUT -p tcp --dport 22 -j ACCEPT     # Allow SSH
iptables -A INPUT -p tcp --dport 53 -j ACCEPT     # Allow DNS TCP
iptables -A INPUT -p udp --dport 53 -j ACCEPT     # Allow DNS UDP

# Delete rules
iptables -D INPUT 1                      # Delete rule by number
iptables -F                              # Flush all rules (dangerous!)
```

**VM Lab Context**:
```bash
# Check bridge traffic rules (hybrid networking)
iptables -L FORWARD -v -n | grep hybr0

# Docker-generated rules for hybrid network
iptables -t nat -L | grep hybr0
```

**Common Bridge Rules**:
```bash
# Rules automatically created by Docker/libvirt for hybr0
ACCEPT all -- * hybr0 ctstate RELATED,ESTABLISHED
ACCEPT all -- hybr0 !hybr0 
ACCEPT all -- hybr0 hybr0
```

### brctl - Bridge Management (Legacy)
**Purpose**: Linux bridge configuration  
**Skill Level**: Advanced  

**Note**: `brctl` is legacy, modern systems use `ip` commands, but it's still useful for information display.

```bash
# Show bridges
brctl show                               # All bridges
brctl show hybr0                        # Specific bridge

# Show MAC address table (forwarding database)
brctl showmacs hybr0                    # Bridge forwarding table
brctl showstp hybr0                     # Spanning tree info

# Bridge configuration (usually done automatically)
brctl addbr mybr0                       # Create bridge
brctl addif mybr0 eth0                  # Add interface to bridge
brctl setfd mybr0 0                     # Set forward delay
```

**VM Lab Examples**:
```bash
# Check hybrid bridge status
brctl show hybr0                        # Shows connected interfaces
brctl showmacs hybr0                    # Shows learned MAC addresses
```

**Modern Equivalent (using ip commands)**:
```bash
# Modern bridge management
ip link show type bridge                # Show bridges
bridge fdb show br hybr0                # Show forwarding database
bridge link show                        # Show bridge ports
```

### virsh - Libvirt Virtualization Management
**Purpose**: Manage VMs and virtual networks  
**Skill Level**: Advanced  

```bash
# VM management
virsh list                               # Running VMs
virsh list --all                        # All VMs
virsh dominfo vm-name                   # VM information
virsh start vm-name                     # Start VM
virsh stop vm-name                      # Stop VM

# Network management
virsh net-list                          # Active networks
virsh net-list --all                    # All networks
virsh net-info hybrid-network           # Network details
virsh net-start hybrid-network          # Start network
virsh net-autostart hybrid-network      # Auto-start on boot

# VM network information
virsh domiflist vm-name                 # VM network interfaces
virsh domifaddr vm-name                 # VM IP addresses
```

**VM Lab Examples**:
```bash
# Check VM network configuration
virsh domiflist test-vm_default          # Should show eth0 + eth1
virsh domifaddr test-vm_default          # Show assigned IPs

# Check hybrid network
virsh net-list | grep hybrid-network     # Should be active
virsh net-dumpxml hybrid-network         # Network XML config
```

**Network Configuration**:
```bash
# Define network from XML
virsh net-define /tmp/network.xml
virsh net-start network-name
virsh net-autostart network-name

# Attach/detach interfaces
virsh attach-interface vm-name network hybrid-network
virsh detach-interface vm-name network hybrid-network
```

---

## eBPF and System Tracing

### bpftrace - eBPF Tracing Language
**Purpose**: Dynamic system tracing and performance analysis  
**Skill Level**: Expert  

**Basic Syntax**:
```bash
# One-liners
bpftrace -e 'BEGIN { printf("Hello World\n"); }'

# System call tracing
bpftrace -e 'tracepoint:syscalls:sys_enter_open { printf("%s opened %s\n", comm, str(args->filename)); }'

# Network tracing
bpftrace -e 'tracepoint:net:net_dev_xmit { printf("TX: %s %d bytes\n", comm, args->len); }'
```

**VM Lab DNS Monitoring Examples**:
```bash
# Simple process monitoring
bpftrace -e 'tracepoint:syscalls:sys_enter_openat /str(args->filename) =~ /resolv/ { printf("DNS config access: %s\n", comm); }'

# Network packet monitoring
bpftrace -e 'tracepoint:net:net_dev_xmit /args->len > 20 && args->len < 512/ { printf("Packet: %d bytes\n", args->len); }'
```

**Useful Probes**:
```bash
# Available tracepoints
bpftrace -l 'tracepoint:syscalls:*' | head -10
bpftrace -l 'tracepoint:net:*'

# Kprobes (kernel functions)
bpftrace -l 'kprobe:*tcp*' | head -10

# Uprobes (userspace functions)
bpftrace -l 'uprobe:/bin/bash:*' | head -10
```

**Script Examples**:
```bash
# DNS query monitoring script
#!/usr/bin/env bpftrace
tracepoint:syscalls:sys_enter_openat /str(args->filename) =~ /resolv/ {
    printf("🔍 DNS config: %s (PID %d) opened %s\n", 
           comm, pid, str(args->filename));
}
```

**Performance Monitoring**:
```bash
# CPU usage by process
bpftrace -e 'profile:hz:99 { @cpu[comm] = count(); }'

# Network I/O by process  
bpftrace -e 'tracepoint:net:net_dev_xmit { @bytes[comm] = sum(args->len); }'

# System call frequency
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @syscalls[comm] = count(); }'
```

---

## Troubleshooting Workflows

### Network Connectivity Issues
```bash
# 1. Basic connectivity
ping 10.0.1.1                           # Gateway reachable?
ping 8.8.8.8                            # Internet reachable?

# 2. Interface configuration
ip addr show                             # Interfaces configured?
ip route show                            # Routes correct?

# 3. DNS resolution
nslookup google.com                      # DNS working?
resolvectl status                        # DNS configuration?

# 4. Port/service testing
nmap -p 53 10.0.1.2                    # DNS server listening?
telnet 10.0.1.50 80                    # Service reachable?
```

### DNS Resolution Issues
```bash
# 1. Check system DNS configuration
resolvectl status                        # What DNS servers?
cat /etc/resolv.conf                    # Legacy DNS config

# 2. Test specific DNS servers
nslookup google.com 8.8.8.8            # External DNS works?
nslookup test.hybrid.local 10.0.1.2    # Hybrid DNS works?

# 3. Detailed DNS debugging
dig +trace google.com                   # Full resolution path
dig @10.0.1.2 test.hybrid.local        # Direct server query

# 4. DNS cache issues
resolvectl flush-caches                 # Clear DNS cache
systemctl restart systemd-resolved     # Restart DNS service
```

### Bridge/VM Networking Issues
```bash
# 1. Check bridge status
ip addr show hybr0                      # Bridge configured?
brctl show hybr0                        # Interfaces attached?

# 2. Check VM network interfaces
virsh domiflist vm-name                 # VM has interfaces?
virsh domifaddr vm-name                 # VM has IP addresses?

# 3. Check firewall rules
iptables -L FORWARD -v | grep hybr0     # Bridge traffic allowed?

# 4. Test connectivity step by step
ping 10.0.1.1                          # Host to bridge
ping 10.0.1.10                         # Host to VM
docker exec container ping 10.0.1.10   # Container to VM
```

### Performance Issues
```bash
# 1. Basic network performance
ping -c 10 10.0.1.50                   # Latency test
iperf3 -s (server) / iperf3 -c IP (client)  # Throughput test

# 2. System resource usage
htop                                     # CPU/memory usage
iotop                                    # Disk I/O usage
iftop -i hybr0                          # Network I/O by interface

# 3. Advanced monitoring with eBPF
bpftrace -e 'profile:hz:99 { @cpu[comm] = count(); }'  # CPU profiling
bpftrace -e 'tracepoint:net:net_dev_xmit { @net[comm] = sum(args->len); }'  # Network I/O
```

---

## Installation and Setup

### Tool Installation (Ubuntu/Debian)
```bash
# Basic networking tools (usually pre-installed)
sudo apt update
sudo apt install -y iputils-ping dnsutils net-tools

# Advanced networking tools
sudo apt install -y nmap iptables-persistent bridge-utils

# Modern networking tools
sudo apt install -y systemd-resolved netplan.io

# Virtualization tools
sudo apt install -y libvirt-clients libvirt-daemon-system

# eBPF tools
sudo apt install -y bpftrace linux-headers-$(uname -r)

# Optional: useful additions
sudo apt install -y tcpdump wireshark-common iperf3 iftop
```

### VM Lab Specific Setup
```bash
# Clone and setup VM Lab
git clone https://github.com/sv-pro/vm-lab.git
cd vm-lab

# Create hybrid networking infrastructure
make create-hybrid-network
make hybrid-enable-dns

# Test the setup
make hybrid-status
make demo-dns-monitor
```

---

## Quick Command Cheatsheet

| Task | Command | Example |
|------|---------|---------|
| **Test connectivity** | `ping <ip>` | `ping 10.0.1.1` |
| **DNS lookup** | `nslookup <domain> <server>` | `nslookup test.hybrid.local 10.0.1.2` |
| **Show interfaces** | `ip addr show` | `ip addr show eth1` |
| **Show routes** | `ip route show` | `ip route show dev hybr0` |
| **DNS status** | `resolvectl status` | `resolvectl status eth1` |
| **Network scan** | `nmap -sn <network>` | `nmap -sn 10.0.1.0/24` |
| **Bridge status** | `brctl show` | `brctl show hybr0` |
| **VM interfaces** | `virsh domiflist <vm>` | `virsh domiflist test-vm_default` |
| **DNS trace** | `bpftrace script.bt` | `bpftrace dns-monitor.bt` |
| **Apply network config** | `netplan apply` | `sudo netplan apply` |

---

## Conclusion

This reference covers the essential networking tools used in modern Linux systems and VM Lab's hybrid infrastructure. The tools are presented in order of complexity, from basic connectivity testing to advanced eBPF system tracing.

**Learning Path Recommendation**:
1. Start with basic tools: `ping`, `nslookup`, `ip addr`
2. Learn DNS tools: `dig`, `resolvectl`, `systemd-resolved`  
3. Master network discovery: `nmap`, `iptables`, `brctl`
4. Advance to virtualization: `virsh`, `netplan`
5. Expert level: `bpftrace` and eBPF monitoring

Each tool serves a specific purpose in the networking stack, and understanding them all provides comprehensive network troubleshooting and management capabilities for hybrid VM+Container environments.