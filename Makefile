# VM Lab Makefile
# Wrapper for vm-manage.sh operations

# Default variables
VM_MANAGE_SCRIPT := ./vm-manage.sh
DEFAULT_NAME ?= 
ROLE ?= base

# Helper to run vm-manage.sh
define vm_manage
	@./vm-manage.sh $(1)
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
.PHONY: create-base create-lxd create-docker create-k8s create-kata create-observer
create-base: ## Create base Ubuntu VM
ifdef NAME
	$(call vm_manage,create base --name $(NAME))
else
	$(call vm_manage,create base)
endif

create-lxd: ## Create LXD host VM
ifdef NAME
	$(call vm_manage,create lxd --name $(NAME))
else
	$(call vm_manage,create lxd)
endif

create-docker: ## Create Docker host VM
ifdef NAME
	$(call vm_manage,create docker --name $(NAME))
else
	$(call vm_manage,create docker)
endif

create-k8s: ## Create Kubernetes host VM
ifdef NAME
	$(call vm_manage,create k8s --name $(NAME))
else
	$(call vm_manage,create k8s)
endif

create-kata: ## Create Kata host VM
ifdef NAME
	$(call vm_manage,create kata --name $(NAME))
else
	$(call vm_manage,create kata)
endif

create-observer: ## Create Observer host VM
ifdef NAME
	$(call vm_manage,create observer --name $(NAME))
else
	$(call vm_manage,create observer)
endif

# VM Management targets
.PHONY: list start stop ssh delete status
list: ## List all VM images and running VMs
	$(call vm_manage,list)

start: ## Start a VM
ifdef NAME
	$(call vm_manage,start --name $(NAME))
else
	$(call vm_manage,start)
endif

stop: ## Stop a VM
ifdef NAME
	$(call vm_manage,stop --name $(NAME))
else
	$(call vm_manage,stop)
endif

ssh: ## SSH into a running VM
ifdef NAME
	$(call vm_manage,ssh --name $(NAME))
else
	$(call vm_manage,ssh)
endif

delete: ## Delete a VM
ifndef NAME
	@echo "Error: NAME parameter is required for delete operation"
	@echo "Usage: make delete NAME=<vm-name>"
	@exit 1
endif
	$(call vm_manage,delete --name $(NAME))

status: ## Check VM status
	$(call vm_manage,status)

# Convenience targets
.PHONY: clean
clean: ## Stop all VMs and clean up
	@echo "Stopping all running VMs..."
	@pkill -f qemu-system-x86_64 || true
	@echo "All VMs stopped"

# Development shortcuts
.PHONY: dev-vm web-vm
dev-vm: ## Create and start a development VM
	make create-base NAME=dev-vm
	make start NAME=dev-vm

web-vm: ## Create and start a web server VM
	make create-docker NAME=web-vm
	make start NAME=web-vm