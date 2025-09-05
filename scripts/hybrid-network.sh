#!/bin/bash

# Hybrid Networking Script for VM Lab
# Manages bridge networking for VM+Docker hybrid communication
# Network: 10.0.1.0/24, Bridge: hybr0, Gateway: 10.0.1.1

set -e

BRIDGE_NAME="hybr0"
NETWORK_CIDR="10.0.1.0/24"
GATEWAY_IP="10.0.1.1"
DOCKER_NETWORK_NAME="hybrid-net"
LIBVIRT_NETWORK_NAME="hybrid-network"
LIBVIRT_NETWORK_XML="/tmp/hybrid-network.xml"
DNS_CONTAINER_NAME="hybrid-dns"
DNS_IP="10.0.1.2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_bridge_exists() {
    ip link show "$BRIDGE_NAME" &>/dev/null
}

check_docker_network_exists() {
    docker network ls --format "{{.Name}}" | grep -q "^${DOCKER_NETWORK_NAME}$"
}

check_libvirt_network_exists() {
    virsh net-list --all --name | grep -q "^${LIBVIRT_NETWORK_NAME}$"
}

check_dns_container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^${DNS_CONTAINER_NAME}$"
}

create_bridge() {
    if check_bridge_exists; then
        log_info "Bridge $BRIDGE_NAME already exists"
        return 0
    fi
    
    log_info "Creating bridge $BRIDGE_NAME..."
    sudo ip link add name "$BRIDGE_NAME" type bridge
    sudo ip addr add "$GATEWAY_IP/24" dev "$BRIDGE_NAME"
    sudo ip link set "$BRIDGE_NAME" up
    log_success "Bridge $BRIDGE_NAME created successfully"
}

create_docker_network() {
    if check_docker_network_exists; then
        log_info "Docker network $DOCKER_NETWORK_NAME already exists"
        return 0
    fi
    
    log_info "Creating Docker network $DOCKER_NETWORK_NAME..."
    docker network create \
        --driver bridge \
        --subnet="$NETWORK_CIDR" \
        --gateway="$GATEWAY_IP" \
        --opt com.docker.network.bridge.name="$BRIDGE_NAME" \
        "$DOCKER_NETWORK_NAME"
    log_success "Docker network $DOCKER_NETWORK_NAME created successfully"
}

create_libvirt_network_xml() {
    cat > "$LIBVIRT_NETWORK_XML" << EOF
<network>
  <name>$LIBVIRT_NETWORK_NAME</name>
  <forward mode='bridge'/>
  <bridge name='$BRIDGE_NAME'/>
</network>
EOF
}

create_libvirt_network() {
    if check_libvirt_network_exists; then
        log_info "Libvirt network $LIBVIRT_NETWORK_NAME already exists"
        if ! virsh net-list --name | grep -q "^${LIBVIRT_NETWORK_NAME}$"; then
            log_info "Starting libvirt network $LIBVIRT_NETWORK_NAME..."
            sudo virsh net-start "$LIBVIRT_NETWORK_NAME"
        fi
        return 0
    fi
    
    log_info "Creating libvirt network $LIBVIRT_NETWORK_NAME..."
    create_libvirt_network_xml
    sudo virsh net-define "$LIBVIRT_NETWORK_XML"
    sudo virsh net-start "$LIBVIRT_NETWORK_NAME"
    sudo virsh net-autostart "$LIBVIRT_NETWORK_NAME"
    rm -f "$LIBVIRT_NETWORK_XML"
    log_success "Libvirt network $LIBVIRT_NETWORK_NAME created successfully"
}

create_dns_container() {
    if check_dns_container_exists; then
        log_info "DNS container $DNS_CONTAINER_NAME already exists"
        if ! docker ps --format "{{.Names}}" | grep -q "^${DNS_CONTAINER_NAME}$"; then
            log_info "Starting DNS container $DNS_CONTAINER_NAME..."
            docker start "$DNS_CONTAINER_NAME"
        fi
        return 0
    fi
    
    log_info "Creating DNS container $DNS_CONTAINER_NAME..."
    
    # Create dnsmasq configuration
    local dns_config_dir="/tmp/hybrid-dns-config"
    mkdir -p "$dns_config_dir"
    
    cat > "$dns_config_dir/dnsmasq.conf" << EOF
# Hybrid network DNS configuration
interface=eth0
listen-address=$DNS_IP
bind-interfaces

# Domain for hybrid network
domain=hybrid.local
expand-hosts

# DNS forwarding
server=8.8.8.8
server=8.8.4.4

# DHCP is disabled - we use static IPs
no-dhcp-interface=eth0

# Log queries for debugging
log-queries
log-facility=/var/log/dnsmasq.log

# Host resolution
address=/gateway.hybrid.local/$GATEWAY_IP
address=/dns.hybrid.local/$DNS_IP

# Enable reverse DNS
ptr-record=1.1.0.10.in-addr.arpa,gateway.hybrid.local
ptr-record=2.1.0.10.in-addr.arpa,dns.hybrid.local
EOF
    
    cat > "$dns_config_dir/hosts" << EOF
$GATEWAY_IP gateway gateway.hybrid.local
$DNS_IP dns dns.hybrid.local hybrid-dns
EOF
    
    # Create DNS container with dnsmasq
    docker run -d \
        --name "$DNS_CONTAINER_NAME" \
        --network "$DOCKER_NETWORK_NAME" \
        --ip "$DNS_IP" \
        --cap-add=NET_ADMIN \
        --dns=8.8.8.8 \
        -v "$dns_config_dir/dnsmasq.conf:/etc/dnsmasq.conf:ro" \
        -v "$dns_config_dir/hosts:/etc/hosts:ro" \
        --restart=unless-stopped \
        strm/dnsmasq \
        --log-facility=-
        
    log_success "DNS container $DNS_CONTAINER_NAME created successfully"
}

update_dns_records() {
    if ! check_dns_container_exists; then
        log_warning "DNS container not found, skipping DNS record update"
        return 1
    fi
    
    local dns_config_dir="/tmp/hybrid-dns-config"
    local hosts_file="$dns_config_dir/hosts"
    
    log_info "Updating DNS records..."
    
    # Start with base entries
    cat > "$hosts_file" << EOF
$GATEWAY_IP gateway gateway.hybrid.local
$DNS_IP dns dns.hybrid.local hybrid-dns
EOF
    
    # Add Docker container entries
    if check_docker_network_exists; then
        docker network inspect "$DOCKER_NETWORK_NAME" --format "{{range .Containers}}{{.Name}} {{.IPv4Address}}{{printf \"\n\"}}{{end}}" | while read name ip; do
            if [[ -n "$name" && -n "$ip" && "$name" != "$DNS_CONTAINER_NAME" ]]; then
                ip_only=$(echo "$ip" | cut -d/ -f1)
                echo "$ip_only $name $name.hybrid.local" >> "$hosts_file"
            fi
        done
    fi
    
    # Add VM entries
    if check_libvirt_network_exists; then
        for vm in $(virsh list --all --name); do
            if [[ -n "$vm" ]]; then
                local vm_ip=$(get_vm_hybrid_ip "$vm")
                if [[ -n "$vm_ip" ]]; then
                    echo "$vm_ip $vm $vm.hybrid.local" >> "$hosts_file"
                fi
            fi
        done
    fi
    
    # Reload DNS container to pick up new hosts file
    docker exec "$DNS_CONTAINER_NAME" pkill -SIGHUP dnsmasq 2>/dev/null || true
    
    log_success "DNS records updated"
}

get_vm_hybrid_ip() {
    local vm_name="$1"
    
    # Try to get IP from domifaddr
    local ip=$(virsh domifaddr "$vm_name" 2>/dev/null | awk '/10\.0\.1\./ {print $4}' | cut -d/ -f1)
    
    # If not found, check if it's a custom VM with recorded IP
    if [[ -z "$ip" ]]; then
        local ip_file="${SCRIPT_DIR}/vms/.hybrid-ips"
        if [[ -f "$ip_file" ]]; then
            ip=$(grep "^$vm_name=" "$ip_file" 2>/dev/null | cut -d= -f2)
        fi
    fi
    
    echo "$ip"
}

destroy_bridge() {
    if ! check_bridge_exists; then
        log_info "Bridge $BRIDGE_NAME does not exist"
        return 0
    fi
    
    log_info "Destroying bridge $BRIDGE_NAME..."
    sudo ip link set "$BRIDGE_NAME" down
    sudo ip link delete "$BRIDGE_NAME"
    log_success "Bridge $BRIDGE_NAME destroyed successfully"
}

destroy_docker_network() {
    if ! check_docker_network_exists; then
        log_info "Docker network $DOCKER_NETWORK_NAME does not exist"
        return 0
    fi
    
    log_info "Destroying Docker network $DOCKER_NETWORK_NAME..."
    docker network rm "$DOCKER_NETWORK_NAME"
    log_success "Docker network $DOCKER_NETWORK_NAME destroyed successfully"
}

destroy_libvirt_network() {
    if ! check_libvirt_network_exists; then
        log_info "Libvirt network $LIBVIRT_NETWORK_NAME does not exist"
        return 0
    fi
    
    log_info "Destroying libvirt network $LIBVIRT_NETWORK_NAME..."
    if virsh net-list --name | grep -q "^${LIBVIRT_NETWORK_NAME}$"; then
        sudo virsh net-destroy "$LIBVIRT_NETWORK_NAME"
    fi
    sudo virsh net-undefine "$LIBVIRT_NETWORK_NAME"
    log_success "Libvirt network $LIBVIRT_NETWORK_NAME destroyed successfully"
}

destroy_dns_container() {
    if ! check_dns_container_exists; then
        log_info "DNS container $DNS_CONTAINER_NAME does not exist"
        return 0
    fi
    
    log_info "Destroying DNS container $DNS_CONTAINER_NAME..."
    docker stop "$DNS_CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$DNS_CONTAINER_NAME" >/dev/null 2>&1 || true
    
    # Clean up config directory
    rm -rf "/tmp/hybrid-dns-config"
    
    log_success "DNS container $DNS_CONTAINER_NAME destroyed successfully"
}

show_status() {
    echo ""
    echo "=== HYBRID NETWORK STATUS ==="
    echo ""
    
    # Bridge status
    if check_bridge_exists; then
        echo -e "${GREEN}✓${NC} Bridge: $BRIDGE_NAME"
        echo "  $(ip addr show $BRIDGE_NAME | grep inet)"
        echo "  Connected devices:"
        if command -v brctl &> /dev/null; then
            brctl show "$BRIDGE_NAME" | tail -n +2 | sed 's/^/    /'
        else
            bridge link show | grep "$BRIDGE_NAME" | sed 's/^/    /' || echo "    (no devices connected)"
        fi
    else
        echo -e "${RED}✗${NC} Bridge: $BRIDGE_NAME (not found)"
    fi
    echo ""
    
    # Docker network status
    if check_docker_network_exists; then
        echo -e "${GREEN}✓${NC} Docker Network: $DOCKER_NETWORK_NAME"
        docker network inspect "$DOCKER_NETWORK_NAME" --format "  Network: {{.IPAM.Config}} Bridge: {{.Options}}" || true
        echo "  Connected containers:"
        docker network inspect "$DOCKER_NETWORK_NAME" --format "{{range .Containers}}    {{.Name}} ({{.IPv4Address}}){{end}}" || echo "    (no containers connected)"
    else
        echo -e "${RED}✗${NC} Docker Network: $DOCKER_NETWORK_NAME (not found)"
    fi
    echo ""
    
    # Libvirt network status  
    if check_libvirt_network_exists; then
        echo -e "${GREEN}✓${NC} Libvirt Network: $LIBVIRT_NETWORK_NAME"
        if virsh net-list --name | grep -q "^${LIBVIRT_NETWORK_NAME}$"; then
            echo "  Status: Active"
        else
            echo "  Status: Inactive"
        fi
        echo "  Connected VMs:"
        for vm in $(virsh list --all --name); do
            if [ -n "$vm" ] && virsh domiflist "$vm" 2>/dev/null | grep -q "$LIBVIRT_NETWORK_NAME"; then
                ip=$(virsh domifaddr "$vm" 2>/dev/null | awk '/'"$LIBVIRT_NETWORK_NAME"'/ {print $4}' | cut -d/ -f1)
                echo "    $vm ($ip)"
            fi
        done
    else
        echo -e "${RED}✗${NC} Libvirt Network: $LIBVIRT_NETWORK_NAME (not found)"
    fi
    echo ""
    
    # DNS service status
    if check_dns_container_exists; then
        echo -e "${GREEN}✓${NC} DNS Service: $DNS_CONTAINER_NAME"
        if docker ps --format "{{.Names}}" | grep -q "^${DNS_CONTAINER_NAME}$"; then
            echo "  Status: Running at $DNS_IP"
            echo "  Domain: hybrid.local"
            echo "  Available hosts:"
            if [[ -f "/tmp/hybrid-dns-config/hosts" ]]; then
                sed 's/^/    /' "/tmp/hybrid-dns-config/hosts" | head -10
                local host_count=$(wc -l < "/tmp/hybrid-dns-config/hosts")
                if [[ $host_count -gt 10 ]]; then
                    echo "    ... and $((host_count - 10)) more hosts"
                fi
            fi
        else
            echo "  Status: Stopped"
        fi
    else
        echo -e "${RED}✗${NC} DNS Service: $DNS_CONTAINER_NAME (not found)"
        echo "  Run 'make hybrid-enable-dns' to enable service discovery"
    fi
    echo ""
}

test_connectivity() {
    echo ""
    echo "=== HYBRID NETWORK CONNECTIVITY TEST ==="
    echo ""
    
    # Test if bridge is reachable from host
    log_info "Testing host connectivity to bridge gateway..."
    if ping -c 2 -W 1 "$GATEWAY_IP" >/dev/null 2>&1; then
        log_success "Host → Bridge Gateway ($GATEWAY_IP): OK"
    else
        log_error "Host → Bridge Gateway ($GATEWAY_IP): FAILED"
    fi
    
    # Test Docker containers
    if check_docker_network_exists; then
        log_info "Testing Docker container connectivity..."
        containers=$(docker network inspect "$DOCKER_NETWORK_NAME" --format "{{range .Containers}}{{.Name}}:{{.IPv4Address}} {{end}}" 2>/dev/null | tr ' ' '\n' | grep -v '^$')
        if [ -n "$containers" ]; then
            echo "$containers" | while read container_info; do
                container_name=$(echo "$container_info" | cut -d: -f1)
                container_ip=$(echo "$container_info" | cut -d: -f2 | cut -d/ -f1)
                if ping -c 2 -W 1 "$container_ip" >/dev/null 2>&1; then
                    log_success "Host → Container $container_name ($container_ip): OK"
                else
                    log_error "Host → Container $container_name ($container_ip): FAILED"
                fi
            done
        else
            log_info "No Docker containers connected to hybrid network"
        fi
    fi
    
    # Test VMs  
    if check_libvirt_network_exists; then
        log_info "Testing VM connectivity..."
        vm_found=false
        for vm in $(virsh list --all --name); do
            if [ -n "$vm" ] && virsh domiflist "$vm" 2>/dev/null | grep -q "$LIBVIRT_NETWORK_NAME"; then
                vm_found=true
                ip=$(virsh domifaddr "$vm" 2>/dev/null | awk '/vnet/ && /10\.0\.1\./ {print $4}' | cut -d/ -f1)
                if [ -n "$ip" ]; then
                    if ping -c 2 -W 1 "$ip" >/dev/null 2>&1; then
                        log_success "Host → VM $vm ($ip): OK"
                    else
                        log_error "Host → VM $vm ($ip): FAILED"
                    fi
                else
                    log_warning "VM $vm connected to hybrid network but no IP detected"
                fi
            fi
        done
        if [ "$vm_found" = false ]; then
            log_info "No VMs connected to hybrid network"
        fi
    fi
    
    echo ""
}

ensure_network() {
    create_bridge
    create_docker_network  
    create_libvirt_network
}

ensure_network_with_dns() {
    ensure_network
    create_dns_container
    update_dns_records
}

monitor_network() {
    echo ""
    echo "=== HYBRID NETWORK MONITORING ==="
    echo ""
    
    # Real-time network statistics
    log_info "Bridge traffic statistics:"
    if command -v iftop &> /dev/null; then
        echo "Starting iftop monitoring (press 'q' to quit)..."
        sudo iftop -i "$BRIDGE_NAME" -t -L 20
    else
        echo "Bridge interface stats:"
        cat /proc/net/dev | grep "$BRIDGE_NAME" | awk '{printf "  RX: %s bytes, %s packets\n  TX: %s bytes, %s packets\n", $2, $3, $10, $11}'
        
        echo ""
        echo "Monitoring bridge traffic (press Ctrl+C to stop)..."
        while true; do
            echo -n "$(date '+%H:%M:%S') - "
            cat /proc/net/dev | grep "$BRIDGE_NAME" | awk '{printf "RX: %s bytes TX: %s bytes\r", $2, $10}'
            sleep 2
        done
    fi
}

debug_network() {
    echo ""
    echo "=== HYBRID NETWORK DIAGNOSTICS ==="
    echo ""
    
    # Bridge detailed information
    log_info "Bridge configuration:"
    ip addr show "$BRIDGE_NAME" | sed 's/^/  /'
    echo ""
    
    log_info "Bridge forwarding table:"
    if command -v brctl &> /dev/null; then
        brctl showmacs "$BRIDGE_NAME" | head -20 | sed 's/^/  /'
    else
        bridge fdb show br "$BRIDGE_NAME" | head -20 | sed 's/^/  /'
    fi
    echo ""
    
    log_info "Network namespaces:"
    ip netns list | sed 's/^/  /' || echo "  No custom network namespaces found"
    echo ""
    
    # Container network debugging
    if check_docker_network_exists; then
        log_info "Docker network detailed info:"
        docker network inspect "$DOCKER_NETWORK_NAME" --format '{{json .}}' | jq '.' 2>/dev/null || docker network inspect "$DOCKER_NETWORK_NAME"
        echo ""
    fi
    
    # DNS debugging
    if check_dns_container_exists; then
        log_info "DNS container network configuration:"
        docker exec "$DNS_CONTAINER_NAME" ip addr show 2>/dev/null | sed 's/^/  /' || echo "  DNS container not running"
        echo ""
        
        log_info "DNS server test from container:"
        docker exec "$DNS_CONTAINER_NAME" nslookup gateway.hybrid.local localhost 2>/dev/null | sed 's/^/  /' || echo "  DNS lookup failed"
        echo ""
    fi
    
    # VM network debugging
    log_info "Active VMs with hybrid networking:"
    for vm in $(virsh list --name); do
        if [[ -n "$vm" ]] && virsh domiflist "$vm" 2>/dev/null | grep -q "$LIBVIRT_NETWORK_NAME"; then
            echo "  VM: $vm"
            virsh domifaddr "$vm" 2>/dev/null | grep -E "(Name|vnet.*10\.0\.1\.)" | sed 's/^/    /'
        fi
    done
    echo ""
    
    # Route table
    log_info "Host routing table (hybrid network routes):"
    ip route | grep "10.0.1" | sed 's/^/  /' || echo "  No hybrid network routes found"
    echo ""
    
    # Firewall rules
    log_info "Iptables rules (FORWARD chain - bridge traffic):"
    sudo iptables -L FORWARD -v -n | grep -E "(Chain FORWARD|10\.0\.1|$BRIDGE_NAME)" | sed 's/^/  /' || echo "  No specific hybrid network rules"
    echo ""
}

show_dns_logs() {
    if ! check_dns_container_exists; then
        log_error "DNS container not found"
        return 1
    fi
    
    echo ""
    echo "=== DNS CONTAINER LOGS ==="
    echo ""
    
    if docker ps --format "{{.Names}}" | grep -q "^${DNS_CONTAINER_NAME}$"; then
        log_info "Recent DNS queries and activity:"
        docker logs --tail 50 "$DNS_CONTAINER_NAME" 2>/dev/null || echo "No logs available"
        
        echo ""
        log_info "Live DNS logs (press Ctrl+C to stop):"
        docker logs -f "$DNS_CONTAINER_NAME"
    else
        log_warning "DNS container exists but is not running"
        log_info "Container logs from last run:"
        docker logs "$DNS_CONTAINER_NAME" 2>/dev/null || echo "No logs available"
    fi
}

case "$1" in
    create)
        log_info "Creating hybrid network infrastructure..."
        ensure_network
        log_success "Hybrid network infrastructure created successfully!"
        ;;
    destroy)
        log_info "Destroying hybrid network infrastructure..."
        destroy_dns_container
        destroy_docker_network
        destroy_libvirt_network
        destroy_bridge
        log_success "Hybrid network infrastructure destroyed successfully!"
        ;;
    enable-dns)
        log_info "Enabling DNS service discovery..."
        ensure_network_with_dns
        log_success "DNS service discovery enabled successfully!"
        ;;
    disable-dns)
        log_info "Disabling DNS service discovery..."
        destroy_dns_container
        log_success "DNS service discovery disabled!"
        ;;
    update-dns)
        log_info "Updating DNS records..."
        update_dns_records
        log_success "DNS records updated successfully!"
        ;;
    status)
        show_status
        ;;
    test-connectivity)
        test_connectivity
        ;;
    ensure-network)
        ensure_network
        ;;
    monitor)
        log_info "Starting hybrid network monitoring..."
        monitor_network
        ;;
    debug)
        log_info "Running hybrid network diagnostics..."
        debug_network
        ;;
    logs)
        log_info "Showing DNS container logs..."
        show_dns_logs
        ;;
    *)
        echo "Usage: $0 {create|destroy|enable-dns|disable-dns|update-dns|status|test-connectivity|monitor|debug|logs|ensure-network}"
        echo ""
        echo "Commands:"
        echo "  create            - Create hybrid network infrastructure"
        echo "  destroy           - Destroy hybrid network infrastructure"
        echo "  enable-dns        - Enable DNS service discovery (dnsmasq)"
        echo "  disable-dns       - Disable DNS service discovery"
        echo "  update-dns        - Update DNS records for all VMs and containers"
        echo "  status            - Show network status and connected devices"
        echo "  test-connectivity - Test connectivity between all components"
        echo "  monitor           - Real-time network traffic monitoring"
        echo "  debug             - Comprehensive network diagnostics"
        echo "  logs              - Show DNS container logs"
        echo "  ensure-network    - Ensure network exists (create if needed)"
        exit 1
        ;;
esac