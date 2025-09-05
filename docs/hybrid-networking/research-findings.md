# Hybrid Networking Research Findings

## Current Network Architecture Discovery

### Libvirt Networks
**vagrant-libvirt Network (Primary for VMs)**
- Bridge: `virbr1`
- Network: `192.168.121.0/24`
- Gateway: `192.168.121.1`
- DHCP Range: `192.168.121.1-192.168.121.254`
- Currently active with 4 connections

**default Network (Inactive)**  
- Bridge: `virbr0` (down)
- Network: `192.168.122.0/24`
- Gateway: `192.168.122.1`
- DHCP Range: `192.168.122.2-192.168.122.254`

### Docker Networks
**Default Bridge (docker0)**
- Bridge: `docker0` 
- Network: `172.17.0.0/16`
- Gateway: `172.17.0.1`
- Active containers: 1 (portainer)

**Custom Bridge (ebpf-ddos_demo_network)**
- Bridge: `br-3a1ae101c82e`
- Network: `172.20.0.0/16` 
- Gateway: `172.20.0.1`
- Active containers: 6 (demo application stack)

### Current VM Status
**Active VMs on vagrant-libvirt network:**
- vm-lab_lxd: `192.168.121.74/24`
- vm-lab_observer: `192.168.121.201/24`
- vm-lab_kata: `192.168.121.161/24`
- vm-lab_router: `192.168.121.26/24`

**Inactive VMs:**
- vm-lab_base, vm-lab_docker, vm-lab_k8s (shut off)

### Other Bridges
- `lxdbr0`: LXD internal bridge (likely from LXD VM)

## Key Findings

### 1. Network Isolation
- **Complete isolation**: VMs (192.168.121.x) and Docker containers (172.17.x/172.20.x) are on separate networks
- No current communication path between VM and container networks
- Different bridge interfaces with no interconnection

### 2. IP Address Management
- **No conflicts detected**: VM and Docker networks use entirely different IP ranges
- Libvirt uses 192.168.121.x for VMs
- Docker uses 172.17.x and 172.20.x for containers
- Clean separation makes hybrid networking safer to implement

### 3. Bridge Infrastructure Analysis
- **virbr1**: Libvirt's vagrant network - mature, stable
- **docker0**: Docker's default bridge - well-tested
- **br-xxx**: Docker custom bridges - created via docker-compose

### 4. Connectivity Potential
- Both VM and Docker bridges support similar Linux networking
- Both use NAT for external connectivity
- Bridge-to-bridge routing should be technically feasible

## Technical Feasibility Assessment

### ✅ **Advantages**
1. **Clean IP separation** - No existing conflicts to resolve
2. **Proven bridge technology** - Both libvirt and Docker use Linux bridges
3. **Existing infrastructure** - Active VMs and containers to test with
4. **NAT compatibility** - Both networks already support external connectivity

### ⚠️ **Challenges**
1. **DHCP coordination** - Need to prevent IP conflicts if using shared subnet
2. **Routing complexity** - Bridge-to-bridge routing requires careful setup
3. **DNS resolution** - Container/VM hostname resolution across networks
4. **Security boundaries** - Maintaining proper network isolation where needed

### 🎯 **Recommended Approach**
1. **Create dedicated hybrid bridge** - New bridge for hybrid networking
2. **Custom IP range** - Use 10.0.x.x range to avoid conflicts  
3. **Manual IP assignment initially** - Avoid DHCP conflicts during PoC
4. **Test with existing VMs** - Use running VMs for connectivity tests

## Next Steps

### Phase 1A: Bridge Creation Experiment
1. Create custom bridge (e.g., `hybr0` with `10.0.1.0/24`)
2. Test Docker container attachment to custom bridge
3. Test VM attachment to custom bridge (requires VM restart)
4. Validate bidirectional connectivity

### Phase 1B: Production Integration
1. Create Makefile targets for hybrid network management
2. Update VM templates with hybrid networking option
3. Create Docker network creation scripts
4. Document configuration procedures

## Research Questions - Status

✅ **Bridge Compatibility**: Linux bridges are compatible - both libvirt and Docker use similar technology

🔄 **IP Management**: Clean separation exists, need DHCP coordination strategy for shared subnets

🔄 **Performance Impact**: Needs testing - expect minimal impact for bridge-to-bridge routing

🔄 **Security Implications**: Need to define isolation boundaries for hybrid vs isolated networking modes

## Test Environment Ready

- **4 active VMs** available for testing
- **7 active containers** across 2 networks
- **Clean IP separation** makes experimentation safe
- **Multiple bridges** provide good test diversity

The current environment is ideal for implementing hybrid networking PoC!