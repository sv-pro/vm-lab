#!/bin/bash

# VM Vagrant Wrapper Script - Option C Implementation
# Handles both predefined VMs (base, docker, k8s, etc.) and custom named VMs
# Uses isolated directories for custom VMs while keeping predefined VMs in main Vagrantfile

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VMS_DIR="${SCRIPT_DIR}/vms"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
MAIN_VAGRANTFILE="${SCRIPT_DIR}/Vagrantfile"

# Predefined VM roles
PREDEFINED_ROLES=("base" "docker" "observer" "k8s" "lxd" "kata" "router" "pfsense" "hybrid-base" "hybrid-docker")

# Check if a name is a predefined role
is_predefined_role() {
    local name="$1"
    for role in "${PREDEFINED_ROLES[@]}"; do
        if [[ "$name" == "$role" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if a name matches ubuntu-24-04-{role} pattern
is_default_role_name() {
    local name="$1"
    for role in "${PREDEFINED_ROLES[@]}"; do
        if [[ "$name" == "ubuntu-24-04-$role" ]]; then
            return 0
        fi
    done
    return 1
}

# Get role from name (either direct role or ubuntu-24-04-{role})
get_role_from_name() {
    local name="$1"
    
    # Direct role match
    for role in "${PREDEFINED_ROLES[@]}"; do
        if [[ "$name" == "$role" ]]; then
            echo "$role"
            return 0
        fi
    done
    
    # ubuntu-24-04-{role} pattern
    for role in "${PREDEFINED_ROLES[@]}"; do
        if [[ "$name" == "ubuntu-24-04-$role" ]]; then
            echo "$role"
            return 0
        fi
    done
    
    return 1
}

# Generate unique IP address for hybrid networking
generate_hybrid_ip() {
    local vm_name="$1"
    local base_ip="10.0.1"
    local ip_file="${VMS_DIR}/.hybrid-ips"
    
    # Create IP tracking file if it doesn't exist
    mkdir -p "$VMS_DIR"
    touch "$ip_file"
    
    # Check if this VM already has an IP assigned
    if [[ -f "$ip_file" ]]; then
        local existing_ip=$(grep "^$vm_name=" "$ip_file" | cut -d= -f2)
        if [[ -n "$existing_ip" ]]; then
            echo "$existing_ip"
            return 0
        fi
    fi
    
    # Find next available IP (starting from 10.0.1.10, avoiding gateway at .1 and Docker range .100-199)
    local used_ips=$(cat "$ip_file" 2>/dev/null | cut -d= -f2 | cut -d. -f4 | sort -n)
    local next_ip=10
    
    for used in $used_ips; do
        if [[ $used -ge 10 && $used -lt 100 && $used -eq $next_ip ]]; then
            ((next_ip++))
        fi
    done
    
    # Skip Docker container range (100-199) and go to VM range (200+)
    if [[ $next_ip -ge 100 ]]; then
        next_ip=200
        for used in $used_ips; do
            if [[ $used -ge 200 && $used -eq $next_ip ]]; then
                ((next_ip++))
            fi
        done
    fi
    
    local assigned_ip="${base_ip}.${next_ip}"
    
    # Record the assignment
    echo "${vm_name}=${assigned_ip}" >> "$ip_file"
    
    echo "$assigned_ip"
}

# Create isolated VM directory with Vagrantfile
create_custom_vm() {
    local vm_name="$1"
    local role="$2"
    local vm_dir="${VMS_DIR}/${vm_name}"
    
    echo "Creating custom VM '$vm_name' with role '$role'"
    
    # Create VM directory
    mkdir -p "$vm_dir"
    
    # Check if template exists
    local template_file="${TEMPLATES_DIR}/Vagrantfile.${role}"
    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template for role '$role' not found: $template_file"
        exit 1
    fi
    
    # Copy and customize Vagrantfile
    if [[ "$role" == "hybrid-base" || "$role" == "hybrid-docker" ]]; then
        # Generate unique IP for hybrid networking (10.0.1.x)
        local hybrid_ip=$(generate_hybrid_ip "$vm_name")
        sed -e "s/VM_NAME_PLACEHOLDER/$vm_name/g" \
            -e "s/HYBRID_IP_PLACEHOLDER/$hybrid_ip/g" \
            "$template_file" > "${vm_dir}/Vagrantfile"
        echo "Assigned hybrid network IP: $hybrid_ip"
    else
        sed "s/VM_NAME_PLACEHOLDER/$vm_name/g" "$template_file" > "${vm_dir}/Vagrantfile"
    fi
    
    echo "Custom VM '$vm_name' workspace created at: $vm_dir"
}

# Execute vagrant command in appropriate context
run_vagrant_command() {
    local vm_name="$1"
    shift
    local vagrant_args=("$@")
    
    if is_predefined_role "$vm_name" || is_default_role_name "$vm_name"; then
        # Use main Vagrantfile for predefined roles
        local role
        role=$(get_role_from_name "$vm_name")
        echo "Running vagrant command for predefined VM: $role"
        cd "$SCRIPT_DIR"
        vagrant "${vagrant_args[@]}" "$role"
    else
        # Use isolated directory for custom VMs
        local vm_dir="${VMS_DIR}/${vm_name}"
        if [[ ! -d "$vm_dir" ]]; then
            echo "Error: Custom VM '$vm_name' workspace not found: $vm_dir"
            echo "Create it first with: $0 create <role> <custom-name>"
            exit 1
        fi
        
        echo "Running vagrant command for custom VM '$vm_name' in: $vm_dir"
        cd "$vm_dir"
        vagrant "${vagrant_args[@]}"
    fi
}

# List all VMs (both predefined and custom)
list_all_vms() {
    echo "=== Predefined VMs (Main Vagrantfile) ==="
    cd "$SCRIPT_DIR"
    vagrant status
    
    echo ""
    echo "=== Custom VMs (Isolated Directories) ==="
    if [[ -d "$VMS_DIR" ]] && [[ -n "$(ls -A "$VMS_DIR" 2>/dev/null)" ]]; then
        for vm_dir in "$VMS_DIR"/*; do
            if [[ -d "$vm_dir" ]]; then
                local vm_name=$(basename "$vm_dir")
                echo "Custom VM: $vm_name"
                cd "$vm_dir"
                vagrant status 2>/dev/null || echo "  Status: Unknown (no Vagrant state)"
            fi
        done
    else
        echo "No custom VMs found"
    fi
}

# Main command dispatcher
case "$1" in
    "create")
        if [[ $# -lt 3 ]]; then
            echo "Usage: $0 create <role> <vm-name>"
            echo "Roles: ${PREDEFINED_ROLES[*]}"
            exit 1
        fi
        
        role="$2"
        vm_name="$3"
        
        # Validate role
        if ! printf '%s\n' "${PREDEFINED_ROLES[@]}" | grep -qx "$role"; then
            echo "Error: Invalid role '$role'"
            echo "Available roles: ${PREDEFINED_ROLES[*]}"
            exit 1
        fi
        
        if is_predefined_role "$vm_name" || is_default_role_name "$vm_name"; then
            echo "Error: VM name '$vm_name' conflicts with predefined role names"
            echo "Use a different custom name"
            exit 1
        fi
        
        create_custom_vm "$vm_name" "$role"
        run_vagrant_command "$vm_name" up
        ;;
    
    "up"|"start")
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 $1 <vm-name>"
            exit 1
        fi
        run_vagrant_command "$2" up
        ;;
    
    "halt"|"stop")
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 $1 <vm-name>"
            exit 1
        fi
        run_vagrant_command "$2" halt
        ;;
    
    "ssh")
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 ssh <vm-name>"
            exit 1
        fi
        run_vagrant_command "$2" ssh
        ;;
    
    "destroy"|"delete")
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 $1 <vm-name>"
            exit 1
        fi
        vm_name="$2"
        run_vagrant_command "$vm_name" destroy -f
        
        # Clean up custom VM directory
        if ! is_predefined_role "$vm_name" && ! is_default_role_name "$vm_name"; then
            vm_dir="${VMS_DIR}/${vm_name}"
            if [[ -d "$vm_dir" ]]; then
                echo "Cleaning up custom VM directory: $vm_dir"
                rm -rf "$vm_dir"
            fi
        fi
        ;;
    
    "status"|"list")
        list_all_vms
        ;;
    
    *)
        echo "Usage: $0 {create|up|halt|ssh|destroy|status} [options]"
        echo ""
        echo "Commands:"
        echo "  create <role> <vm-name>  - Create custom VM with specific role"
        echo "  up <vm-name>            - Start VM (predefined or custom)"
        echo "  halt <vm-name>          - Stop VM"
        echo "  ssh <vm-name>           - SSH into VM"
        echo "  destroy <vm-name>       - Destroy VM"
        echo "  status                  - List all VMs"
        echo ""
        echo "Predefined roles: ${PREDEFINED_ROLES[*]}"
        echo "Predefined VMs: base, docker, observer (production-ready)"
        echo "                 k8s, lxd, kata, router, pfsense (experimental)"
        echo ""
        echo "Examples:"
        echo "  $0 create docker web-server    # Create custom Docker VM"
        echo "  $0 up docker                   # Start predefined docker VM"
        echo "  $0 up web-server               # Start custom web-server VM"
        echo "  $0 ssh base                    # SSH to predefined base VM"
        exit 1
        ;;
esac