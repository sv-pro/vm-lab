# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Common configuration for all VMs
  config.vm.box = "alvistack/ubuntu-24.04"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Configure libvirt provider (primary)
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 2048
    libvirt.cpus = 2
    libvirt.graphics_type = "none"
    libvirt.management_network_name = "vagrant-libvirt"
    libvirt.management_network_address = "192.168.121.0/24"
  end

  # Configure VirtualBox provider (fallback)
  config.vm.provider :virtualbox do |vb|
    vb.memory = 2048
    vb.cpus = 2
    vb.gui = false
    vb.linked_clone = true
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # SSH key configuration
  config.ssh.insert_key = false
  config.ssh.private_key_path = ["~/.vagrant.d/insecure_private_key"]
  
  # Common user setup for all VMs
  config.vm.provision "shell", inline: <<-SHELL
    # Create dev user with sudo access
    useradd -m -s /bin/bash dev
    echo "dev:dev123" | chpasswd
    usermod -aG sudo dev
    
    # Set password for ubuntu user for compatibility
    echo "ubuntu:ubuntu" | chpasswd
    
    # Configure SSH access for ubuntu user
    mkdir -p /home/ubuntu/.ssh
    cp /home/vagrant/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh  
    chmod 600 /home/ubuntu/.ssh/authorized_keys
    
    # Configure SSH access for dev user  
    mkdir -p /home/dev/.ssh
    cp /home/vagrant/.ssh/authorized_keys /home/dev/.ssh/authorized_keys
    chown -R dev:dev /home/dev/.ssh
    chmod 700 /home/dev/.ssh
    chmod 600 /home/dev/.ssh/authorized_keys
  SHELL

  # Base VM definition
  config.vm.define "base", autostart: false do |base|
    base.vm.hostname = "ubuntu-24-04-base"
    base.vm.provider :libvirt do |libvirt|
      libvirt.memory = 1024
      libvirt.cpus = 1
    end
    
    base.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y qemu-guest-agent cloud-init
      systemctl enable qemu-guest-agent
    SHELL
  end

  # Docker VM definition  
  config.vm.define "docker", autostart: false do |docker|
    docker.vm.hostname = "ubuntu-24-04-docker"
    docker.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end
    
    docker.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y docker.io docker-compose qemu-guest-agent
      systemctl enable docker
      systemctl enable qemu-guest-agent
      usermod -aG docker vagrant
      usermod -aG docker ubuntu  
      usermod -aG docker dev
    SHELL
  end


  # Observer VM definition
  config.vm.define "observer", autostart: false do |observer|
    observer.vm.hostname = "ubuntu-24-04-observer"
    observer.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end
    
    observer.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y htop iftop nload tcpdump bpftrace bpfcc-tools qemu-guest-agent
      systemctl enable qemu-guest-agent
      
      # Install prometheus-node-exporter if available
      if apt-cache show prometheus-node-exporter >/dev/null 2>&1; then
          apt-get install -y prometheus-node-exporter
          systemctl enable prometheus-node-exporter
      fi
    SHELL
  end

end