# Advanced Hybrid Networking Examples

## Phase 4 Features: DNS + Monitoring + Advanced Use Cases

This guide demonstrates advanced hybrid networking scenarios using VM Lab's Phase 4 features including DNS service discovery, network monitoring, and complex multi-tier applications.

## Prerequisites

```bash
# Ensure hybrid networking is set up
make create-hybrid-network

# Enable DNS service discovery
make hybrid-enable-dns

# Verify everything is working
make hybrid-status
```

## Example 1: Microservices Architecture with VM Database

**Scenario**: Modern containerized microservices with a traditional PostgreSQL database running on a VM.

### Step 1: Create Database VM

```bash
# Create VM with hybrid networking
make hybrid-base NAME=postgres-vm

# SSH into VM and install PostgreSQL
make ssh NAME=postgres-vm
```

Inside the VM:
```bash
# Install PostgreSQL
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Configure PostgreSQL
sudo -u postgres createuser --superuser app
sudo -u postgres createdb appdb
sudo -u postgres psql -c "ALTER USER app PASSWORD 'securepass123';"

# Configure PostgreSQL to listen on hybrid network
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
echo "host all all 10.0.1.0/24 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# Restart PostgreSQL
sudo systemctl restart postgresql

# Test database is ready
psql -h postgres-vm.hybrid.local -U app -d appdb -c "SELECT 'Database ready!'"
```

### Step 2: Deploy Microservices

```bash
# Deploy API service
docker run -d \
  --name user-api \
  --network hybrid-net \
  --hostname user-api \
  -e DATABASE_URL="postgresql://app:securepass123@postgres-vm.hybrid.local:5432/appdb" \
  -p 3001:3000 \
  node:18-alpine sh -c '
    npm init -y && npm install express pg &&
    cat > app.js << "EOF"
const express = require("express");
const { Client } = require("pg");
const app = express();

const client = new Client({ connectionString: process.env.DATABASE_URL });
client.connect();

app.get("/health", (req, res) => res.json({ status: "healthy", database: "connected" }));
app.get("/users", async (req, res) => {
  const result = await client.query("SELECT current_timestamp as server_time");
  res.json({ message: "Users API", db_time: result.rows[0].server_time });
});

app.listen(3000, () => console.log("User API running on port 3000"));
EOF
    node app.js
  '

# Deploy frontend service  
docker run -d \
  --name web-frontend \
  --network hybrid-net \
  --hostname web-frontend \
  -e API_URL="http://user-api.hybrid.local:3000" \
  -p 80:80 \
  nginx:alpine sh -c '
    cat > /etc/nginx/conf.d/default.conf << "EOF"
server {
    listen 80;
    location /api/ {
        proxy_pass http://user-api.hybrid.local:3000/;
    }
    location / {
        return 200 "Frontend -> API: $(API_URL)\nHostname resolution working!";
        add_header Content-Type text/plain;
    }
}
EOF
    nginx -g "daemon off;"
  '

# Update DNS records to include new services
make hybrid-update-dns
```

### Step 3: Test the Complete System

```bash
# Test database connectivity from host
dig +short postgres-vm.hybrid.local @10.0.1.2

# Test API service
curl http://user-api.hybrid.local:3001/health

# Test frontend service
curl http://web-frontend.hybrid.local/

# Monitor network traffic
make hybrid-monitor
```

## Example 2: Load Balancer with Multiple Backend VMs

**Scenario**: HAProxy load balancer container distributing traffic to multiple backend VMs.

### Step 1: Create Backend VMs

```bash
# Create multiple web server VMs
make hybrid-base NAME=web1
make hybrid-base NAME=web2

# Configure web servers on each VM
for vm in web1 web2; do
  make ssh NAME=$vm -c '
    sudo apt install -y nginx
    echo "<h1>Server: $(hostname)</h1><p>IP: $(ip addr show enp0s8 | grep inet | head -1 | awk "{print $2}")</p>" | sudo tee /var/www/html/index.html
    sudo systemctl start nginx
  '
done
```

### Step 2: Deploy Load Balancer

```bash
# Create HAProxy configuration
mkdir -p /tmp/haproxy-config
cat > /tmp/haproxy-config/haproxy.cfg << 'EOF'
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend web_frontend
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    server web1 web1.hybrid.local:80 check
    server web2 web2.hybrid.local:80 check
    
    # Health check endpoint
    option httpchk GET /
EOF

# Deploy HAProxy container
docker run -d \
  --name load-balancer \
  --network hybrid-net \
  --hostname load-balancer \
  -p 8080:80 \
  -v /tmp/haproxy-config:/usr/local/etc/haproxy:ro \
  haproxy:alpine

# Update DNS
make hybrid-update-dns
```

### Step 3: Test Load Balancing

```bash
# Test load balancing
for i in {1..6}; do
  echo "Request $i:"
  curl -s http://load-balancer.hybrid.local:8080/ | grep -E "(Server:|IP:)"
  echo
done

# Monitor connections
make hybrid-debug
```

## Example 3: Service Mesh with VM and Container Services

**Scenario**: Complex service mesh with service discovery, health checks, and monitoring.

### Step 1: Deploy Monitoring Infrastructure

```bash
# Create monitoring VM for Prometheus
make hybrid-base NAME=monitoring-vm

# Configure Prometheus on VM
make ssh NAME=monitoring-vm -c '
  # Install Prometheus
  wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
  tar xvf prometheus-2.45.0.linux-amd64.tar.gz
  sudo mv prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/
  sudo mv prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/
  
  # Create Prometheus config
  sudo mkdir -p /etc/prometheus
  cat > /tmp/prometheus.yml << "EOF"
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "hybrid-services"
    dns_sd_configs:
      - names: ["_http._tcp.hybrid.local"]
        type: A
        port: 9090
    static_configs:
      - targets:
        - "gateway.hybrid.local:9090"
        - "user-api.hybrid.local:3001"
        - "web-frontend.hybrid.local:80"
EOF
  sudo mv /tmp/prometheus.yml /etc/prometheus/
  
  # Start Prometheus
  nohup prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/tmp/prometheus --web.listen-address=0.0.0.0:9090 &
'
```

### Step 2: Deploy Service Registry

```bash
# Deploy Consul for service discovery
docker run -d \
  --name consul \
  --network hybrid-net \
  --hostname consul \
  -p 8500:8500 \
  consul:latest agent -server -bootstrap-expect=1 -ui -client=0.0.0.0

# Register services in Consul
docker exec consul consul services register -name=user-api -address=user-api.hybrid.local -port=3000
docker exec consul consul services register -name=frontend -address=web-frontend.hybrid.local -port=80
docker exec consul consul services register -name=postgres -address=postgres-vm.hybrid.local -port=5432

# Update DNS
make hybrid-update-dns
```

### Step 3: Advanced Service Communication

```bash
# Deploy service that uses consul for discovery
docker run -d \
  --name service-mesh-demo \
  --network hybrid-net \
  --hostname service-mesh \
  node:18-alpine sh -c '
    npm init -y && npm install express axios consul &&
    cat > mesh.js << "EOF"
const express = require("express");
const consul = require("consul")({ host: "consul.hybrid.local" });

const app = express();

app.get("/services", async (req, res) => {
  const services = await consul.catalog.service.list();
  res.json(services);
});

app.get("/discover/:service", async (req, res) => {
  const service = await consul.catalog.service.nodes(req.params.service);
  res.json(service);
});

app.listen(4000, () => console.log("Service mesh demo on port 4000"));
EOF
    node mesh.js
  '
```

## Example 4: Development Environment with Hot Reload

**Scenario**: Complete development environment where containers can communicate with development services running on VMs.

### Step 1: Development VM Setup

```bash
# Create development VM
make hybrid-docker NAME=dev-env

# Setup development environment
make ssh NAME=dev-env -c '
  # Install Node.js, Python, and development tools
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs python3-pip redis-tools postgresql-client
  
  # Clone a sample project (or create one)
  git clone https://github.com/example/sample-app.git || echo "Using local development"
  
  # Start development server that listens on hybrid network
  mkdir -p /app && cd /app
  npm init -y
  npm install express cors
  cat > server.js << "EOF"
const express = require("express");
const app = express();

app.use(require("cors")());
app.get("/dev-api/status", (req, res) => {
  res.json({ 
    status: "development server running",
    hostname: require("os").hostname(),
    timestamp: new Date().toISOString()
  });
});

app.listen(3000, "0.0.0.0", () => console.log("Dev server running"));
EOF
  
  # Start development server
  nohup node server.js &
'
```

### Step 2: Supporting Services as Containers

```bash
# Redis for caching
docker run -d \
  --name redis-cache \
  --network hybrid-net \
  --hostname redis-cache \
  redis:alpine redis-server --bind 0.0.0.0

# Development database
docker run -d \
  --name dev-postgres \
  --network hybrid-net \
  --hostname dev-postgres \
  -e POSTGRES_PASSWORD=devpass \
  -e POSTGRES_DB=devdb \
  postgres:alpine

# Hot-reloading proxy
docker run -d \
  --name dev-proxy \
  --network hybrid-net \
  --hostname dev-proxy \
  -p 3000:3000 \
  nginx:alpine sh -c '
    cat > /etc/nginx/conf.d/default.conf << "EOF"
upstream dev_backend {
    server dev-env.hybrid.local:3000;
}

server {
    listen 3000;
    location / {
        proxy_pass http://dev_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # WebSocket support for hot reload
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
    nginx -g "daemon off;"
  '

# Update DNS for all services
make hybrid-update-dns
```

### Step 3: Test Development Environment

```bash
# Test service discovery
curl http://dev-env.hybrid.local:3000/dev-api/status

# Test database connection from VM
make ssh NAME=dev-env -c 'pg_isready -h dev-postgres.hybrid.local -p 5432'

# Test Redis connection from VM  
make ssh NAME=dev-env -c 'redis-cli -h redis-cache.hybrid.local ping'

# Monitor development traffic
make hybrid-monitor
```

## Network Monitoring and Debugging

### Real-time Network Monitoring

```bash
# Monitor hybrid network traffic
make hybrid-monitor

# Get detailed diagnostics
make hybrid-debug

# Watch DNS queries
make hybrid-logs

# Custom monitoring script
cat > /tmp/hybrid-monitor.sh << 'EOF'
#!/bin/bash
while true; do
    echo "=== $(date) ==="
    echo "Active connections to hybrid services:"
    netstat -tan | grep ":80\|:443\|:3000\|:5432" | grep ESTABLISHED | wc -l
    echo "DNS queries in last minute:"
    docker logs hybrid-dns --since 1m 2>/dev/null | grep -c "query" || echo "0"
    echo "Bridge traffic:"
    cat /proc/net/dev | grep hybr0 | awk '{printf "RX: %s MB, TX: %s MB\n", $2/1024/1024, $10/1024/1024}'
    echo ""
    sleep 10
done
EOF
chmod +x /tmp/hybrid-monitor.sh
/tmp/hybrid-monitor.sh
```

### DNS Troubleshooting

```bash
# Test DNS resolution from different components
echo "Testing DNS resolution:"

# From host
echo "Host -> gateway: $(dig +short @10.0.1.2 gateway.hybrid.local)"

# From container
docker exec user-api nslookup postgres-vm.hybrid.local 10.0.1.2

# From VM (if VM is running)
# make ssh NAME=postgres-vm -c "nslookup user-api.hybrid.local 10.0.1.2"

# Check DNS container health
docker exec hybrid-dns cat /etc/hosts
docker exec hybrid-dns dnsmasq --test
```

### Performance Testing

```bash
# Network latency test between services
echo "Network latency tests:"

# VM to Container
make ssh NAME=postgres-vm -c "ping -c 5 user-api.hybrid.local"

# Container to VM  
docker exec user-api ping -c 5 postgres-vm.hybrid.local

# Container to Container
docker exec user-api ping -c 5 web-frontend.hybrid.local

# Bandwidth test (if iperf3 is available)
# docker run --rm --network hybrid-net networkstatic/iperf3 -c postgres-vm.hybrid.local
```

## Best Practices for Advanced Scenarios

### 1. Service Health Checks

```bash
# Health check script
cat > /tmp/service-health.sh << 'EOF'
#!/bin/bash
services=("user-api.hybrid.local:3001/health" "web-frontend.hybrid.local/" "postgres-vm.hybrid.local:5432")

for service in "${services[@]}"; do
    if curl -sf "http://$service" >/dev/null 2>&1; then
        echo "✓ $service - healthy"
    else
        echo "✗ $service - unhealthy"
    fi
done
EOF
chmod +x /tmp/service-health.sh
/tmp/service-health.sh
```

### 2. Automated Service Discovery

```bash
# Auto-register new services
make hybrid-update-dns

# Verify all services are discoverable
dig +short @10.0.1.2 -t ANY hybrid.local
```

### 3. Security Considerations

```bash
# Check network policies (firewall rules)
make hybrid-debug | grep -A 10 "Iptables rules"

# Monitor suspicious network activity
make hybrid-logs | grep -E "(NXDOMAIN|refused|error)"
```

### 4. Backup and Recovery

```bash
# Backup hybrid network configuration
tar -czf hybrid-network-backup.tar.gz \
  /tmp/hybrid-dns-config \
  /home/dev/Desktop/vm-lab/vms/.hybrid-ips

# Export service configurations
docker network inspect hybrid-net > hybrid-network-config.json
```

## Cleanup

```bash
# Stop all services
docker stop $(docker ps -q --filter network=hybrid-net)

# Remove containers
docker rm $(docker ps -aq --filter network=hybrid-net)

# Stop VMs
make stop NAME=postgres-vm
make stop NAME=web1  
make stop NAME=web2
make stop NAME=monitoring-vm
make stop NAME=dev-env

# Disable DNS if desired
make hybrid-disable-dns

# Full cleanup (destroys everything)
# make destroy-hybrid-network
```

## Troubleshooting Common Issues

### DNS Not Resolving
1. Check DNS service: `make hybrid-status`
2. Update DNS records: `make hybrid-update-dns`
3. Check logs: `make hybrid-logs`

### Service Can't Connect
1. Test connectivity: `make hybrid-test-connectivity`
2. Check firewall: `make hybrid-debug`
3. Verify network: `docker network inspect hybrid-net`

### Poor Performance
1. Monitor traffic: `make hybrid-monitor`
2. Check resource usage: `docker stats`
3. Review bridge stats: `cat /proc/net/dev | grep hybr0`

These advanced examples demonstrate the power of VM Lab's hybrid networking with DNS service discovery, enabling complex, production-like scenarios for development, testing, and learning.