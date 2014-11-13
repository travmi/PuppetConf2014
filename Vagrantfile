# -*- mode: ruby -*-
# vi: set ft=ruby :


# Set up /etc/hosts
$hostnames = <<EOF
echo "Setting up /etc/hosts"
echo -e "192.168.10.10\tpuppet\tpuppetlabs.local.lan\n192.168.10.11\trsyslog\trsyslog.local.lan\n192.168.10.12\telk\telk.local.lan\n192.168.10.13\tclient\tclient.local.lan\n" >> /etc/hosts
EOF

# Clean up /etc/resolv.conf if it tries to set domain/search
$resolv = <<EOF
echo "Sanitizing /etc/resolv.conf"
sed -i '/search/d' /etc/resolv.conf
sed -i '/domain/d' /etc/resolv.conf
EOF

# Install packages I like
$packages = <<EOF
echo "Installing extra packages"
yum update -y
yum install vim strace lsof tcpdump git htop rsync wget -y
EOF

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

 config.vm.define "master" do |master|
    master.vm.box = "chef/centos-6.6"
    master.vm.hostname = "puppet.local.lan"
    master.vm.network "private_network", ip: "192.168.10.10"
    master.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "512"]
    end
    # Install puppet master
    master.vm.provision "shell",
      inline: "sudo rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm; sudo yum update -y; sudo yum install puppet-server -y"
    # Set up autosigning for agents
    master.vm.provision "shell",
      inline: 'echo -e "rsyslog.local.lan\nelk.local.lan\nclient.local.lan\n" >> /etc/puppet/autosign.conf'
    # Remove templatedir from puppet master config, deprecated
    master.vm.provision "shell",
      inline: "sed -i '/templatedir/d' /etc/puppet/puppet.conf"
  end

  config.vm.define "rsyslog" do |rsyslog|
    rsyslog.vm.box = "chef/centos-6.6"
    rsyslog.vm.hostname = "rsyslog.local.lan"
    rsyslog.vm.network "private_network", ip: "192.168.10.11"
    rsyslog.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "512"]
    end 
  end

  config.vm.define "elk" do |elk|
    elk.vm.box = "chef/centos-6.6"
    elk.vm.hostname = "elk.local.lan"
    elk.vm.network "private_network", ip: "192.168.10.12"
    elk.vm.network "forwarded_port", guest: 9200, host: 9200
    elk.vm.network "forwarded_port", guest: 80, host: 8080
    elk.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "1024"]
    end
  end

  config.vm.define "client" do |client|
    client.vm.box = "chef/centos-6.6"
    client.vm.hostname = "client.local.lan"
    client.vm.network "private_network", ip: "192.168.10.13"
    client.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "256"]
    end
  end

  hosts = ["master", "rsyslog", "elk", "client"]
  hosts.each do |i|
    config.vm.define "#{i}" do |node|
        node.vm.provision "shell", inline: $hostnames
        node.vm.provision "shell", inline: $resolv
        node.vm.provision "shell", inline: $packages
    end
  end

  clients = ["rsyslog", "elk", "client"]
  clients.each do |i|
    config.vm.define "#{i}" do |node|
        node.vm.provision "shell",
          inline: "curl -k https://puppet.local.lan:8140/packages/current/install.bash | sudo bash"
        node.vm.provision "shell",
          inline: "puppet agent -t"
    end
  end

end
