# VM Lab Demos

Interactive demonstrations showcasing VM Lab's hybrid networking and eBPF monitoring capabilities.

## Available Demos

### 🔍 DNS Monitoring Demo Suite
Real-time monitoring of DNS queries in the hybrid VM+Container network.

**Location**: `demos/dns-*` files  
**Purpose**: Demonstrate network monitoring from simple log watching to advanced eBPF tracing  
**Network**: Uses hybrid-dns container (10.0.1.2:53) and .hybrid.local domains  

---

## Quick Start

### 🚀 Easy Interactive Mode
```bash
make demo-dns-monitor
```
**What it does**: Launches interactive menu with 6 monitoring options  
**Requirements**: Hybrid network must be running, **sudo access for eBPF demos**  
**User Level**: All levels (beginner to expert)  

**⚠️ Important**: Most demos require `sudo` for eBPF functionality  

### ⚡ Prerequisites Check
```bash
# 1. Ensure hybrid network is running
make hybrid-status

# 2. If not running, create it:
make create-hybrid-network
make hybrid-enable-dns

# 3. Verify DNS container is active:
docker ps | grep hybrid-dns
```

---

## Demo Types

### 1. 📊 Container Logs Monitoring (Simplest)
```bash
./demos/dns-container-monitor.sh
```

**What it monitors**: DNS queries processed by the hybrid-dns container  
**Technology**: Docker logs, **no eBPF or sudo required**  
**Requirements**: Only hybrid network running (no special permissions)  
**Good for**: Understanding DNS query patterns, beginners, **works without sudo**  

**Sample Output**:
```
🔍 DNS Container Monitor - Watching hybrid-dns container logs
📊 Real-time DNS queries:
🔍 QUERY:  dnsmasq[1]: query[A] test-container.hybrid.local from 10.0.1.10
✅ REPLY:  dnsmasq[1]: reply test-container.hybrid.local is 10.0.1.50
```

### 2. 🖥️ eBPF Process Monitoring (Intermediate)
```bash
sudo bpftrace demos/dns-ultra-simple.bt
```

**What it monitors**: Processes accessing DNS configuration files  
**Technology**: eBPF tracepoints (stable, kernel-agnostic)  
**Requirements**: **sudo required**, bpftrace installed  
**Good for**: Learning eBPF basics, system call monitoring  

**Sample Output**:
```
🔍 DNS Process Monitor - Shows when programs do DNS lookups
📖 systemd-resolve (PID 1234) accessed DNS config: /etc/resolv.conf
📖 ping (PID 5678) accessed DNS config: /etc/hosts
```

### 3. 🌐 eBPF Network Monitoring (Advanced)
```bash
sudo bpftrace demos/dns-simple.bt
```

**What it monitors**: Network packets that could be DNS traffic  
**Technology**: eBPF network tracepoints  
**Requirements**: **sudo required**, bpftrace, networking knowledge  
**Good for**: Advanced users, network packet analysis  

**Sample Output**:
```
🔍 Monitoring DNS-like traffic (packet size 20-512 bytes)
📤 Outbound: ping sent 64 bytes
📥 Inbound: received 64 bytes
```

---

## Interactive Demo Menu

When you run `make demo-dns-monitor` or `sudo ./demos/run-dns-demo.sh`, you get:

```
╔══════════════════════════════════════════════════════════════╗
║                    VM Lab eBPF Demo                         ║
║              DNS Monitoring with bpftrace                   ║
╚══════════════════════════════════════════════════════════════╝

Select Demo Type:
1) Container logs monitoring (simplest, no eBPF needed)
2) eBPF process monitoring (intermediate)  
3) eBPF network packets (advanced)
4) All demos with traffic generation
5) Show all monitoring scripts
6) Exit
```

### Menu Options Explained

**Option 1**: Perfect for beginners, shows actual DNS server activity (**no sudo needed**)  
**Option 2**: Good introduction to eBPF without complex networking (**sudo required**)  
**Option 3**: Advanced eBPF for network engineers (**sudo required**)  
**Option 4**: Runs multiple demos simultaneously with automatic test traffic (**sudo required**)  
**Option 5**: Shows the actual script code for learning (**no sudo needed**)  

---

## 🔐 Sudo Requirements Summary

| Demo Type | Sudo Required? | Reason |
|-----------|----------------|---------|
| **Container Logs** | ❌ No | Only reads Docker logs |
| **eBPF Process** | ✅ Yes | eBPF requires root access |
| **eBPF Network** | ✅ Yes | eBPF requires root access |
| **Interactive Menu** | ✅ Yes | Accesses eBPF options |
| **Show Scripts** | ❌ No | Only displays code |

**Quick Rule**: If it says "eBPF" or "bpftrace", you need `sudo` ⚡

---

## Command Line Options

### Direct Script Execution
```bash
# Interactive menu (recommended)
sudo ./demos/run-dns-demo.sh

# Quick simple demo (30 seconds)
sudo ./demos/run-dns-demo.sh --simple

# Quick detailed demo (30 seconds)  
sudo ./demos/run-dns-demo.sh --detailed

# Show help
./demos/run-dns-demo.sh --help
```

### Individual eBPF Scripts
```bash
# Basic process monitoring
sudo bpftrace demos/dns-ultra-simple.bt

# Network packet monitoring
sudo bpftrace demos/dns-simple.bt

# Advanced DNS monitoring (unused in menu)
sudo bpftrace demos/bpftrace-dns-monitor.bt
```

---

## Generating Test Traffic

While demos are running, generate DNS queries to see activity:

### From Host System
```bash
# Basic DNS queries
nslookup test-container.hybrid.local 10.0.1.2
dig @10.0.1.2 gateway.hybrid.local
ping test-container.hybrid.local

# Multiple queries for testing
for i in {1..5}; do 
    nslookup gateway.hybrid.local 10.0.1.2
    sleep 1
done
```

### From VM (if you have one running)
```bash
# SSH into a VM and run:
ping test-container.hybrid.local
curl http://test-container.hybrid.local
nslookup dns.hybrid.local
```

### From Container
```bash
# Test from containers to VMs
docker exec test-container ping gateway.hybrid.local
docker exec test-container nslookup dns.hybrid.local
```

---

## Troubleshooting

### Demo Won't Start
```bash
# Check hybrid network status
make hybrid-status

# If hybrid network missing:
make create-hybrid-network
make hybrid-enable-dns

# Check Docker containers
docker ps | grep hybrid
```

### No eBPF Output
```bash
# Check if bpftrace is installed
which bpftrace

# Install bpftrace (Ubuntu/Debian)
sudo apt install bpftrace linux-headers-$(uname -r)

# Try a simple test
sudo bpftrace -e 'BEGIN { printf("eBPF works!\n"); exit(); }'
```

### No DNS Activity Visible
```bash
# Check if DNS container is logging
docker logs hybrid-dns

# Generate more obvious traffic
ping -c 10 test-container.hybrid.local

# Check if DNS server is responding
nslookup gateway.hybrid.local 10.0.1.2
```

### Permission Denied
```bash
# eBPF requires root
sudo ./demos/run-dns-demo.sh

# Or use container monitoring (no sudo needed)
./demos/dns-container-monitor.sh
```

---

## Learning Path

### For Beginners
1. Start with: `make demo-dns-monitor` → Option 1
2. Generate traffic: `ping test-container.hybrid.local`
3. Understand: DNS queries go to 10.0.1.2, get resolved
4. Next step: Try Option 2 (process monitoring)

### For Intermediate Users  
1. Run: `sudo bpftrace demos/dns-ultra-simple.bt`
2. In another terminal: Generate various DNS queries
3. Observe: System calls related to DNS resolution
4. Study: The bpftrace script to understand tracepoints

### For Advanced Users
1. Run: `sudo bpftrace demos/dns-simple.bt`
2. Generate: High-frequency DNS queries
3. Analyze: Network-level packet patterns
4. Extend: Modify scripts for custom monitoring

### For Experts
1. Study: All bpftrace scripts in `demos/`
2. Create: Custom monitoring for your use cases
3. Integrate: With production monitoring systems
4. Contribute: New demo scripts to the project

---

## Demo Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Demo Monitoring Stack                  │
├─────────────────────────────────────────────────────────────┤
│ eBPF Network Monitoring (Advanced)                         │
│   • Network packet tracepoints                             │
│   • Kernel-level network stack visibility                  │
├─────────────────────────────────────────────────────────────┤
│ eBPF Process Monitoring (Intermediate)                     │  
│   • System call tracepoints                                │
│   • DNS configuration file access                          │
├─────────────────────────────────────────────────────────────┤
│ Container Log Monitoring (Simple)                          │
│   • Docker logs from hybrid-dns container                  │
│   • Real DNS query/response logging                        │
├─────────────────────────────────────────────────────────────┤
│              Hybrid Network Infrastructure                  │
│   VMs (10.0.1.x) ←→ DNS (10.0.1.2) ←→ Containers         │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Details

### Files and Their Purpose

| File | Type | Purpose | Requirements |
|------|------|---------|--------------|
| `run-dns-demo.sh` | Shell Script | Interactive demo launcher | None |
| `dns-container-monitor.sh` | Shell Script | Simplest DNS monitoring | Docker |
| `dns-ultra-simple.bt` | bpftrace | Process-level DNS monitoring | sudo, bpftrace |
| `dns-simple.bt` | bpftrace | Network packet monitoring | sudo, bpftrace |
| `bpftrace-dns-monitor.bt` | bpftrace | Complex DNS tracing (unused) | sudo, bpftrace |
| `dns-oneliner.bt` | bpftrace | Minimal eBPF example | sudo, bpftrace |

### Network Flow During Demos

1. **DNS Query Generated**: VM/Container/Host queries .hybrid.local domain
2. **systemd-resolved Routes**: Query sent to 10.0.1.2 (hybrid-dns container)
3. **dnsmasq Processes**: DNS server looks up hostname in hosts file
4. **Response Returned**: IP address sent back to requester
5. **Connection Established**: Original application connects to resolved IP

### Monitoring Points

- **Container Logs**: DNS server query/response logging
- **System Calls**: Process access to DNS configuration files
- **Network Packets**: Layer 3/4 network traffic patterns
- **Application Layer**: Actual DNS protocol messages

---

## Integration with VM Lab

These demos showcase VM Lab's unique hybrid networking capabilities:

- **Cross-Platform DNS**: VMs and containers resolve each other's hostnames
- **Service Discovery**: Applications find services regardless of platform
- **Network Monitoring**: Real-time visibility into hybrid infrastructure
- **Educational Value**: Learn modern networking and eBPF techniques

The demos work specifically because of VM Lab's hybrid network implementation, making them both educational tools and practical examples of the infrastructure's capabilities.

---

## Contributing New Demos

Want to add more demos? Follow this pattern:

1. **Create demo script**: `demos/my-new-demo.sh`
2. **Add bpftrace scripts**: `demos/my-monitoring.bt` 
3. **Update Makefile**: Add `make demo-my-demo` target
4. **Add README section**: Document the new demo here
5. **Test thoroughly**: Ensure it works across different systems

Demo scripts should:
- Check prerequisites automatically
- Provide clear output with colored logging
- Include help/usage information
- Work with existing hybrid network infrastructure
- Follow the educational progression pattern

---

## Support

- **Documentation**: See `docs/hybrid-networking/` for technical details
- **Troubleshooting**: Use `make hybrid-debug` for network diagnostics  
- **Tools Reference**: See `docs/hybrid-networking/TOOLS_REFERENCE.md`
- **Issues**: Report problems in the project's GitHub issues