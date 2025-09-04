# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Common configuration for all VMs
  config.vm.box = "alvistack/ubuntu-24.04"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Configure libvirt provider
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 2048
    libvirt.cpus = 2
    libvirt.graphics_type = "none"
    libvirt.management_network_name = "vagrant-libvirt"
    libvirt.management_network_address = "192.168.121.0/24"
  end

  # SSH key configuration
  config.ssh.insert_key = false
  config.ssh.private_key_path = ["packer/cloud-init/id_rsa", "~/.vagrant.d/insecure_private_key"]
  config.vm.provision "file", source: "packer/cloud-init/id_rsa.pub", destination: "/tmp/vagrant-pubkey"
  config.vm.provision "shell", inline: <<-SHELL
    mkdir -p /home/vagrant/.ssh
    cat /tmp/vagrant-pubkey >> /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh
    chmod 600 /home/vagrant/.ssh/authorized_keys
    
    # Also add to ubuntu user
    mkdir -p /home/ubuntu/.ssh
    cat /tmp/vagrant-pubkey >> /home/ubuntu/.ssh/authorized_keys
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh  
    chmod 600 /home/ubuntu/.ssh/authorized_keys
    
    # Create dev user
    useradd -m -s /bin/bash dev
    echo "dev:dev123" | chpasswd
    usermod -aG sudo dev
    mkdir -p /home/dev/.ssh
    cat /tmp/vagrant-pubkey >> /home/dev/.ssh/authorized_keys
    chown -R dev:dev /home/dev/.ssh
    chmod 700 /home/dev/.ssh
    chmod 600 /home/dev/.ssh/authorized_keys
    
    rm /tmp/vagrant-pubkey
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

  # Kubernetes VM definition
  config.vm.define "k8s", autostart: false do |k8s|
    k8s.vm.hostname = "ubuntu-24-04-k8s"
    k8s.vm.provider :libvirt do |libvirt|
      libvirt.memory = 4096
      libvirt.cpus = 2
    end
    
    k8s.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y snapd qemu-guest-agent
      systemctl enable qemu-guest-agent
      snap install microk8s --classic
      usermod -aG microk8s vagrant
      usermod -aG microk8s ubuntu
      usermod -aG microk8s dev
    SHELL
  end

  # LXD VM definition
  config.vm.define "lxd", autostart: false do |lxd|
    lxd.vm.hostname = "ubuntu-24-04-lxd"
    lxd.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end
    
    lxd.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y lxd zfsutils-linux prometheus-node-exporter qemu-guest-agent
      systemctl enable qemu-guest-agent
      usermod -aG lxd vagrant
      usermod -aG lxd ubuntu
      usermod -aG lxd dev
    SHELL
  end

  # Kata VM definition
  config.vm.define "kata", autostart: false do |kata|
    kata.vm.hostname = "ubuntu-24-04-kata"
    kata.vm.provider :libvirt do |libvirt|
      libvirt.memory = 4096
      libvirt.cpus = 2
    end
    
    kata.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y docker.io qemu-system-x86 qemu-guest-agent
      systemctl enable docker
      systemctl enable qemu-guest-agent
      
      # Install Kata containers
      ARCH=$(dpkg --print-architecture)
      KATA_VERSION="3.2.0"
      curl -fsSL https://github.com/kata-containers/kata-containers/releases/download/${KATA_VERSION}/kata-static-${KATA_VERSION}-${ARCH}.tar.xz | tar -xJf - -C /
      
      # Configure Docker for Kata
      mkdir -p /etc/docker
      cat > /etc/docker/daemon.json << 'EOF'
{
  "runtimes": {
    "kata-runtime": {
      "path": "/usr/bin/kata-runtime"
    }
  }
}
EOF
      
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
      apt-get install -y htop iftop nload tcpdump bpftrace bpfcc-tools \\
                         prometheus-node-exporter grafana-agent qemu-guest-agent
      systemctl enable qemu-guest-agent
      systemctl enable prometheus-node-exporter
    SHELL
  end
end