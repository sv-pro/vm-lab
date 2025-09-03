#!/bin/bash

export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

VM_IMAGE="${SCRIPT_DIR}/output/ubuntu-24.04-cloud-base.qcow2"
SSH_KEY="${SCRIPT_DIR}/packer/cloud-init/id_rsa"
echo "VM image: $VM_IMAGE"
echo "SSH key: $SSH_KEY"

SSH_PORT="2222"

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
        
        # Set default name if not provided
        if [ -z "$VM_NAME" ]; then
            VM_NAME="ubuntu-24.04-$ROLE"
        fi
        
        case "$ROLE" in
            base)
                echo "Creating base Ubuntu 24.04 image: $VM_NAME"
                cd "${SCRIPT_DIR}/packer"
                packer build -var="image_name=$VM_NAME" -var-file="values-cloud-base.hcl" "ubuntu-cloud-base.pkr.hcl"
                cd "${SCRIPT_DIR}"
                ;;
            lxd|docker|k8s|kata|observer)
                if [ ! -f "${SCRIPT_DIR}/packer/values-cloud-$ROLE.hcl" ]; then
                    echo "Error: ${SCRIPT_DIR}/packer/values-cloud-$ROLE.hcl not found"
                    echo "Create the role configuration file first"
                    exit 1
                fi
                echo "Creating $ROLE VM image: $VM_NAME"
                cd "${SCRIPT_DIR}/packer"
                packer build -var="image_name=$VM_NAME" -var-file="values-cloud-$ROLE.hcl" "ubuntu-cloud-base.pkr.hcl"
                cd "${SCRIPT_DIR}"
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
        
        if pgrep -f "$TARGET_IMAGE" > /dev/null; then
            echo "VM is already running"
            exit 1
        fi
        
        # Find available SSH port
        AVAILABLE_PORT=$SSH_PORT
        while netstat -ln | grep ":$AVAILABLE_PORT " > /dev/null 2>&1; do
            AVAILABLE_PORT=$((AVAILABLE_PORT + 1))
        done
        
        echo "Starting VM: $(basename "$TARGET_IMAGE")"
        qemu-system-x86_64 \
            -m 2048 \
            -cpu host \
            -enable-kvm \
            -drive file="$TARGET_IMAGE",format=qcow2 \
            -netdev user,id=net0,hostfwd=tcp::$AVAILABLE_PORT-:22 \
            -device virtio-net,netdev=net0 \
            -daemonize
        echo "VM started. SSH with: ssh -i $SSH_KEY ubuntu@localhost -p $AVAILABLE_PORT"
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
            kill "$PID"
            echo "VM stopped: $(basename "$TARGET_IMAGE")"
        else
            echo "No running VM found for: $(basename "$TARGET_IMAGE")"
        fi
        ;;
    ssh)
        ssh -i "$SSH_KEY" ubuntu@localhost -p $SSH_PORT
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
        echo "Usage: $0 {create|list|start|stop|ssh|status} [options]"
        echo ""
        echo "Commands:"
        echo "  create <role> [--name <name>] - Create a new VM image"
        echo "  list                          - Show available images and running VMs"
        echo "  start [--name <name>]         - Start a VM (default or named)"
        echo "  stop [--name <name>]          - Stop a VM"
        echo "  ssh [--name <name>]           - SSH into a VM"
        echo "  status                        - Check VM status"
        echo ""
        echo "Roles: base, lxd, docker, k8s, kata, observer"
        echo ""
        echo "Examples:"
        echo "  $0 create base --name my-dev-vm"
        echo "  $0 create docker --name web-server"
        echo "  $0 start --name my-dev-vm"
        echo "  $0 ssh --name web-server"
        ;;
esac