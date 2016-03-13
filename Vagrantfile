# *- mode: ruby -*-
# vi: set ft=ruby :


domain = 'acs-sandbox.priv'
agent_num = 2

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  config.vm.define "cloudstack-mgmt-server" do |cloudstack_mgmt|

    cloudstack_mgmt.vm.box = "centos/7"
    cloudstack_mgmt.vm.hostname = "cloudstack-mgmt.#{domain}"

    cloudstack_mgmt.vm.network :private_network,
      :ip => "192.168.10.2",
      :libvirt_netmask => "255.255.255.0"

    # cloustack management vm 4GB ram and 2 vpus
    cloudstack_mgmt.vm.provider "libvirt" do |acs_mgmt_domain|
      acs_mgmt_domain.uri    = 'qemu+unix:///system'
      acs_mgmt_domain.driver = 'kvm'
      acs_mgmt_domain.host   = "cloustack-mgmt-server"
      acs_mgmt_domain.memory = 2048 
      acs_mgmt_domain.cpus   = 2
    end

    # run bootstrap for cloudstack management server
    cloudstack_mgmt.vm.provision "shell", path: "acs-bootstrap/cloudstack-mgmt-bootstrap.sh"
  end

  #config for cloudstack agent
  (1..agent_num).each do |i|

    config.vm.define "cloudstack-agent#{i}" do |cloudstack_agent|

      cloudstack_agent.vm.box = "centos/7"
      cloudstack_agent.vm.hostname = "cloudstack-agent#{i}.#{domain}"
      # config the host_only network
      agent_ip = 2 + i

      cloudstack_agent.vm.network :private_network,
        :ip => "192.168.10.#{agent_ip}",
        :libvirt_netmask => "255.255.255.0"

      cloudstack_agent.vm.provider "libvirt" do |acs_agt_domain|
        acs_agt_domain.uri    = 'qemu+unix:///system'
        acs_agt_domain.driver = 'kvm'
        acs_agt_domain.host   = "cloustack-agent#{i}"
        acs_agt_domain.memory = 1024 
        acs_agt_domain.cpus   = 2
        acs_agt_domain.nested = true
      end

      cloudstack_agent.vm.provision "shell", path: "acs-bootstrap/cloudstack-agent-bootstrap.sh"
    end
  end
end
