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

case "$1" in
    create)
        log_info "Creating hybrid network infrastructure..."
        ensure_network
        log_success "Hybrid network infrastructure created successfully!"
        ;;
    destroy)
        log_info "Destroying hybrid network infrastructure..."
        destroy_docker_network
        destroy_libvirt_network
        destroy_bridge
        log_success "Hybrid network infrastructure destroyed successfully!"
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
    *)
        echo "Usage: $0 {create|destroy|status|test-connectivity|ensure-network}"
        echo ""
        echo "Commands:"
        echo "  create            - Create hybrid network infrastructure"
        echo "  destroy           - Destroy hybrid network infrastructure"  
        echo "  status            - Show network status and connected devices"
        echo "  test-connectivity - Test connectivity between all components"
        echo "  ensure-network    - Ensure network exists (create if needed)"
        exit 1
        ;;
esac