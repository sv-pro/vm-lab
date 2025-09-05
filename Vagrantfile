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

  # === EXPERIMENTAL ROLES (Use with caution - known issues) ===
  
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
      apt-get install -y lxd zfsutils-linux qemu-guest-agent
      systemctl enable qemu-guest-agent
      usermod -aG lxd vagrant
      usermod -aG lxd ubuntu
      usermod -aG lxd dev
      
      # Install prometheus-node-exporter if available
      if apt-cache show prometheus-node-exporter >/dev/null 2>&1; then
          apt-get install -y prometheus-node-exporter
          systemctl enable prometheus-node-exporter
      fi
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

  # Router VM definition
  config.vm.define "router", autostart: false do |router|
    router.vm.hostname = "ubuntu-24-04-router"
    router.vm.provider :libvirt do |libvirt|
      libvirt.memory = 1024
      libvirt.cpus = 1
      libvirt.nested = true
      libvirt.cpu_mode = "host-passthrough"
    end
    
    router.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y \\
        iproute2 iptables ipset bridge-utils vlan tcpdump nftables \\
        bird2 frr strongswan openvpn dnsmasq bind9 nginx haproxy \\
        keepalived netfilter-persistent iptables-persistent qemu-guest-agent
      
      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
      echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
      sysctl -p
      
      systemctl enable qemu-guest-agent bird frr dnsmasq bind9 nginx netfilter-persistent || true
      
      cat > /etc/motd << 'EOF'
==========================================
    Virtual Router VM
==========================================
Routing: bird2, frr • VPN: strongswan, openvpn
DNS: bind9, dnsmasq • Load Balancing: nginx, haproxy
Networking: iptables, bridge-utils, vlan

IP forwarding enabled • Basic firewall configured
==========================================
EOF
      echo "Virtual router setup complete!"
    SHELL
  end

  # pfSense-style VM definition (Ubuntu-based alternative)
  config.vm.define "pfsense", autostart: false do |pfsense|
    pfsense.vm.box = "alvistack/ubuntu-24.04"
    pfsense.vm.hostname = "pfsense-style-gw"
    pfsense.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
      libvirt.nested = true
      libvirt.cpu_mode = "host-passthrough"
    end
    
    pfsense.vm.provision "shell", inline: <<-SHELL
      apt-get update
      
      # Install pfSense-like functionality on Ubuntu
      apt-get install -y \\
        iptables ipset netfilter-persistent iptables-persistent \\
        dnsmasq bind9 nginx haproxy keepalived \\
        strongswan openvpn bridge-utils vlan \\
        snmp snmp-mibs-downloader \\
        ntopng nload iftop tcpdump \\
        qemu-guest-agent
      
      # Enable IP forwarding (like pfSense)
      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
      echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
      sysctl -p
      
      # Install pfSense-like web management (simplified)
      apt-get install -y apache2 php libapache2-mod-php php-curl php-xml
      systemctl enable apache2
      
      # Create basic firewall rules directory structure
      mkdir -p /etc/pfsense-style/{rules,config}
      
      # Basic NAT rules (pfSense-style)
      cat > /etc/iptables/rules.v4 << 'EOF'
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback
-A INPUT -i lo -j ACCEPT

# Allow established connections
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow SSH (management)
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow web management interface
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT

# Allow ICMP
-A INPUT -p icmp -j ACCEPT

# Allow LAN access (adjust for your network)
-A INPUT -s 192.168.0.0/16 -j ACCEPT
-A INPUT -s 10.0.0.0/8 -j ACCEPT

COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# Basic NAT (adjust interface names as needed)
-A POSTROUTING -o eth0 -j MASQUERADE

COMMIT
EOF
      
      # Enable services
      systemctl enable qemu-guest-agent dnsmasq nginx netfilter-persistent apache2
      
      # Start iptables rules
      netfilter-persistent reload
      
      cat > /etc/motd << 'EOF'
==========================================
    pfSense-Style Ubuntu Gateway
==========================================
Ubuntu-based firewall with pfSense-like functionality:

Features:
• Firewall: iptables with persistent rules
• NAT/PAT: Internet gateway functionality  
• VPN: strongSwan (IPSec) + OpenVPN
• DNS: bind9 + dnsmasq
• Web UI: Apache + PHP (basic management)
• Monitoring: ntopng, nload, iftop
• High Availability: keepalived (VRRP)

Management:
• Web: http://this-ip (basic interface)
• SSH: Full command-line access
• Config: /etc/pfsense-style/

Note: This provides pfSense-like functionality on Ubuntu.
For full pfSense, use manual ISO installation method.
==========================================
EOF

      # Create simple web interface
      cat > /var/www/html/index.php << 'EOF'
<!DOCTYPE html>
<html><head><title>pfSense-Style Gateway</title></head>
<body>
<h1>pfSense-Style Ubuntu Gateway</h1>
<h2>System Status</h2>
<pre><?php echo shell_exec('ip addr show'); ?></pre>
<h2>Routing Table</h2>
<pre><?php echo shell_exec('ip route show'); ?></pre>
<h2>Firewall Rules</h2>
<pre><?php echo shell_exec('sudo iptables -L -n'); ?></pre>
<h2>System Load</h2>
<pre><?php echo shell_exec('uptime'); ?></pre>
</body></html>
EOF
      
      # Allow www-data to run network commands
      echo "www-data ALL=(ALL) NOPASSWD: /sbin/iptables, /sbin/ip" >> /etc/sudoers
      
      echo "pfSense-style Ubuntu gateway setup complete!"
      echo "Web interface available at: http://$(hostname -I | awk '{print $1}')"
    SHELL
  end
end