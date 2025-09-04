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
	@echo "  make create-lxd [NAME=<name>]      - Create LXD host VM"
	@echo "  make create-docker [NAME=<name>]   - Create Docker host VM"
	@echo "  make create-k8s [NAME=<name>]      - Create Kubernetes host VM"
	@echo "  make create-kata [NAME=<name>]     - Create Kata host VM"
	@echo "  make create-observer [NAME=<name>] - Create Observer host VM"
	@echo "  make create-router [NAME=<name>]   - Create Virtual Router VM"
	@echo "  make create-pfsense [NAME=<name>]  - Create pfSense Firewall VM"
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
	@echo "  SSH Key: packer/cloud-init/id_rsa"
	@echo "  Users: ubuntu (password: ubuntu), dev (password: dev123)"

# VM Creation targets
.PHONY: create-base create-lxd create-docker create-k8s create-kata create-observer create-router create-pfsense
.PHONY: base lxd docker k8s kata observer router pfsense
create-base: ## Create base Ubuntu VM
ifdef NAME
	$(call vm_vagrant,create base $(NAME))
else
	$(call vm_vagrant,up base)
endif

create-lxd: ## Create LXD host VM
ifdef NAME
	$(call vm_vagrant,create lxd $(NAME))
else
	$(call vm_vagrant,up lxd)
endif

create-docker: ## Create Docker host VM
ifdef NAME
	$(call vm_vagrant,create docker $(NAME))
else
	$(call vm_vagrant,up docker)
endif

create-k8s: ## Create Kubernetes host VM
ifdef NAME
	$(call vm_vagrant,create k8s $(NAME))
else
	$(call vm_vagrant,up k8s)
endif

create-kata: ## Create Kata host VM
ifdef NAME
	$(call vm_vagrant,create kata $(NAME))
else
	$(call vm_vagrant,up kata)
endif

create-observer: ## Create Observer host VM
ifdef NAME
	$(call vm_vagrant,create observer $(NAME))
else
	$(call vm_vagrant,up observer)
endif

create-router: ## Create Virtual Router VM
ifdef NAME
	$(call vm_vagrant,create router $(NAME))
else
	$(call vm_vagrant,up router)
endif

create-pfsense: ## Create pfSense Firewall VM
ifdef NAME
	$(call vm_vagrant,create pfsense $(NAME))
else
	$(call vm_vagrant,up pfsense)
endif

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

# Clean aliases (without create- prefix)
base: create-base        ## Alias for create-base
lxd: create-lxd          ## Alias for create-lxd  
docker: create-docker    ## Alias for create-docker
k8s: create-k8s          ## Alias for create-k8s
kata: create-kata        ## Alias for create-kata
observer: create-observer ## Alias for create-observer
router: create-router    ## Alias for create-router
pfsense: create-pfsense  ## Alias for create-pfsense