# BGP Configuration Tutorial

Border Gateway Protocol (BGP) is the routing protocol that makes the internet work. This guide shows you how to configure BGP on your virtual router using FRRouting.

## What is BGP?

BGP is used for:
- **Internet connectivity** - Connecting to ISPs
- **Multi-homing** - Multiple internet connections
- **Traffic engineering** - Controlling traffic flow
- **Enterprise peering** - Direct connections between organizations

## Prerequisites

- Virtual router deployed and running
- Basic understanding of IP networking
- FRRouting installed (included in router template)

## BGP Configuration Steps

### 1. Enable BGP Daemon

First, enable the BGP daemon in FRRouting:

```bash
sudo nano /etc/frr/daemons
```

Ensure BGP is enabled:
```
bgpd=yes
zebra=yes
```

Restart FRRouting:
```bash
sudo systemctl restart frr
```

### 2. Basic BGP Configuration

Enter FRRouting configuration mode:

```bash
sudo vtysh
configure terminal
```

Configure basic BGP settings:

```bash
# Configure BGP with your AS number
router bgp 65001

# Set router ID (usually your router's main IP)
bgp router-id 192.168.121.115

# Configure BGP networks you want to advertise
network 10.1.0.0/24
network 192.168.1.0/24

# Save configuration
write memory
exit
```

### 3. Configure BGP Neighbors (Peers)

Add BGP neighbors (other routers you want to peer with):

```bash
sudo vtysh
configure terminal
router bgp 65001

# Add external BGP neighbor (ISP)
neighbor 203.0.113.1 remote-as 64512
neighbor 203.0.113.1 description "ISP Connection"

# Add internal BGP neighbor (another router in your network)
neighbor 10.0.0.2 remote-as 65001
neighbor 10.0.0.2 description "Internal Router"

# Configure neighbor policies
neighbor 203.0.113.1 soft-reconfiguration inbound
neighbor 203.0.113.1 route-map ISP-IN in
neighbor 203.0.113.1 route-map ISP-OUT out

write memory
exit
```

### 4. Route Maps and Filtering

Create route maps to control traffic:

```bash
sudo vtysh
configure terminal

# Create access list for networks to advertise
ip prefix-list MY-NETWORKS seq 10 permit 10.1.0.0/24
ip prefix-list MY-NETWORKS seq 20 permit 192.168.1.0/24

# Create route map for outbound announcements
route-map ISP-OUT permit 10
 match ip address prefix-list MY-NETWORKS
 set metric 100

# Create route map for inbound filtering  
route-map ISP-IN permit 10
 set local-preference 100

write memory
exit
```

### 5. Verification Commands

Check BGP status and routing:

```bash
# Show BGP summary
show ip bgp summary

# Show BGP routing table
show ip bgp

# Show specific neighbor details
show ip bgp neighbors 203.0.113.1

# Show advertised routes to neighbor
show ip bgp neighbors 203.0.113.1 advertised-routes

# Show received routes from neighbor
show ip bgp neighbors 203.0.113.1 received-routes

# Show BGP routing table for specific network
show ip bgp 10.1.0.0/24
```

## Example Configurations

### Scenario 1: Single ISP Connection

```bash
# Basic single-homed configuration
router bgp 65001
 bgp router-id 192.168.121.115
 
 # Advertise your networks
 network 10.1.0.0/24
 network 192.168.1.0/24
 
 # ISP connection
 neighbor 203.0.113.1 remote-as 64512
 neighbor 203.0.113.1 description "Primary ISP"
```

### Scenario 2: Multi-Homed Setup

```bash
# Multi-homed configuration with two ISPs
router bgp 65001
 bgp router-id 192.168.121.115
 
 network 10.1.0.0/24
 network 192.168.1.0/24
 
 # Primary ISP
 neighbor 203.0.113.1 remote-as 64512
 neighbor 203.0.113.1 description "Primary ISP"
 neighbor 203.0.113.1 route-map PRIMARY-IN in
 neighbor 203.0.113.1 route-map PRIMARY-OUT out
 
 # Secondary ISP
 neighbor 198.51.100.1 remote-as 64513
 neighbor 198.51.100.1 description "Secondary ISP"
 neighbor 198.51.100.1 route-map SECONDARY-IN in  
 neighbor 198.51.100.1 route-map SECONDARY-OUT out

# Route maps for load balancing and failover
route-map PRIMARY-IN permit 10
 set local-preference 200

route-map SECONDARY-IN permit 10
 set local-preference 100

route-map PRIMARY-OUT permit 10
 match ip address prefix-list MY-NETWORKS
 set as-path prepend 65001

route-map SECONDARY-OUT permit 10
 match ip address prefix-list MY-NETWORKS
 set as-path prepend 65001 65001
```

### Scenario 3: Internal BGP (iBGP)

```bash
# Configuration for internal BGP between routers
router bgp 65001
 bgp router-id 10.0.0.1
 
 # iBGP neighbors (same AS)
 neighbor 10.0.0.2 remote-as 65001
 neighbor 10.0.0.2 description "Core Router 2"
 neighbor 10.0.0.2 update-source loopback0
 
 neighbor 10.0.0.3 remote-as 65001  
 neighbor 10.0.0.3 description "Edge Router"
 neighbor 10.0.0.3 next-hop-self
```

## Advanced BGP Features

### Route Reflection

For large iBGP networks:

```bash
router bgp 65001
 # Configure as route reflector
 bgp cluster-id 10.0.0.1
 
 # Route reflector clients
 neighbor 10.0.0.10 route-reflector-client
 neighbor 10.0.0.11 route-reflector-client
```

### BGP Communities

Tag routes for policy decisions:

```bash
# Set community values
route-map SET-COMMUNITY permit 10
 set community 65001:100

# Match community values
route-map MATCH-COMMUNITY permit 10
 match community CUSTOMER-ROUTES
 
ip community-list CUSTOMER-ROUTES permit 65001:100
```

### BGP Monitoring

Monitor BGP in real-time:

```bash
# Debug BGP updates
debug bgp updates

# Debug BGP neighbor events  
debug bgp neighbor-events

# Show BGP performance statistics
show ip bgp statistics

# Clear BGP sessions
clear ip bgp *
clear ip bgp 203.0.113.1
```

## Troubleshooting

### Common Issues

**BGP Neighbor Not Establishing:**
```bash
# Check neighbor state
show ip bgp neighbors 203.0.113.1

# Common states:
# - Idle: Not trying to connect
# - Connect: TCP connection attempt
# - Active: Waiting for connection
# - Established: Working properly
```

**Routes Not Being Advertised:**
```bash
# Verify network statements
show running-config | section router bgp

# Check route maps
show route-map

# Verify routing table has routes
show ip route
```

**Incorrect Route Selection:**
```bash
# Show BGP path selection
show ip bgp 10.1.0.0/24

# BGP path selection order:
# 1. Highest local preference
# 2. Shortest AS path
# 3. Lowest origin (IGP < EGP < Incomplete)
# 4. Lowest MED
# 5. eBGP over iBGP
# 6. Shortest IGP metric to next-hop
# 7. Lowest router ID
```

## Security Considerations

### BGP Authentication

```bash
# Configure MD5 authentication
neighbor 203.0.113.1 password MySecretKey
```

### Prefix Filtering

```bash
# Limit accepted prefixes
neighbor 203.0.113.1 maximum-prefix 10000

# Filter bogon networks
ip prefix-list BOGONS deny 0.0.0.0/8 le 32
ip prefix-list BOGONS deny 10.0.0.0/8 le 32
ip prefix-list BOGONS deny 127.0.0.0/8 le 32
ip prefix-list BOGONS deny 169.254.0.0/16 le 32
ip prefix-list BOGONS deny 172.16.0.0/12 le 32
ip prefix-list BOGONS deny 192.168.0.0/16 le 32

route-map ISP-IN deny 5
 match ip address prefix-list BOGONS
route-map ISP-IN permit 10
```

## Next Steps

- **[OSPF Configuration](ospf.md)** - Internal routing protocol
- **[VPN Setup](vpn.md)** - Secure site-to-site connections
- **[Multi-Router Lab](../examples/multi-router.md)** - Complex network topologies

---

*BGP: The protocol that routes the internet, now running on your virtual router!*