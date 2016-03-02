# *- mode: ruby -*-
# vi: set ft=ruby :


domain = 'acs-sandbox.priv'
agent_num = 2

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.box_check_update = true

  config.vm.define "cloudstack-mgmt-server" do |cloudstack_mgmt|
    cloudstack_mgmt.vm.hostname = "cloudstack-mgmt.#{domain}"
    # config the host_only network
    cloudstack_mgmt.vm.network "private_network",
      ip: "192.168.10.2",
      netmask: "255.255.255.0"
    # cloustack management vm 4GB ram and 2 vpus
    cloudstack_mgmt.vm.provider "virtualbox" do |acs_mgmt_vb|
      acs_mgmt_vb.name = "cloustack-mgmt-server"
      acs_mgmt_vb.memory = 2048
      acs_mgmt_vb.cpus = 2
    end
    # run bootstrap for cloudstack management server
    cloudstack_mgmt.vm.provision "shell", path: "acs-bootstrap/cloudstack-mgmt-bootstrap.sh"
  end

  #config for cloudstack agent
  (1..agent_num).each do |i|
    config.vm.define "cloudstack-agent#{i}" do |cloudstack_agent|
      cloudstack_agent.vm.hostname = "cloudstack-agent#{i}.#{domain}"
      # config the host_only network
      agent_ip = 2 + i
      cloudstack_agent.vm.network "private_network",
        ip: "192.168.10.#{agent_ip}",
        netmask: "255.255.255.0"
      cloudstack_agent.vm.provider "virtualbox" do |acs_agt_vb|
        acs_agt_vb.name = "cloustack-agent#{i}"
        acs_agt_vb.memory = 2048
        acs_agt_vb.cpus = 2
      end
      cloudstack_agent.vm.provision "shell", path: "acs-bootstrap/cloudstack-agent-bootstrap.sh"
    end
  end
end
