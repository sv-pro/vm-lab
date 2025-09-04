# pfSense Router Setup Guide

pfSense is a popular FreeBSD-based firewall and router platform with a web-based GUI. This guide shows you how to set up pfSense in your VM lab.

## What is pfSense?

pfSense provides:
- **Web-based GUI** - Easy configuration interface
- **Firewall** - Stateful packet filtering
- **VPN** - OpenVPN and IPSec support
- **Traffic Shaping** - Bandwidth management
- **High Availability** - CARP clustering
- **Packages** - Extensible with add-on packages

## pfSense vs Linux Router

| Feature | pfSense | Linux Router |
|---------|---------|--------------|
| **GUI** | Web interface | Command line |
| **Ease of Use** | Beginner-friendly | Advanced users |
| **Firewall** | Built-in GUI | iptables CLI |
| **VPN** | GUI wizards | Manual config |
| **Monitoring** | Web dashboards | CLI tools |
| **Community** | Large user base | Technical focus |

## Option 1: pfSense Template (Recommended)

### Deploy pfSense-Ready VM

```bash
# Add pfsense to vm-vagrant.sh roles first
# Create pfSense-ready FreeBSD VM
make create-pfsense NAME=firewall
```

### Install pfSense

1. **Download pfSense ISO:**
   ```bash
   wget https://www.pfsense.org/download/
   # Download latest pfSense ISO
   ```

2. **Mount ISO to VM:**
   ```bash
   # Using libvirt tools
   sudo virsh attach-disk firewall_default /path/to/pfsense.iso hdc --type cdrom
   ```

3. **Reboot and Install:**
   ```bash
   # Reboot VM to boot from ISO
   sudo virsh reboot firewall_default
   
   # Connect to console
   sudo virsh console firewall_default
   ```

4. **Follow pfSense Installation:**
   - Accept license
   - Install to hard disk
   - Reboot after installation

## Option 2: pfSense Vagrant Box

### Using Pre-built pfSense Box

Create custom pfSense Vagrantfile:

```ruby
# -*- mode: ruby -*-
Vagrant.configure("2") do |config|
  # Use unofficial pfSense box (community maintained)
  config.vm.box = "pfsense/pfsense"
  config.vm.hostname = "pfsense-gw"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
    
    # Add multiple network interfaces
    libvirt.management_network_name = "pfsense-mgmt"
    libvirt.management_network_address = "192.168.100.0/24"
  end
  
  # Configure multiple networks
  config.vm.network "private_network", 
    libvirt__network_name: "wan-network",
    ip: "203.0.113.1"
    
  config.vm.network "private_network",
    libvirt__network_name: "lan-network", 
    ip: "192.168.1.1"
end
```

## pfSense Initial Configuration

### 1. Console Setup

Access pfSense console:

```bash
# Via SSH to FreeBSD VM
make ssh NAME=firewall

# Or via libvirt console
sudo virsh console firewall_default
```

### 2. Network Interface Assignment

Configure interfaces in pfSense console:

```
1) Assign interfaces
2) Set interface(s) IP address
3) Reset webConfigurator password
4) Reset to factory defaults
...

Choose option 1 to assign interfaces:
- WAN: vtnet0 (usually first interface)  
- LAN: vtnet1 (second interface)
- OPT1: vtnet2 (additional interfaces)
```

### 3. Set IP Addresses

Configure interface IPs:

```
Choose option 2 to set IP addresses:

WAN interface:
- DHCP: y (for lab environment)
- Or static IP configuration

LAN interface:  
- IP: 192.168.1.1
- Subnet: 24
- Gateway: (none for LAN)
- DHCP: y
- DHCP range: 192.168.1.100-192.168.1.199
```

### 4. Web Interface Access

After basic configuration:

1. **Find pfSense IP:**
   ```bash
   # From console menu, option 2 shows IPs
   # Or check DHCP lease on management network
   ```

2. **Access Web GUI:**
   ```
   https://192.168.1.1  (LAN IP)
   Default: admin/pfsense
   ```

## pfSense Web Configuration

### Initial Setup Wizard

1. **General Information:**
   - Hostname: pfsense-gw
   - Domain: lab.local
   - DNS: 8.8.8.8, 1.1.1.1

2. **Time Server:**
   - Timezone: Your timezone
   - NTP Server: pool.ntp.org

3. **WAN Configuration:**
   - Type: DHCP (or Static)
   - Block private networks: Unchecked (for lab)

4. **LAN Configuration:**
   - IP: 192.168.1.1/24
   - DHCP: Enabled
   - Range: 192.168.1.100-199

5. **Admin Password:**
   - Set strong password
   - Create admin user

### Essential Configurations

#### Firewall Rules

**System → Firewall → Rules:**

```
LAN Rules:
- Allow: LAN net to any (default)
- Allow: LAN to WAN HTTP/HTTPS
- Block: LAN to RFC1918 (if needed)

WAN Rules:  
- Block: All (default)
- Allow: Specific services as needed
```

#### NAT Configuration

**Firewall → NAT → Port Forward:**

```bash
# Example: Forward SSH to internal server
Interface: WAN
Protocol: TCP  
Destination: WAN Address
Destination Port: 2222
Redirect Target IP: 192.168.1.10
Redirect Target Port: 22
```

#### VPN Setup

**VPN → OpenVPN → Servers:**

```bash
# Create OpenVPN server
Server Mode: Remote Access SSL/TLS
Protocol: UDP IPv4
Interface: WAN
Port: 1194
Description: Road Warrior VPN

# Certificate Management
System → Certificate Manager
- Create CA
- Create Server Certificate
- Create User Certificates
```

## Advanced pfSense Features

### High Availability (CARP)

Set up pfSense clustering:

```bash
# Primary pfSense
System → High Availability Sync
CARP VIP: 192.168.1.10
Sync Interface: LAN
Remote System: 192.168.1.2

# Secondary pfSense  
System → High Availability Sync
CARP VIP: 192.168.1.10 (same)
Sync Interface: LAN
Remote System: 192.168.1.1
```

### Traffic Shaping

**Firewall → Traffic Shaping:**

```bash
# Create traffic shaper
Interface: WAN
Bandwidth: 100 Mbps
Scheduler: HFSC

# Create queues
- VoIP: Priority 7, Bandwidth 10%
- Web: Priority 3, Bandwidth 50%  
- P2P: Priority 1, Bandwidth 10%
```

### Package Installation

**System → Package Manager:**

Popular packages:
- **pfBlockerNG** - DNS/IP blocking
- **Suricata** - Intrusion detection
- **ntopng** - Network monitoring
- **HAProxy** - Load balancing
- **Squid** - Web proxy/cache

## Monitoring and Maintenance

### Dashboard Widgets

Configure Status → Dashboard:
- **Interfaces** - Interface status
- **System Information** - System stats
- **Traffic Graphs** - Bandwidth usage
- **Services Status** - Service monitoring

### Logging

**Status → System Logs:**

```bash
# View logs
- System: General system events
- Firewall: Blocked connections
- DHCP: DHCP leases
- OpenVPN: VPN connections

# Log analysis
- Status → Monitoring → Traffic Graph
- Diagnostics → pfInfo
- Diagnostics → Packet Capture
```

### Backup and Restore

**Diagnostics → Backup & Restore:**

```bash
# Regular backups
- Download config: XML format
- Schedule: AutoConfigBackup package
- Version control: Git integration

# Restore process
- Upload backup file
- Restore and reboot
```

## Troubleshooting

### Common Issues

**Can't Access Web Interface:**
```bash
# Check IP configuration
# Console: option 2
# Verify firewall rules allow management access
```

**No Internet Access:**
```bash
# Check gateway configuration
# Verify DNS settings
# Check firewall rules on WAN
# Test from Diagnostics → Ping
```

**VPN Not Working:**
```bash
# Check certificate validity
# Verify firewall rules for VPN port
# Check OpenVPN server logs
# Test client configuration
```

### Diagnostic Tools

pfSense built-in diagnostics:

```bash
# Network connectivity
Diagnostics → Ping
Diagnostics → Traceroute  
Diagnostics → DNS Lookup

# System analysis
Diagnostics → pfInfo
Diagnostics → System Activity
Diagnostics → Tables

# Packet analysis
Diagnostics → Packet Capture
Status → Traffic Graph
```

## pfSense vs Linux Router Decision

### Choose pfSense When:
- ✅ You want a GUI interface
- ✅ Quick deployment is priority  
- ✅ Team has mixed skill levels
- ✅ Need enterprise firewall features
- ✅ Want commercial support options

### Choose Linux Router When:
- ✅ You prefer command line control
- ✅ Need custom routing protocols
- ✅ Want maximum flexibility
- ✅ Have strong Linux networking skills
- ✅ Need integration with other Linux services

## Next Steps

- **[Multi-Router Lab](../examples/multi-router.md)** - pfSense + Linux router scenarios
- **[VPN Configurations](vpn.md)** - Site-to-site with pfSense
- **[Load Balancing](load-balancing.md)** - HAProxy on pfSense

---

*pfSense: Enterprise firewall features with point-and-click simplicity!*