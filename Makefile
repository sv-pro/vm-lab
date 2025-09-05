# VM Lab Makefile
# Wrapper for Vagrant operations with support for both predefined and custom VM names

# Default variables
DEFAULT_NAME ?= 
ROLE ?= base
VM_VAGRANT_SCRIPT := ./vm-vagrant.sh

# Helper to run vm-vagrant.sh wrapper
define vm_vagrant
	@$(VM_VAGRANT_SCRIPT) $(1)
endef

# Default target
.PHONY: help
help: ## Show this help message
	@echo "VM Lab Management Commands:"
	@echo ""
	@echo "VM Creation:"
	@echo "  make create-base [NAME=<name>]     - Create base Ubuntu VM"
	@echo "  make create-docker [NAME=<name>]   - Create Docker host VM"
	@echo "  make create-observer [NAME=<name>] - Create Observer host VM"
	@echo ""
	@echo "Hybrid Networking (VM + Docker containers on shared network):"
	@echo "  make create-hybrid-network         - Create hybrid bridge network"
	@echo "  make hybrid-base [NAME=<name>]     - Create base VM with hybrid networking"
	@echo "  make hybrid-docker [NAME=<name>]   - Create Docker VM with hybrid networking"
	@echo "  make hybrid-status                 - Show hybrid network status"
	@echo ""
	@echo "DNS Service Discovery:"
	@echo "  make hybrid-enable-dns             - Enable hostname resolution (containers ↔ VMs)"
	@echo "  make hybrid-update-dns             - Update DNS records for all components"
	@echo ""
	@echo "Network Monitoring & Debugging:"
	@echo "  make hybrid-monitor                - Real-time traffic monitoring"
	@echo "  make hybrid-debug                  - Comprehensive network diagnostics"
	@echo "  make hybrid-logs                   - DNS container logs"
	@echo ""
	@echo "eBPF Demos & Monitoring:"
	@echo "  make demo-dns-monitor              - Interactive bpftrace DNS monitoring demo"
	@echo ""
	@echo "VM Management:"
	@echo "  make list                          - List all VM images and running VMs"
	@echo "  make start [NAME=<name>]           - Start a VM"
	@echo "  make stop [NAME=<name>]            - Stop a VM"
	@echo "  make ssh [NAME=<name>]             - SSH into a running VM"
	@echo "  make delete NAME=<name>            - Delete a VM (requires confirmation)"
	@echo "  make status                        - Check VM status"
	@echo ""
	@echo "Examples:"
	@echo "  make create-base NAME=my-dev-vm"
	@echo "  make create-docker NAME=web-server"
	@echo "  make start NAME=my-dev-vm"
	@echo "  make ssh NAME=web-server"
	@echo "  make delete NAME=old-vm"
	@echo ""
	@echo "Authentication:"
	@echo "  SSH: Standard Vagrant keys (~/.vagrant.d/insecure_private_key)"
	@echo "  Users: vagrant (Vagrant default), ubuntu (password: ubuntu), dev (password: dev123)"

# VM Creation targets (production-ready - shown in help)
.PHONY: create-base create-docker create-observer
.PHONY: base docker observer

# Experimental VM Creation targets (hidden from help - use with caution)
.PHONY: create-k8s create-lxd create-kata create-router create-pfsense
.PHONY: k8s lxd kata router pfsense
create-base: ## Create base Ubuntu VM
ifdef NAME
	$(call vm_vagrant,create base $(NAME))
else
	$(call vm_vagrant,up base)
endif

create-docker: ## Create Docker host VM
ifdef NAME
	$(call vm_vagrant,create docker $(NAME))
else
	$(call vm_vagrant,up docker)
endif

create-observer: ## Create Observer host VM
ifdef NAME
	$(call vm_vagrant,create observer $(NAME))
else
	$(call vm_vagrant,up observer)
endif

# Experimental VM Creation targets (hidden - no ## comments)
create-k8s:
ifdef NAME
	$(call vm_vagrant,create k8s $(NAME))
else
	$(call vm_vagrant,up k8s)
endif

create-lxd:
ifdef NAME
	$(call vm_vagrant,create lxd $(NAME))
else
	$(call vm_vagrant,up lxd)
endif

create-kata:
ifdef NAME
	$(call vm_vagrant,create kata $(NAME))
else
	$(call vm_vagrant,up kata)
endif

create-router:
ifdef NAME
	$(call vm_vagrant,create router $(NAME))
else
	$(call vm_vagrant,up router)
endif

create-pfsense:
ifdef NAME
	$(call vm_vagrant,create pfsense $(NAME))
else
	$(call vm_vagrant,up pfsense)
endif

# Hybrid Networking targets
.PHONY: create-hybrid-network hybrid-base hybrid-docker hybrid-status
.PHONY: destroy-hybrid-network hybrid-test-connectivity
.PHONY: hybrid-enable-dns hybrid-disable-dns hybrid-update-dns
.PHONY: hybrid-monitor hybrid-debug hybrid-logs

create-hybrid-network: ## Create hybrid bridge network for VM+Docker communication
	@echo "Creating hybrid bridge network (10.0.1.0/24)..."
	@./scripts/hybrid-network.sh create
	@echo "Hybrid network created successfully!"
	@echo "Network: 10.0.1.0/24, Gateway: 10.0.1.1, Bridge: hybr0"

destroy-hybrid-network: ## Destroy hybrid bridge network
	@echo "Destroying hybrid bridge network..."
	@./scripts/hybrid-network.sh destroy
	@echo "Hybrid network destroyed"

hybrid-base: ## Create base VM with hybrid networking
ifdef NAME
	@echo "Creating base VM '$(NAME)' with hybrid networking..."
	@./scripts/hybrid-network.sh ensure-network
	$(call vm_vagrant,create hybrid-base $(NAME))
else
	@echo "Creating predefined base VM with hybrid networking..."
	@./scripts/hybrid-network.sh ensure-network
	$(call vm_vagrant,up hybrid-base)
endif

hybrid-docker: ## Create Docker VM with hybrid networking  
ifdef NAME
	@echo "Creating Docker VM '$(NAME)' with hybrid networking..."
	@./scripts/hybrid-network.sh ensure-network
	$(call vm_vagrant,create hybrid-docker $(NAME))
else
	@echo "Creating predefined Docker VM with hybrid networking..."
	@./scripts/hybrid-network.sh ensure-network
	$(call vm_vagrant,up hybrid-docker)
endif

hybrid-status: ## Show hybrid network status
	@./scripts/hybrid-network.sh status

hybrid-test-connectivity: ## Test connectivity between VMs and containers on hybrid network
	@./scripts/hybrid-network.sh test-connectivity

hybrid-enable-dns: ## Enable DNS service discovery (hostname resolution)
	@echo "Enabling DNS service discovery for hybrid network..."
	@./scripts/hybrid-network.sh enable-dns
	@echo "DNS enabled! VMs and containers can now resolve each other by hostname."
	@echo "Example: ping container-name.hybrid.local"

hybrid-disable-dns: ## Disable DNS service discovery
	@echo "Disabling DNS service discovery..."
	@./scripts/hybrid-network.sh disable-dns
	@echo "DNS disabled"

hybrid-update-dns: ## Update DNS records for all VMs and containers
	@echo "Updating DNS records..."
	@./scripts/hybrid-network.sh update-dns

hybrid-monitor: ## Monitor hybrid network traffic in real-time
	@echo "Starting hybrid network monitoring..."
	@./scripts/hybrid-network.sh monitor

hybrid-debug: ## Run comprehensive network diagnostics
	@echo "Running hybrid network diagnostics..."
	@./scripts/hybrid-network.sh debug

hybrid-logs: ## Show DNS container logs
	@echo "Showing DNS container logs..."
	@./scripts/hybrid-network.sh logs

# eBPF Demo targets
.PHONY: demo-dns-monitor
demo-dns-monitor: ## Interactive bpftrace DNS monitoring demo
	@echo "Starting DNS monitoring demo..."
	@./demos/run-dns-demo.sh

# VM Management targets  
.PHONY: list start stop ssh delete status
list: ## List all VM images and running VMs
	$(call vm_vagrant,status)

start: ## Start a VM
ifndef NAME
	@echo "Error: NAME parameter is required for start operation"
	@echo "Usage: make start NAME=<vm-name>"
	@echo "Available VMs: base, docker, k8s, lxd, kata, observer, or custom names"
	@exit 1
endif
	$(call vm_vagrant,up $(NAME))

stop: ## Stop a VM
ifndef NAME
	@echo "Error: NAME parameter is required for stop operation"
	@echo "Usage: make stop NAME=<vm-name>"
	@echo "Available VMs: base, docker, k8s, lxd, kata, observer, or custom names"
	@exit 1
endif
	$(call vm_vagrant,halt $(NAME))

ssh: ## SSH into a running VM
ifndef NAME
	@echo "Error: NAME parameter is required for ssh operation"
	@echo "Usage: make ssh NAME=<vm-name>"
	@echo "Available VMs: base, docker, k8s, lxd, kata, observer, or custom names"
	@exit 1
endif
	$(call vm_vagrant,ssh $(NAME))

delete: ## Delete a VM
ifndef NAME
	@echo "Error: NAME parameter is required for delete operation"
	@echo "Usage: make delete NAME=<vm-name>"
	@exit 1
endif
	$(call vm_vagrant,destroy $(NAME))

status: ## Check VM status
	$(call vm_vagrant,status)

# Convenience targets
.PHONY: clean
clean: ## Stop all VMs and clean up
	@echo "Stopping all predefined VMs..."
	@cd $(shell pwd) && vagrant halt
	@echo "Stopping custom VMs..."
	@if [ -d "vms" ]; then \
		for vm_dir in vms/*; do \
			if [ -d "$$vm_dir" ]; then \
				echo "Stopping $$(basename $$vm_dir)..."; \
				cd "$$vm_dir" && vagrant halt || true; \
				cd $(shell pwd); \
			fi; \
		done; \
	fi
	@echo "All VMs stopped"

# Development shortcuts
.PHONY: dev-vm web-vm
dev-vm: ## Create and start a development VM
	$(call vm_vagrant,up base)
	@echo "Development VM ready. Connect with: make ssh NAME=base"

web-vm: ## Create and start a web server VM
	$(call vm_vagrant,up docker)
	@echo "Web server VM ready. Connect with: make ssh NAME=docker"

# Clean aliases (without create- prefix) - production-ready
base: create-base        ## Alias for create-base
docker: create-docker    ## Alias for create-docker
observer: create-observer ## Alias for create-observer

# Clean aliases for experimental roles (hidden)
k8s: create-k8s
lxd: create-lxd  
kata: create-kata
router: create-router
pfsense: create-pfsense