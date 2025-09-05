# Hybrid Networking User Guide

## Overview

VM Lab's hybrid networking feature allows Docker containers and virtual machines to communicate directly on the same network subnet. This enables powerful infrastructure scenarios where containers and VMs work together seamlessly.

## Quick Start

### 1. Create the Hybrid Network

```bash
make create-hybrid-network
```

This creates:
- Bridge network `hybr0` with subnet `10.0.1.0/24`
- Docker network `hybrid-net` connected to the bridge
- Libvirt network `hybrid-network` for VMs

### 2. Create Hybrid VMs

```bash
# Create a base Ubuntu VM with hybrid networking
make hybrid-base NAME=my-dev-vm

# Create a Docker-enabled VM with hybrid networking  
make hybrid-docker NAME=my-docker-vm
```

### 3. Run Containers on Hybrid Network

```bash
# Run a container on the hybrid network
docker run -d --name web-server --network hybrid-net nginx:alpine

# Or assign a specific IP
docker run -d --name api-server --network hybrid-net --ip 10.0.1.150 node:alpine
```

### 4. Test Connectivity

```bash
# Check hybrid network status
make hybrid-status

# Test connectivity between all components
make hybrid-test-connectivity
```

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 Hybrid Network (10.0.1.0/24)               │
├─────────────┬─────────────────┬─────────────────────────────┤
│    Host     │   Docker        │        Virtual               │
│  Gateway    │  Containers     │        machines              │
│ 10.0.1.1    │ 10.0.1.100-199  │      10.0.1.200+            │
└─────────────┴─────────────────┴─────────────────────────────┘
│                                                             │
└──────────────────── hybr0 Bridge ─────────────────────────┘
```

### IP Address Allocation

- **Gateway**: `10.0.1.1` (bridge host interface)
- **Docker Containers**: `10.0.1.100-199` (auto-assigned or manual)
- **Virtual Machines**: `10.0.1.200+` (auto-assigned)
- **Reserved**: `10.0.1.2-99` (available for manual assignment)

## VM Types

### Hybrid Base VM

```bash
make hybrid-base NAME=my-base-vm
```

**Features:**
- Clean Ubuntu 24.04 LTS
- Dual network interfaces (management + hybrid)
- Basic networking tools included
- Ready for container communication

**Use Cases:**
- Development environments that need to communicate with containers
- Testing VM-to-container service interactions
- Infrastructure components that work alongside containerized services

### Hybrid Docker VM

```bash
make hybrid-docker NAME=my-docker-vm  
```

**Features:**
- Ubuntu 24.04 LTS with Docker pre-installed
- Docker Compose included
- Dual network interfaces (management + hybrid)
- Helper scripts for hybrid container management

**Use Cases:**
- Running containers that need to communicate with other VMs
- Mixed VM/container environments
- Container orchestration with VM-based services

## Usage Examples

### Example 1: Web Application with Database VM

```bash
# Create hybrid network
make create-hybrid-network

# Create database VM
make hybrid-base NAME=database-vm
make ssh NAME=database-vm
# Install and configure PostgreSQL on VM

# Run web application container
docker run -d --name web-app --network hybrid-net -p 80:3000 \
  -e DATABASE_URL=postgresql://user:pass@10.0.1.200:5432/mydb \
  my-web-app:latest
```

### Example 2: Microservices with Legacy VM Service

```bash
# Create hybrid network
make create-hybrid-network

# Create VM for legacy service
make hybrid-base NAME=legacy-service
# Deploy legacy application on VM

# Run modern microservices as containers
docker run -d --name auth-service --network hybrid-net auth-microservice:latest
docker run -d --name api-gateway --network hybrid-net \
  -e LEGACY_SERVICE_URL=http://10.0.1.200:8080 \
  api-gateway:latest
```

### Example 3: Development Environment

```bash
# Create hybrid network
make create-hybrid-network

# Create development VM
make hybrid-docker NAME=dev-vm

# SSH into VM and run development containers
make ssh NAME=dev-vm
# Inside VM:
docker run -d --name redis --network hybrid-net redis:alpine
docker run -d --name postgres --network hybrid-net \
  -e POSTGRES_PASSWORD=password postgres:alpine

# Run application locally that connects to VM containers
```

## Network Management

### View Network Status

```bash
make hybrid-status
```

Shows:
- Bridge status and connected devices
- Docker network information and connected containers
- Libvirt network status and connected VMs
- IP address assignments

### Test Connectivity

```bash
make hybrid-test-connectivity
```

Tests:
- Host-to-bridge gateway connectivity
- Host-to-container connectivity  
- Host-to-VM connectivity
- Reports any connectivity issues

### Clean Up

```bash
# Remove all containers from hybrid network
docker network disconnect hybrid-net <container-name>

# Stop hybrid VMs
make stop NAME=<vm-name>

# Destroy hybrid network (removes all components)
make destroy-hybrid-network
```

## VM Commands Inside Hybrid VMs

### Hybrid Base VMs

- `hybrid-test` - Test network connectivity to other hybrid components
- `ip addr show enp0s8` - Show hybrid network interface status
- `ping 10.0.1.1` - Test gateway connectivity

### Hybrid Docker VMs

- `hybrid-test` - Comprehensive network connectivity test
- `hybrid-container <name> <image>` - Run container on hybrid network
- `docker network connect hybrid-net <container>` - Connect existing container

## Troubleshooting

### VM Can't Reach Containers

1. Check VM hybrid interface:
   ```bash
   make ssh NAME=my-vm
   ip addr show enp0s8
   ```

2. Verify hybrid network exists:
   ```bash
   make hybrid-status
   ```

3. Test basic connectivity:
   ```bash
   ping 10.0.1.1  # Should reach bridge gateway
   ```

### Container Can't Reach VM

1. Check container is on hybrid network:
   ```bash
   docker network inspect hybrid-net
   ```

2. Verify VM IP and connectivity:
   ```bash
   make hybrid-test-connectivity
   ```

### Network Creation Fails

1. Check for conflicting bridges:
   ```bash
   ip addr show | grep 10.0.1.1
   brctl show
   ```

2. Ensure Docker and libvirt are running:
   ```bash
   systemctl status docker libvirtd
   ```

3. Check permissions:
   ```bash
   # Current user should be in docker group
   groups $USER | grep docker
   
   # Should be able to run virsh commands
   virsh net-list --all
   ```

## Advanced Configuration

### Custom IP Assignments

For containers:
```bash
docker run -d --name my-service --network hybrid-net --ip 10.0.1.150 my-image:latest
```

For VMs, edit the Vagrantfile in `vms/<vm-name>/Vagrantfile` before starting:
```ruby
config.vm.network :private_network, 
  :libvirt__network_name => "hybrid-network",
  :libvirt__dhcp_enabled => false,
  :ip => "10.0.1.210"
```

### Security Considerations

- Hybrid networking bypasses container isolation
- All components on hybrid network can communicate freely
- Use firewall rules within VMs/containers for additional security
- Consider network segmentation for production deployments

### Performance Optimization

- Bridge networking adds minimal latency (typically <1ms)
- For high-throughput scenarios, consider dedicating CPU cores
- Monitor bridge interface performance with standard network tools

## Integration with Existing Infrastructure

### With Standard VM Lab VMs

- Standard VMs use `192.168.121.0/24` (isolated from hybrid network)
- Mix standard and hybrid VMs as needed
- Use make commands to manage both types

### With Docker Compose

```yaml
version: '3.8'
services:
  web:
    image: nginx:alpine
    networks:
      - hybrid-net
      
  app:
    image: node:alpine
    networks:
      - hybrid-net
    environment:
      - DATABASE_URL=postgresql://user:pass@10.0.1.200:5432/db

networks:
  hybrid-net:
    external: true
```

### With Kubernetes (Experimental VMs)

- K8s VMs can be created with hybrid networking
- Allows pod-to-VM communication
- Useful for hybrid cloud-native architectures

## Best Practices

1. **Plan IP allocation** - Reserve ranges for different services
2. **Document network topology** - Keep track of what runs where
3. **Use DNS names when possible** - Consider running a DNS service
4. **Monitor connectivity** - Regular health checks
5. **Backup VM configurations** - VMs in `vms/` directory
6. **Test disaster recovery** - Practice recreating the network

## Next Steps

- Explore [Advanced Scenarios](advanced-scenarios.md)
- Set up [DNS Resolution](dns-resolution.md) between components
- Configure [Network Policies](network-policies.md) for security
- Learn about [Performance Monitoring](monitoring.md)