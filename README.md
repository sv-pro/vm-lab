# 🚀 VM Lab: Your Personal Infrastructure Playground

**Build enterprise-grade networks in minutes, not hours.**

VM Lab is a comprehensive virtualization platform that lets you craft complete network infrastructures with simple commands. Whether you're learning networking, testing configurations, or building complex multi-tier applications, VM Lab gives you the tools to **make** anything.

[![Vagrant](https://img.shields.io/badge/Vagrant-2.4+-blue.svg)](https://www.vagrantup.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Why VM Lab?

### 🎯 **Simple Commands, Professional Results**
```bash
make base NAME=dev-env        # "I'm making a clean Ubuntu development environment"
make docker NAME=web-app      # "I'm making a Docker container host"
make observer NAME=monitor    # "I'm making a monitoring and analysis system"
```

### 🏗️ **Digital Craftsmanship**
Each command feels like **building** infrastructure, not just running scripts. You're crafting your own data center, piece by piece.

### 🌟 **Production-Ready Tools**
- **Base Systems**: Clean Ubuntu 24.04 LTS with development tools
- **Containers**: Docker 27.5+ with docker-compose for modern applications
- **Monitoring**: eBPF tools (bpftrace), system monitoring (htop) for deep observability
- **Multi-User**: Pre-configured vagrant, ubuntu, and dev users with SSH access

## 🚧 Current Development Status

### ✅ **Fully Functional (Ready for Production)**
| Role | Description | Status |
|------|-------------|---------|
| **base** | Clean Ubuntu 24.04 with development tools | ✅ Production Ready |
| **docker** | Docker host with container orchestration | ✅ Production Ready |
| **observer** | System monitoring with eBPF capabilities | ✅ Production Ready |

### 🧪 **Experimental Roles (Available but Hidden)**
*Advanced users can access these via direct commands (not shown in `make help`):*
| Role | Description | Status | Access |
|------|-------------|---------|--------|
| **k8s** | Kubernetes cluster with MicroK8s | ⚠️ Provisioning Issues | `make create-k8s` |
| **lxd** | LXD container platform | ⚠️ Provisioning Issues | `make create-lxd` |
| **kata** | Secure container runtime | ❌ Creation Issues | `make create-kata` |
| **router** | Virtual networking router | ❌ Provisioning Timeout | `make create-router` |  
| **pfsense** | Ubuntu-based firewall | ❌ Heavy Provisioning | `make create-pfsense` |

### 🛣️ **Roadmap**

**Phase 1: Stabilize Core Functionality** *(Current Priority)*
- [ ] Fix snap package installation for k8s and lxd roles
- [ ] Optimize provisioning timeouts for complex VMs
- [ ] Add resource management to prevent concurrent provisioning conflicts
- [ ] Implement provisioning retry logic and error handling

**Phase 2: Enhanced Reliability**
- [ ] Split complex provisioning into multiple stages
- [ ] Add provisioning progress indicators and logging
- [ ] Implement VM health checks and validation
- [ ] Create minimal "quick start" variants of complex roles

**Phase 3: Advanced Features**
- [ ] Custom VM templates and cloning
- [ ] Multi-VM environment orchestration
- [ ] Network connectivity testing between VMs
- [ ] Resource usage monitoring and optimization

## 🎮 Quick Start: Build Your First Network

### 1. **Prerequisites**
```bash
# Ubuntu/Debian
sudo apt install vagrant libvirt-daemon-system

# Install vagrant-libvirt plugin  
vagrant plugin install vagrant-libvirt

# Clone the lab
git clone https://github.com/your-org/vm-lab.git
cd vm-lab
```

### 2. **Create Your Infrastructure**
```bash
# Start with working VM roles (tested and reliable)
make base NAME=dev-env            # Clean development environment  
make docker NAME=web-cluster      # Container host with Docker
make observer NAME=monitoring     # System monitoring with eBPF tools

# Check VM status
make status                       # View all VM states
make ssh NAME=dev-env            # Connect to your VMs
```

### 3. **Connect and Configure**
```bash
# SSH into any VM
make ssh NAME=core-gw

# List all VMs  
make list

# Check VM status
make status
```

### 4. **Access Web Interfaces**
- **pfSense Management**: `http://<pfsense-ip>` - Firewall GUI
- **Monitoring Dashboard**: `http://<observer-ip>:3000` - Grafana
- **Container Registry**: `http://<docker-ip>:5000` - Private registry

## 🏆 VM Types: Choose Your Tool

| VM Type | Command | Purpose | Key Features |
|---------|---------|---------|--------------|
| **🐧 Base** | `make base` | Clean Ubuntu | Minimal system, custom configs |
| **🐳 Docker** | `make docker` | Container Host | Docker + Compose, private registry |
| **☸️ Kubernetes** | `make k8s` | Orchestration | MicroK8s, kubectl, Helm ready |
| **📦 LXD** | `make lxd` | System Containers | LXD + ZFS, container management |
| **🏃 Kata** | `make kata` | Secure Containers | Hardware virtualization isolation |
| **🔍 Observer** | `make observer` | Monitoring | eBPF, Prometheus, Grafana, tcpdump |
| **🌐 Router** | `make router` | Network Routing | FRRouting, BGP, OSPF, VPN |
| **🛡️ pfSense** | `make pfsense` | Firewall/Gateway | Web GUI, NAT, VPN, load balancing |

## 🎯 Real-World Scenarios

### 🏢 **Enterprise Network Simulation**
```bash
# Core infrastructure
make router NAME=core-router          # BGP + OSPF routing
make pfsense NAME=border-fw           # Internet gateway
make observer NAME=network-mon        # Traffic monitoring

# Application tier  
make k8s NAME=prod-cluster           # Production workloads
make docker NAME=staging-env         # Development environment

# Connect and configure routing between VMs
make ssh NAME=core-router
# Configure BGP peering, OSPF areas, static routes
```

### 🔐 **Security Testing Lab**
```bash
# Security infrastructure
make pfsense NAME=perimeter-fw       # Perimeter defense
make observer NAME=threat-hunter     # Security monitoring  
make docker NAME=vulnerable-apps     # Test applications

# Simulate attacks, test firewall rules, monitor traffic
```

### ☁️ **Cloud-Native Development**
```bash
# Modern application stack
make k8s NAME=dev-cluster            # Development cluster
make docker NAME=build-server        # CI/CD environment
make observer NAME=metrics-stack     # Application monitoring

# Deploy microservices, test scaling, monitor performance
```

### 🎓 **Network Learning Lab**
```bash
# Learning environment
make router NAME=router-a            # First router
make router NAME=router-b            # Second router  
make docker NAME=client-net          # Client applications

# Practice BGP peering, OSPF configuration, traffic engineering
```

## 🎨 Advanced Features

### 🏷️ **Dynamic VM Naming**
Create multiple VMs of the same type with custom names:
```bash
make docker NAME=web-app-01
make docker NAME=web-app-02  
make docker NAME=database-server
```

Each gets isolated configuration and networking.

### 🔧 **Role-Based Templates**
Every VM type comes with purpose-built configurations:

- **Router VMs**: FRRouting daemons, networking tools, BGP/OSPF ready
- **Docker VMs**: Container runtime, Docker Compose, private registry
- **K8s VMs**: MicroK8s cluster, kubectl, Helm, ingress controllers
- **Observer VMs**: Monitoring stack, eBPF tools, network analysis

### 🌐 **Network Integration**
VMs automatically get:
- **Isolated networking** with libvirt
- **SSH key authentication** pre-configured  
- **Hostname resolution** between VMs
- **Internet connectivity** through host

### 📊 **Built-in Monitoring**
Observer VMs include:
- **Prometheus** - Metrics collection
- **Grafana** - Visualization dashboards
- **eBPF tools** - Kernel-level tracing
- **Network analyzers** - Traffic inspection

## 📖 Documentation

### 🚀 **Quick Guides**
- **[Router Quick Start](docs/router/quickstart/README.md)** - Get routing in 5 minutes
- **[BGP Configuration](docs/router/tutorials/bgp.md)** - Internet routing setup
- **[pfSense Setup](docs/router/tutorials/pfsense-setup.md)** - Web-managed firewall

### 📚 **Deep Dives**
- **[Network Scenarios](docs/router/examples/lab-scenarios.md)** - Real-world topologies
- **[Security Monitoring](docs/observer/monitoring-setup.md)** - eBPF and Grafana
- **[Container Orchestration](docs/k8s/cluster-setup.md)** - Kubernetes deployment

### 🔧 **Reference**
- **[Command Reference](docs/reference/commands.md)** - All available commands
- **[Troubleshooting](docs/reference/troubleshooting.md)** - Common issues
- **[Configuration Files](docs/reference/config-files.md)** - Customization guide

## 🏗️ Architecture

### **Technology Stack**
- **Virtualization**: QEMU/KVM with libvirt
- **Orchestration**: Vagrant for VM lifecycle
- **Operating System**: Ubuntu 24.04 LTS
- **Networking**: Linux bridge networking, isolated subnets
- **Storage**: qcow2 disk images, ZFS where appropriate

### **Project Structure**
```
vm-lab/
├── Makefile                 # Main command interface
├── Vagrantfile              # Multi-machine VM definitions  
├── vm-vagrant.sh           # VM management wrapper
├── templates/              # Role-specific VM templates
│   ├── Vagrantfile.docker  # Docker host template
│   ├── Vagrantfile.k8s     # Kubernetes template
│   └── Vagrantfile.router  # Router template
├── docs/                   # Comprehensive documentation
└── vms/                    # Custom VM workspaces
```

## 🤝 Contributing

### **Ways to Contribute**
- 🐛 **Bug Reports**: Found an issue? Open an issue!
- 💡 **Feature Requests**: Have an idea? We'd love to hear it!
- 📖 **Documentation**: Help improve guides and tutorials
- 🔧 **New VM Types**: Add support for new technologies
- 🧪 **Testing**: Try different scenarios and report back

### **Development Setup**
```bash
git clone https://github.com/your-org/vm-lab.git
cd vm-lab

# Test your changes
make docker NAME=test-vm
make ssh NAME=test-vm

# Run the test suite
./scripts/test-all-roles.sh
```

## 🎯 Use Cases

### **👨‍💼 For Network Engineers**
- Learn routing protocols (BGP, OSPF, ISIS)
- Test network configurations safely
- Practice troubleshooting scenarios
- Validate designs before production

### **🔐 For Security Professionals**  
- Build attack/defense scenarios
- Test firewall configurations
- Monitor network traffic patterns
- Develop security automation

### **☁️ For DevOps Engineers**
- Container orchestration learning
- Infrastructure as Code practice
- Monitoring stack deployment
- Multi-tier application testing

### **🎓 For Students & Educators**
- Hands-on networking labs
- Safe learning environment  
- Real-world tool exposure
- Collaborative projects

### **🏢 For Enterprise Teams**
- Architecture prototyping
- Technology evaluation
- Training environments
- Proof of concepts

## 🚀 Roadmap

### **🎯 Planned Features**
- [ ] **Windows VMs** - Active Directory, Windows Server roles
- [ ] **ARM Support** - Apple Silicon and ARM server support  
- [ ] **Cloud Integration** - AWS/Azure hybrid scenarios
- [ ] **Ansible Integration** - Infrastructure as Code automation
- [ ] **Scenario Templates** - Pre-built network topologies
- [ ] **Performance Testing** - Built-in benchmarking tools
- [ ] **Multi-Host** - Distributed lab across multiple machines

### **💡 Community Ideas**
- Network simulation with realistic latency/bandwidth
- Integration with network emulators (GNS3, EVE-NG)
- Support for more hypervisors (VMware, Hyper-V)
- Container-based alternatives for faster deployment

```markdown

# Some sections below are illustrative and should be filled with actual data/links as the project evolves.

## 📊 Stats & Recognition 
(Not real, wannabe stats for illustration)
- ⭐ **1.2k+ Stars** - Growing community of network engineers
- 🍴 **200+ Forks** - Active development contributions  
- 📦 **50+ Releases** - Regular updates and improvements
- 🌍 **500+ Organizations** - Used by companies worldwide

## 🏆 Awards & Recognition
(Not real, for illustration)
- **DevOps Weekly Featured Project** - Infrastructure tooling spotlight
- **Awesome Self-Hosted** - Listed in networking tools section
- **GitHub Trending** - Featured in Infrastructure category
- **Community Choice** - Top network simulation platform

## 📞 Support & Community

### **💬 Get Help**
(To be filled with actual support channels)
- 📖 **Documentation**: Comprehensive guides and tutorials
- 💬 **Discussions**: GitHub Discussions for Q&A
- 🐛 **Issues**: Bug reports and feature requests  
- 📧 **Email**: maintainers@vm-lab.dev for direct support

### **🌐 Community**
(To be filled with actual community links)
- **Discord**: [Join our Discord](https://discord.gg/vm-lab) - Real-time chat
- **Reddit**: [r/vmlab](https://reddit.com/r/vmlab) - Community discussions
- **Twitter**: [@vmlabproject](https://twitter.com/vmlabproject) - Updates and tips
- **LinkedIn**: [VM Lab Network](https://linkedin.com/company/vm-lab) - Professional network
```

## ⚖️ License

VM Lab is released under the **MIT License**. See [LICENSE](LICENSE) for details.

**TL;DR**: Use it freely, modify it, distribute it, build amazing things with it! 🎉

## 🙏 Acknowledgments

### **Special Thanks**
- **Vagrant Team** - For the excellent virtualization platform
- **libvirt Community** - For robust VM management
- **FRRouting Project** - For enterprise-grade routing
- **Ubuntu Team** - For the stable foundation
- **Contributors** - For making this project awesome

### **Inspiration**
VM Lab was inspired by the need for accessible, professional-grade networking tools that don't require expensive hardware or complex setups. We believe everyone should have access to enterprise infrastructure for learning and experimentation.

---

<div align="center">

**Ready to build your own infrastructure?**

```bash
git clone https://github.com/your-org/vm-lab.git && cd vm-lab
make docker NAME=my-first-vm
```

**[⭐ Star this repo](https://github.com/your-org/vm-lab)** • **[🍴 Fork it](https://github.com/your-org/vm-lab/fork)** • **[📖 Read the docs](docs/)** • **[💬 Join Discord](https://discord.gg/vm-lab)**

*Made with ❤️ by network engineers, for network engineers*

</div>