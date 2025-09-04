# VM Lab Makefile
# Wrapper for Vagrant operations with role-based VM management

# Default variables
DEFAULT_NAME ?= 
ROLE ?= base

# Helper to run vagrant with proper VM names
define vagrant_cmd
	@vagrant $(1)
endef

# Helper to get VM name (use provided NAME or default role-based name)
define get_vm_name
$(if $(NAME),$(NAME),ubuntu-24-04-$(1))
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
	@echo "Creating base VM with name: $(NAME)"
	@vagrant up base
	@echo "Note: VM is running as 'base' but you can reference it as '$(NAME)' in other commands"
else
	@echo "Creating base VM with default name: ubuntu-24-04-base"
	$(call vagrant_cmd,up base)
endif

create-lxd: ## Create LXD host VM  
ifdef NAME
	@echo "Creating LXD VM with name: $(NAME)"
	@vagrant up lxd
	@echo "Note: VM is running as 'lxd' but you can reference it as '$(NAME)' in other commands"
else
	@echo "Creating LXD VM with default name: ubuntu-24-04-lxd"
	$(call vagrant_cmd,up lxd)
endif

create-docker: ## Create Docker host VM
ifdef NAME
	@echo "Creating Docker VM with name: $(NAME)"
	@vagrant up docker
	@echo "Note: VM is running as 'docker' but you can reference it as '$(NAME)' in other commands"
else
	@echo "Creating Docker VM with default name: ubuntu-24-04-docker"
	$(call vagrant_cmd,up docker)
endif

create-k8s: ## Create Kubernetes host VM
ifdef NAME
	@echo "Creating Kubernetes VM with name: $(NAME)"
	@vagrant up k8s
	@echo "Note: VM is running as 'k8s' but you can reference it as '$(NAME)' in other commands"
else
	@echo "Creating Kubernetes VM with default name: ubuntu-24-04-k8s"
	$(call vagrant_cmd,up k8s)
endif

create-kata: ## Create Kata host VM
ifdef NAME
	@echo "Creating Kata VM with name: $(NAME)"
	@vagrant up kata
	@echo "Note: VM is running as 'kata' but you can reference it as '$(NAME)' in other commands"
else
	@echo "Creating Kata VM with default name: ubuntu-24-04-kata"
	$(call vagrant_cmd,up kata)
endif

create-observer: ## Create Observer host VM
ifdef NAME
	@echo "Creating Observer VM with name: $(NAME)"
	@vagrant up observer
	@echo "Note: VM is running as 'observer' but you can reference it as '$(NAME)' in other commands"
else
	@echo "Creating Observer VM with default name: ubuntu-24-04-observer"
	$(call vagrant_cmd,up observer)
endif

# VM Management targets  
.PHONY: list start stop ssh delete status
list: ## List all VM images and running VMs
	$(call vagrant_cmd,status)

start: ## Start a VM
ifdef NAME
	@echo "Starting VM: $(NAME)"
	@if [ "$(NAME)" = "base" ] || [ "$(NAME)" = "ubuntu-24-04-base" ]; then \
		vagrant up base; \
	elif [ "$(NAME)" = "docker" ] || [ "$(NAME)" = "ubuntu-24-04-docker" ]; then \
		vagrant up docker; \
	elif [ "$(NAME)" = "k8s" ] || [ "$(NAME)" = "ubuntu-24-04-k8s" ]; then \
		vagrant up k8s; \
	elif [ "$(NAME)" = "lxd" ] || [ "$(NAME)" = "ubuntu-24-04-lxd" ]; then \
		vagrant up lxd; \
	elif [ "$(NAME)" = "kata" ] || [ "$(NAME)" = "ubuntu-24-04-kata" ]; then \
		vagrant up kata; \
	elif [ "$(NAME)" = "observer" ] || [ "$(NAME)" = "ubuntu-24-04-observer" ]; then \
		vagrant up observer; \
	else \
		echo "Error: Unknown VM name '$(NAME)'"; \
		echo "Available VMs: base, docker, k8s, lxd, kata, observer"; \
		echo "Or use full names: ubuntu-24-04-{role}"; \
		exit 1; \
	fi
else
	@echo "Error: NAME parameter is required for start operation"
	@echo "Usage: make start NAME=<vm-name>"
	@echo "Available VMs: base, docker, k8s, lxd, kata, observer"
	@exit 1
endif

stop: ## Stop a VM
ifdef NAME
	@echo "Stopping VM: $(NAME)"
	@if [ "$(NAME)" = "base" ] || [ "$(NAME)" = "ubuntu-24-04-base" ]; then \
		vagrant halt base; \
	elif [ "$(NAME)" = "docker" ] || [ "$(NAME)" = "ubuntu-24-04-docker" ]; then \
		vagrant halt docker; \
	elif [ "$(NAME)" = "k8s" ] || [ "$(NAME)" = "ubuntu-24-04-k8s" ]; then \
		vagrant halt k8s; \
	elif [ "$(NAME)" = "lxd" ] || [ "$(NAME)" = "ubuntu-24-04-lxd" ]; then \
		vagrant halt lxd; \
	elif [ "$(NAME)" = "kata" ] || [ "$(NAME)" = "ubuntu-24-04-kata" ]; then \
		vagrant halt kata; \
	elif [ "$(NAME)" = "observer" ] || [ "$(NAME)" = "ubuntu-24-04-observer" ]; then \
		vagrant halt observer; \
	else \
		echo "Error: Unknown VM name '$(NAME)'"; \
		echo "Available VMs: base, docker, k8s, lxd, kata, observer"; \
		exit 1; \
	fi
else
	@echo "Error: NAME parameter is required for stop operation"
	@echo "Usage: make stop NAME=<vm-name>"
	@echo "Available VMs: base, docker, k8s, lxd, kata, observer"
	@exit 1
endif

ssh: ## SSH into a running VM
ifdef NAME
	@echo "Connecting to VM: $(NAME)"
	@if [ "$(NAME)" = "base" ] || [ "$(NAME)" = "ubuntu-24-04-base" ]; then \
		vagrant ssh base; \
	elif [ "$(NAME)" = "docker" ] || [ "$(NAME)" = "ubuntu-24-04-docker" ]; then \
		vagrant ssh docker; \
	elif [ "$(NAME)" = "k8s" ] || [ "$(NAME)" = "ubuntu-24-04-k8s" ]; then \
		vagrant ssh k8s; \
	elif [ "$(NAME)" = "lxd" ] || [ "$(NAME)" = "ubuntu-24-04-lxd" ]; then \
		vagrant ssh lxd; \
	elif [ "$(NAME)" = "kata" ] || [ "$(NAME)" = "ubuntu-24-04-kata" ]; then \
		vagrant ssh kata; \
	elif [ "$(NAME)" = "observer" ] || [ "$(NAME)" = "ubuntu-24-04-observer" ]; then \
		vagrant ssh observer; \
	else \
		echo "Error: Unknown VM name '$(NAME)'"; \
		echo "Available VMs: base, docker, k8s, lxd, kata, observer"; \
		exit 1; \
	fi
else
	@echo "Error: NAME parameter is required for ssh operation"
	@echo "Usage: make ssh NAME=<vm-name>"
	@echo "Available VMs: base, docker, k8s, lxd, kata, observer"
	@exit 1
endif

delete: ## Delete a VM
ifndef NAME
	@echo "Error: NAME parameter is required for delete operation"
	@echo "Usage: make delete NAME=<vm-name>"
	@exit 1
endif
	@echo "Deleting VM: $(NAME)"
	@if [ "$(NAME)" = "base" ] || [ "$(NAME)" = "ubuntu-24-04-base" ]; then \
		vagrant destroy -f base; \
	elif [ "$(NAME)" = "docker" ] || [ "$(NAME)" = "ubuntu-24-04-docker" ]; then \
		vagrant destroy -f docker; \
	elif [ "$(NAME)" = "k8s" ] || [ "$(NAME)" = "ubuntu-24-04-k8s" ]; then \
		vagrant destroy -f k8s; \
	elif [ "$(NAME)" = "lxd" ] || [ "$(NAME)" = "ubuntu-24-04-lxd" ]; then \
		vagrant destroy -f lxd; \
	elif [ "$(NAME)" = "kata" ] || [ "$(NAME)" = "ubuntu-24-04-kata" ]; then \
		vagrant destroy -f kata; \
	elif [ "$(NAME)" = "observer" ] || [ "$(NAME)" = "ubuntu-24-04-observer" ]; then \
		vagrant destroy -f observer; \
	else \
		echo "Error: Unknown VM name '$(NAME)'"; \
		echo "Available VMs: base, docker, k8s, lxd, kata, observer"; \
		exit 1; \
	fi

status: ## Check VM status
	$(call vagrant_cmd,status)

# Convenience targets
.PHONY: clean
clean: ## Stop all VMs and clean up
	@echo "Stopping all running VMs..."
	$(call vagrant_cmd,halt)
	@echo "All VMs stopped"

# Development shortcuts
.PHONY: dev-vm web-vm
dev-vm: ## Create and start a development VM
	@echo "Creating and starting development VM..."
	@vagrant up base
	@echo "Development VM ready. Connect with: make ssh NAME=base"

web-vm: ## Create and start a web server VM
	@echo "Creating and starting web server VM..."
	@vagrant up docker
	@echo "Web server VM ready. Connect with: make ssh NAME=docker"