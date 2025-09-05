#!/bin/bash

# VM Lab bpftrace DNS Monitoring Demo
# Demonstrates eBPF-powered network monitoring in hybrid infrastructure

set -e

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$DEMO_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_demo() {
    echo -e "${PURPLE}[DEMO]${NC} $1"
}

show_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    VM Lab eBPF Demo                         ║${NC}" 
    echo -e "${CYAN}║              DNS Monitoring with bpftrace                   ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  Demonstrates: Hybrid VM+Container network monitoring       ║${NC}"
    echo -e "${CYAN}║  Technology:   eBPF + bpftrace + systemd-resolved          ║${NC}"
    echo -e "${CYAN}║  Target:       hybrid-dns container (10.0.1.2:53)          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/Makefile" ]]; then
        log_error "Must run from VM Lab directory"
        exit 1
    fi
    
    # Check if bpftrace is installed
    if ! command -v bpftrace &> /dev/null; then
        log_error "bpftrace not installed. Install with: sudo apt install bpftrace"
        log_info "Or run: make create-observer to get a VM with bpftrace pre-installed"
        exit 1
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This demo requires root privileges for eBPF"
        log_info "Run with: sudo $0"
        exit 1
    fi
    
    # Check if hybrid network is running
    if ! docker network ls | grep -q hybrid-net; then
        log_warning "Hybrid network not found. Creating..."
        cd "$PROJECT_ROOT"
        make create-hybrid-network
        make hybrid-enable-dns
    fi
    
    log_success "Prerequisites check passed"
}

show_network_status() {
    log_info "Current hybrid network status:"
    cd "$PROJECT_ROOT"
    make hybrid-status | head -20
    echo ""
}

run_simple_demo() {
    log_demo "Starting simple DNS monitoring..."
    log_info "This will monitor all DNS queries in real-time"
    log_info "Try running: ping test-container.hybrid.local (in another terminal)"
    echo ""
    
    echo -e "${CYAN}bpftrace one-liner:${NC}"
    echo "kprobe:udp_sendmsg /((struct sock *)arg0)->__sk_common.skc_dport == 0x3500/ { printf(\"🔍 DNS Query: PID %d (%s) → %s\\n\", pid, comm, ntop(((struct sock *)arg0)->__sk_common.skc_daddr)); }"
    echo ""
    
    log_info "Starting monitor... Press Ctrl+C to stop"
    sleep 2
    
    timeout 30 bpftrace "$DEMO_DIR/dns-oneliner.bt" || true
    
    echo ""
    log_success "Simple demo completed"
}

run_detailed_demo() {
    log_demo "Starting detailed DNS monitoring..."
    log_info "This provides comprehensive DNS traffic analysis"
    echo ""
    
    timeout 30 bpftrace "$DEMO_DIR/bpftrace-dns-monitor.bt" || true
    
    echo ""
    log_success "Detailed demo completed"
}

generate_test_traffic() {
    log_info "Generating test DNS traffic..."
    
    # Background traffic generation
    (
        sleep 2
        for i in {1..5}; do
            log_info "Test query $i/5: test-container.hybrid.local"
            nslookup test-container.hybrid.local 10.0.1.2 >/dev/null 2>&1 || true
            sleep 2
        done
        
        for i in {1..3}; do
            log_info "Test query: gateway.hybrid.local"  
            nslookup gateway.hybrid.local 10.0.1.2 >/dev/null 2>&1 || true
            sleep 1
        done
    ) &
    
    TEST_PID=$!
    echo "Traffic generator PID: $TEST_PID"
}

cleanup() {
    if [[ -n "${TEST_PID:-}" ]]; then
        kill $TEST_PID 2>/dev/null || true
    fi
}

trap cleanup EXIT

show_demo_menu() {
    echo ""
    echo -e "${CYAN}Select Demo Type:${NC}"
    echo "1) Container logs monitoring (simplest, no eBPF needed)"
    echo "2) eBPF process monitoring (intermediate)"
    echo "3) eBPF network packets (advanced)"
    echo "4) All demos with traffic generation"
    echo "5) Show all monitoring scripts"
    echo "6) Exit"
    echo ""
    read -p "Choose option [1-6]: " choice
    
    case $choice in
        1)
            log_demo "Container logs monitoring (simplest approach)"
            log_info "This shows actual DNS queries processed by the hybrid-dns container"
            echo ""
            exec "$DEMO_DIR/dns-container-monitor.sh"
            ;;
        2)
            log_demo "eBPF process monitoring"
            log_info "This uses bpftrace to monitor DNS-related system calls"
            timeout 30 bpftrace "$DEMO_DIR/dns-ultra-simple.bt" || true
            ;;
        3)
            log_demo "eBPF network packets monitoring" 
            log_info "This monitors network packets that could be DNS traffic"
            timeout 30 bpftrace "$DEMO_DIR/dns-simple.bt" || true
            ;;
        4)
            log_demo "Running all demos with traffic generation..."
            generate_test_traffic
            timeout 15 "$DEMO_DIR/dns-container-monitor.sh" &
            sleep 2
            timeout 15 bpftrace "$DEMO_DIR/dns-ultra-simple.bt" || true
            ;;
        5)
            echo ""
            echo -e "${CYAN}=== Container Monitor (dns-container-monitor.sh) ===${NC}"
            head -15 "$DEMO_DIR/dns-container-monitor.sh"
            echo ""
            echo -e "${CYAN}=== eBPF Process Monitor (dns-ultra-simple.bt) ===${NC}"
            cat "$DEMO_DIR/dns-ultra-simple.bt"
            echo ""
            echo -e "${CYAN}=== eBPF Network Monitor (dns-simple.bt) ===${NC}" 
            head -10 "$DEMO_DIR/dns-simple.bt"
            ;;
        6)
            log_info "Demo ended"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            show_demo_menu
            ;;
    esac
}

main() {
    show_header
    check_prerequisites
    show_network_status
    
    log_info "This demo monitors DNS queries to the hybrid-dns container"
    log_info "Perfect for observing VM ↔ Container service discovery traffic"
    
    show_demo_menu
    
    echo ""
    log_success "🎉 VM Lab eBPF Demo completed!"
    log_info "Learn more about eBPF networking at: docs/hybrid-networking/"
}

# Handle script arguments
case "${1:-}" in
    --simple)
        show_header
        check_prerequisites
        run_simple_demo
        ;;
    --detailed)
        show_header
        check_prerequisites  
        run_detailed_demo
        ;;
    --help)
        echo "VM Lab bpftrace DNS Monitoring Demo"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  --simple    Run simple one-liner demo"
        echo "  --detailed  Run detailed monitoring demo"
        echo "  --help      Show this help"
        echo ""
        echo "Interactive mode (default): $0"
        ;;
    *)
        main
        ;;
esac