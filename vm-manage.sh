#!/bin/bash

export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

VM_IMAGE="${SCRIPT_DIR}/output/ubuntu-24.04-cloud-base.qcow2"
SSH_KEY="${SCRIPT_DIR}/packer/cloud-init/id_rsa"
echo "VM image: $VM_IMAGE"
echo "SSH key: $SSH_KEY"

SSH_PORT="2222"

# Bridge networking configuration
VM_BRIDGE="vmlab-br0"
VM_NETWORK="192.168.100"
VM_IP_START=10

# Get next available VM IP
get_next_vm_ip() {
    local ip_suffix=$VM_IP_START
    local vm_ip
    
    while true; do
        vm_ip="${VM_NETWORK}.${ip_suffix}"
        if ! ping -c 1 -W 1 "$vm_ip" >/dev/null 2>&1; then
            echo "$vm_ip"
            return 0
        fi
        ip_suffix=$((ip_suffix + 1))
        
        # Safety limit
        if [ "$ip_suffix" -gt 254 ]; then
            echo "Error: No available IP addresses in ${VM_NETWORK}.0/24 range" >&2
            exit 1
        fi
    done
}

# Create TAP interface for VM
create_tap_interface() {
    local tap_name="$1"
    local vm_ip="$2"
    
    # Create TAP interface
    sudo ip tuntap add "$tap_name" mode tap
    sudo ip link set "$tap_name" up
    sudo brctl addif "$VM_BRIDGE" "$tap_name"
    
    echo "$tap_name"
}

# Remove TAP interface
remove_tap_interface() {
    local tap_name="$1"
    if ip link show "$tap_name" >/dev/null 2>&1; then
        sudo brctl delif "$VM_BRIDGE" "$tap_name" 2>/dev/null
        sudo ip link delete "$tap_name" 2>/dev/null
    fi
}

# Check if running in interactive mode
is_interactive() {
    [[ -t 0 && -t 1 ]]
}

# Check if VM image exists
vm_image_exists() {
    local name="$1"
    [[ -f "output/${name}.qcow2" ]]
}

# Get or create role-specific base image
get_or_create_image() {
    local role="$1"
    local role_image="ubuntu-24.04-${role}"
    
    if vm_image_exists "$role_image"; then
        echo "Using existing $role image: $role_image" >&2
        echo "$role_image"
        return 0
    fi
    
    echo "Role image $role_image not found. Building it first..." >&2
    if [ ! -f "${SCRIPT_DIR}/packer/values-cloud-$role.hcl" ]; then
        echo "Error: ${SCRIPT_DIR}/packer/values-cloud-$role.hcl not found" >&2
        exit 1
    fi
    
    # Clean up any incomplete build directories
    if [ -d "${SCRIPT_DIR}/output/$role_image" ]; then
        echo "Cleaning up incomplete build directory: output/$role_image" >&2
        rm -rf "${SCRIPT_DIR}/output/$role_image"
    fi
    
    cd "${SCRIPT_DIR}/packer"
    if packer build -var="image_name=$role_image" -var="hostname=$role_image" -var-file="values-cloud-$role.hcl" "ubuntu-cloud-base.pkr.hcl" >&2; then
        cd "${SCRIPT_DIR}"
        echo "Successfully built $role image: $role_image" >&2
        echo "$role_image"
        return 0
    else
        cd "${SCRIPT_DIR}"
        echo "Error: Failed to build $role image" >&2
        exit 1
    fi
}

# Generate unique name with auto-incrementing suffix
generate_unique_name() {
    local base_name="$1"
    local name="$base_name"
    local counter=2
    
    while vm_image_exists "$name"; do
        name="${base_name}-${counter}"
        counter=$((counter + 1))
    done
    
    echo "$name"
}

# Handle name conflicts
handle_name_conflict() {
    local vm_name="$1"
    local is_default_name="$2"
    
    if ! vm_image_exists "$vm_name"; then
        echo "$vm_name"
        return 0
    fi
    
    if [[ "$is_default_name" == "true" ]]; then
        # Auto-increment for default names
        local unique_name=$(generate_unique_name "$vm_name")
        echo "VM '$vm_name' already exists. Using '$unique_name' instead." >&2
        echo "$unique_name"
        return 0
    else
        # Custom name conflict handling
        if is_interactive; then
            echo "VM '$vm_name' already exists." >&2
            echo -n "Do you want to overwrite it? [y/N]: " >&2
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo "$vm_name"
                return 0
            else
                echo "Operation cancelled." >&2
                exit 1
            fi
        else
            echo "Error: VM '$vm_name' already exists. Cannot overwrite in non-interactive mode." >&2
            exit 1
        fi
    fi
}

# Clean up existing VM output directory
cleanup_existing_vm() {
    local vm_name="$1"
    if [[ -d "output/${vm_name}" ]]; then
        echo "Removing existing output directory: output/${vm_name}" >&2
        rm -rf "output/${vm_name}"
    fi
}

# Parse arguments for --name option
parse_args() {
    ROLE=""
    VM_NAME=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                VM_NAME="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option $1"
                exit 1
                ;;
            *)
                if [ -z "$ROLE" ]; then
                    ROLE="$1"
                fi
                shift
                ;;
        esac
    done
}

case "$1" in
    create)
        shift # Remove 'create' from arguments
        parse_args "$@"
        
        if [ -z "$ROLE" ]; then
            echo "Available roles: base, lxd, docker, k8s, kata, observer"
            echo "Usage: $0 create <role> [--name <custom-name>]"
            exit 1
        fi
        
        # Set default name if not provided and handle conflicts
        is_default_name="false"
        if [ -z "$VM_NAME" ]; then
            VM_NAME="ubuntu-24.04-$ROLE"
            is_default_name="true"
        fi
        
        # Handle name conflicts
        VM_NAME=$(handle_name_conflict "$VM_NAME" "$is_default_name")
        
        case "$ROLE" in
            base)
                echo "Creating base Ubuntu 24.04 image: $VM_NAME"
                cleanup_existing_vm "$VM_NAME"
                cd "${SCRIPT_DIR}/packer"
                packer build -var="image_name=$VM_NAME" -var="hostname=$VM_NAME" -var-file="values-cloud-base.hcl" "ubuntu-cloud-base.pkr.hcl"
                cd "${SCRIPT_DIR}"
                ;;
            lxd|docker|k8s|kata|observer)
                # Get or create role-specific image first
                ROLE_IMAGE=$(get_or_create_image "$ROLE")
                
                # Now clone the role image to create the VM
                echo "Creating $ROLE VM '$VM_NAME' from image '$ROLE_IMAGE'"
                cleanup_existing_vm "$VM_NAME"
                
                # Copy the role image to create the VM instance
                if [ -f "output/${ROLE_IMAGE}.qcow2" ]; then
                    cp "output/${ROLE_IMAGE}.qcow2" "output/${VM_NAME}.qcow2"
                    echo "VM '$VM_NAME' created successfully from $ROLE image"
                else
                    echo "Error: Role image output/${ROLE_IMAGE}.qcow2 not found after build"
                    exit 1
                fi
                ;;
            *)
                echo "Unknown role: $ROLE"
                echo "Available roles: base, lxd, docker, k8s, kata, observer"
                exit 1
                ;;
        esac
        ;;
    list)
        echo "VM Images:"
        if ls output/*.qcow2 >/dev/null 2>&1; then
            for vm_file in output/*.qcow2; do
                vm_name=$(basename "$vm_file" .qcow2)
                vm_size=$(du -h "$vm_file" | cut -f1)
                if pgrep -f "$vm_file" >/dev/null; then
                    echo "  ✓ $vm_name ($vm_size) - RUNNING"
                else
                    echo "  • $vm_name ($vm_size) - stopped"
                fi
            done
        else
            echo "  No VM images found"
        fi
        echo
        echo "Running VMs details:"
        ps aux | grep qemu-system-x86_64 | grep -v grep || echo "  No running VMs"
        ;;
    start)
        shift # Remove 'start' from arguments
        parse_args "$@"
        
        # If VM_NAME provided, use that image, otherwise use default
        if [ -n "$VM_NAME" ]; then
            TARGET_IMAGE="output/$VM_NAME.qcow2"
        else
            TARGET_IMAGE="$VM_IMAGE"
        fi
        
        if [ ! -f "$TARGET_IMAGE" ]; then
            echo "Error: VM image $TARGET_IMAGE not found"
            echo "Available images:"
            ls -1 output/*.qcow2 2>/dev/null || echo "No images available"
            exit 1
        fi
        
        # Validate qcow2 file
        if ! qemu-img info "$TARGET_IMAGE" >/dev/null 2>&1; then
            echo "Error: $TARGET_IMAGE is not a valid image file"
            echo "File info:"
            ls -lh "$TARGET_IMAGE"
            exit 1
        fi
        
        # Check if it's actually qcow2 format and non-empty
        IMG_FORMAT=$(qemu-img info "$TARGET_IMAGE" | grep "file format:" | cut -d: -f2 | xargs)
        IMG_SIZE=$(qemu-img info "$TARGET_IMAGE" | grep "virtual size:" | cut -d'(' -f2 | cut -d' ' -f1)
        
        if [ "$IMG_FORMAT" != "qcow2" ]; then
            echo "Error: $TARGET_IMAGE is not in qcow2 format (found: $IMG_FORMAT)"
            echo "File info:"
            ls -lh "$TARGET_IMAGE"
            exit 1
        fi
        
        if [ "$IMG_SIZE" = "0" ]; then
            echo "Error: $TARGET_IMAGE appears to be empty (0 bytes)"
            echo "File info:"
            ls -lh "$TARGET_IMAGE"
            exit 1
        fi
        
        if pgrep -f "$TARGET_IMAGE" > /dev/null; then
            echo "VM is already running"
            exit 1
        fi
        
        # Get VM name and IP for bridge networking
        VM_NAME=$(basename "$TARGET_IMAGE" .qcow2)
        VM_IP=$(get_next_vm_ip)
        # Generate short TAP name (max 15 chars)
        VM_HASH=$(echo "$VM_NAME" | md5sum | cut -c1-6)
        TAP_NAME="tap${VM_HASH}"
        
        echo "Starting VM: $VM_NAME"
        echo "Assigned IP: $VM_IP"
        
        # Create TAP interface
        create_tap_interface "$TAP_NAME" "$VM_IP"
        
        # Start VM with bridge networking
        if qemu-system-x86_64 \
            -m 2048 \
            -cpu host \
            -enable-kvm \
            -drive file="$TARGET_IMAGE",format=qcow2 \
            -netdev tap,id=net0,ifname="$TAP_NAME",script=no,downscript=no \
            -device virtio-net,netdev=net0,mac=52:54:00:$(printf '%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))) \
            -daemonize; then
            
            # Wait a moment and verify the VM actually started
            sleep 2
            if pgrep -f "$TARGET_IMAGE" > /dev/null; then
                echo "VM started successfully. SSH with: ssh -i $SSH_KEY ubuntu@$VM_IP"
                echo "VM IP: $VM_IP"
            else
                echo "Error: VM failed to start - process not found"
                remove_tap_interface "$TAP_NAME"
                exit 1
            fi
        else
            echo "Error: Failed to start VM - QEMU command failed"
            remove_tap_interface "$TAP_NAME"
            exit 1
        fi
        ;;
    stop)
        shift # Remove 'stop' from arguments
        parse_args "$@"
        
        # If VM_NAME provided, use that image, otherwise use default
        if [ -n "$VM_NAME" ]; then
            TARGET_IMAGE="output/$VM_NAME.qcow2"
        else
            TARGET_IMAGE="$VM_IMAGE"
        fi
        
        PID=$(pgrep -f "$TARGET_IMAGE")
        if [ -n "$PID" ]; then
            VM_NAME=$(basename "$TARGET_IMAGE" .qcow2)
            VM_HASH=$(echo "$VM_NAME" | md5sum | cut -c1-6)
            TAP_NAME="tap${VM_HASH}"
            
            kill "$PID"
            echo "VM stopped: $VM_NAME"
            
            # Clean up TAP interface
            remove_tap_interface "$TAP_NAME"
        else
            echo "Error: VM '$(basename "$TARGET_IMAGE" .qcow2)' is not running or does not exist"
            echo "Available VMs:"
            if ls output/*.qcow2 >/dev/null 2>&1; then
                for vm_file in output/*.qcow2; do
                    vm_name=$(basename "$vm_file" .qcow2)
                    if pgrep -f "$vm_file" >/dev/null; then
                        echo "  ✓ $vm_name - RUNNING"
                    else
                        echo "  • $vm_name - stopped"
                    fi
                done
            else
                echo "  No VMs found"
            fi
        fi
        ;;
    ssh)
        shift # Remove 'ssh' from arguments
        parse_args "$@"
        
        # If VM_NAME provided, use that image, otherwise use default
        if [ -n "$VM_NAME" ]; then
            TARGET_IMAGE="output/$VM_NAME.qcow2"
        else
            TARGET_IMAGE="$VM_IMAGE"
        fi
        
        # Check if VM is running
        if ! pgrep -f "$TARGET_IMAGE" > /dev/null; then
            echo "Error: VM $(basename "$TARGET_IMAGE" .qcow2) is not running"
            echo "Start it first with: $0 start$([ -n "$VM_NAME" ] && echo " --name $VM_NAME")"
            exit 1
        fi
        
        # Find the VM IP from bridge network
        VM_NAME=$(basename "$TARGET_IMAGE" .qcow2)
        VM_HASH=$(echo "$VM_NAME" | md5sum | cut -c1-6)
        TAP_NAME="tap${VM_HASH}"
        
        # Get VM IP by checking ARP table for the TAP interface
        VM_IP=""
        if ip link show "$TAP_NAME" >/dev/null 2>&1; then
            # Try to find the IP from the VM network range
            for ip_suffix in $(seq $VM_IP_START 254); do
                test_ip="${VM_NETWORK}.${ip_suffix}"
                if ping -c 1 -W 1 "$test_ip" >/dev/null 2>&1; then
                    VM_IP="$test_ip"
                    break
                fi
            done
        fi
        
        if [ -z "$VM_IP" ]; then
            echo "Error: Could not determine VM IP address"
            echo "VM may not be fully booted yet. Try again in a few seconds."
            exit 1
        fi
        
        echo "Connecting to $VM_NAME at $VM_IP..."
        ssh -i "$SSH_KEY" ubuntu@"$VM_IP"
        ;;
    delete)
        shift # Remove 'delete' from arguments
        parse_args "$@"
        
        # If VM_NAME provided, use that image, otherwise use default
        if [ -n "$VM_NAME" ]; then
            TARGET_IMAGE="output/$VM_NAME.qcow2"
            TARGET_DIR="output/$VM_NAME"
        else
            echo "Error: VM name is required for delete operation"
            echo "Usage: $0 delete --name <vm-name>"
            exit 1
        fi
        
        # Check if VM exists
        if [ ! -f "$TARGET_IMAGE" ] && [ ! -d "$TARGET_DIR" ]; then
            echo "Error: VM $(basename "$TARGET_IMAGE" .qcow2) does not exist"
            exit 1
        fi
        
        # Check if VM is running
        if pgrep -f "$TARGET_IMAGE" > /dev/null; then
            echo "Error: VM $(basename "$TARGET_IMAGE" .qcow2) is currently running"
            echo "Stop it first with: $0 stop --name $VM_NAME"
            exit 1
        fi
        
        # Confirmation prompt
        if is_interactive; then
            echo "This will permanently delete VM '$(basename "$TARGET_IMAGE" .qcow2)' and all its data."
            echo -n "Are you sure? [y/N]: "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                echo "Operation cancelled."
                exit 0
            fi
        else
            echo "Error: Delete operation requires interactive confirmation. Cannot delete in non-interactive mode."
            exit 1
        fi
        
        # Delete VM files
        echo "Deleting VM: $(basename "$TARGET_IMAGE" .qcow2)"
        
        if [ -f "$TARGET_IMAGE" ]; then
            rm -f "$TARGET_IMAGE"
            echo "Deleted image file: $TARGET_IMAGE"
        fi
        
        if [ -d "$TARGET_DIR" ]; then
            rm -rf "$TARGET_DIR"
            echo "Deleted directory: $TARGET_DIR"
        fi
        
        echo "VM $(basename "$TARGET_IMAGE" .qcow2) has been deleted successfully"
        ;;
    status)
        if pgrep -f "$VM_IMAGE" > /dev/null; then
            echo "VM is running"
            ps aux | grep qemu-system-x86_64 | grep -v grep
        else
            echo "VM is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {create|list|start|stop|ssh|delete|status} [options]"
        echo ""
        echo "Commands:"
        echo "  create <role> [--name <name>] - Create a new VM image"
        echo "  list                          - Show available images and running VMs"
        echo "  start [--name <name>]         - Start a VM (default or named)"
        echo "  stop [--name <name>]          - Stop a VM"
        echo "  ssh [--name <name>]           - SSH into a running VM (auto-detects port)"
        echo "  delete --name <name>          - Delete a VM (requires confirmation)"
        echo "  status                        - Check VM status"
        echo ""
        echo "Roles: base, lxd, docker, k8s, kata, observer"
        echo ""
        echo "Examples:"
        echo "  $0 create base --name my-dev-vm"
        echo "  $0 create docker --name web-server"
        echo "  $0 start --name my-dev-vm"
        echo "  $0 ssh --name web-server"
        echo "  $0 delete --name old-vm"
        ;;
esac