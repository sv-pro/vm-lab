# Virtual Router Quick Start Guide

Get your virtual router up and running in under 5 minutes!

## 1. Deploy the Router

Create and start your virtual router:

```bash
# Create a custom router VM
make create-router NAME=gateway

# Or use default name
make create-router
```

The router will be provisioned with:
- **IP Forwarding** enabled
- **FRRouting** installed and configured
- **Networking tools** ready to use
- **Basic firewall** rules applied

## 2. Connect to Your Router

SSH into the router:

```bash
make ssh NAME=gateway
```

You'll see the router welcome message with installed components.

## 3. Verify Router Status

Check that core services are running:

```bash
# Check IP forwarding
sudo sysctl net.ipv4.ip_forward
sudo sysctl net.ipv6.conf.all.forwarding

# Check routing table
ip route show

# Check network interfaces
ip addr show

# Check FRRouting status
sudo systemctl status frr
```

## 4. Basic Network Configuration

### Configure Additional Network Interfaces

Add more network interfaces for multi-homed setup:

```bash
# View current interfaces
ip link show

# Add VLAN interface (example)
sudo ip link add link eth0 name eth0.100 type vlan id 100
sudo ip addr add 10.1.100.1/24 dev eth0.100
sudo ip link set eth0.100 up
```

### Enable FRRouting Daemons

Edit FRR daemon configuration:

```bash
sudo nano /etc/frr/daemons
```

Enable the routing protocols you need:
```
bgpd=yes
ospfd=yes
zebra=yes
```

Restart FRRouting:
```bash
sudo systemctl restart frr
```

## 5. Access Router Configuration

### FRRouting CLI (vtysh)

Enter the router configuration mode:

```bash
sudo vtysh
```

Basic commands:
```
# Show running configuration
show running-config

# Show IP routes
show ip route

# Configure router
configure terminal

# Save configuration
write memory
```

### Configuration Files

Key configuration files:
- `/etc/frr/frr.conf` - Main FRR configuration
- `/etc/frr/daemons` - Enable/disable routing daemons
- `/etc/iptables/rules.v4` - Firewall rules
- `/etc/sysctl.conf` - Kernel networking parameters

## 6. Quick Test

Test basic connectivity:

```bash
# Ping test
ping -c 4 8.8.8.8

# Check routing table
ip route show

# Monitor network traffic
sudo tcpdump -i any -c 10
```

## Next Steps

Now that your router is running, choose your configuration path:

### For Enterprise Networks
→ **[OSPF Setup Guide](../tutorials/ospf.md)** - Internal routing protocol

### For Internet Connectivity  
→ **[BGP Configuration](../tutorials/bgp.md)** - Internet routing

### For Remote Access
→ **[VPN Configuration](../tutorials/vpn.md)** - Site-to-site tunnels

### For Load Balancing
→ **[HAProxy Setup](../tutorials/load-balancing.md)** - Traffic distribution

## Troubleshooting

### Router Not Forwarding Traffic?
```bash
# Check IP forwarding
sudo sysctl net.ipv4.ip_forward
# Should return: net.ipv4.ip_forward = 1

# Enable if needed
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### FRRouting Not Starting?
```bash
# Check status
sudo systemctl status frr

# Check logs  
sudo journalctl -u frr -f

# Restart service
sudo systemctl restart frr
```

### Network Interface Issues?
```bash
# Check interface status
ip link show

# Bring interface up
sudo ip link set <interface> up

# Check for IP addresses
ip addr show <interface>
```

## Default Credentials

- **SSH Users:** vagrant, ubuntu, dev
- **Passwords:** ubuntu/ubuntu, dev/dev123
- **SSH Key:** `~/.ssh/id_rsa` (or Vagrant insecure key)
- **VM IP:** Assigned by libvirt DHCP (192.168.121.x)

---

**Your virtual router is now ready for advanced networking configurations!**