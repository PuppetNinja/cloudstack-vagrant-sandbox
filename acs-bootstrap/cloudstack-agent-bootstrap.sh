#!/bin/bash

# The process of configuration follows
# http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/management-server/index.html

source "/home/vagrant/sync/acs-bootstrap/bootstrap-utils.sh"

#########################################################
# start install and configure process
#########################################################
# set hostname
# the hostname has been set by Vagrantfile

# install ntp
log_info "Install Ntp..."
yum install -y --quiet ntp

# configure cloudstack repo info
cat > /etc/yum.repos.d/cloudstack.repo << EOF
[cloudstack]
name=cloudstack
baseurl=http://cloudstack.apt-get.eu/centos/7/4.8/
enabled=1
gpgcheck=0
EOF

# install cloudstack-management
log_info "Install cloudstack-agent..."
yum install -y --quiet cloudstack-agent

# config selinux, add sudo just ensure setenforce is run as root
if getenforce | grep 'Enforcing'
then
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
fi

# This is a sandbox so we just disable security rules
for srv in "iptables firewalld"
do
    systemctl disable ${srv}
    systemctl stop  ${srv}
done

# Add sudoer conf for cloudstack user
cat > /etc/sudoers.d/01_cloudstack.conf << EOF
cloudstack ALL=NOPASSWD: /usr/bin/cloudstack-setup-agent
defaults:cloudstack !requiretty
EOF

# Disable the security for libvirt tls communication, they are all commented out in the
# libvirtd conf
cat >> /etc/libvirt/libvirtd.conf << EOF
listen_tls = 0
listen_tcp = 1
tcp_port = "16509"
auth_tcp = "none"
mdns_adv = 0
EOF

sed -i 's/#LIBVIRTD_ARGS="--listen"/LIBVIRTD_ARGS="--listen"/' /etc/sysconfig/libvirtd

systemctl restart libvirtd

# configure cloudstack agent network part
systemctl disable NetworkManager
systemctl stop NetworkManager

log_info "Install openvswitch..."
cat > /etc/yum.repos.d/CentOS-cloud.repo << EOF
[cloud]
name=CentOS-\$releasever - Cloud
baseurl=http://mirror.centos.org/centos/\$releasever/cloud/\$basearch/openstack-liberty
gpgcheck=0
EOF

yum install -y --quiet openvswitch


# config eth1 interface
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
NM_CONTROLLED
BOOTPROTO=none
ONBOOT=yes
DEVICE=eth1
PEERDNS=no
BRIDGE=cloudbr
EOF

# get hostname to configure ovs bridge
if [[ $(hostname -f) =~ agent1 ]]
then
# config cloudbr bridge
    cat > /etc/sysconfig/network-scripts/ifcfg-cloudbr << EOF
DEVICE=cloudbr
ONBOOT=yes
HOTPLUG=no
BOOTPROTO=none
IPADDR=192.168.10.3
GATEWAY=192.168.10.1
NETMASK=255.255.255.0
#DEVICETYPE=ovs
#TYPE=OVSBridge
TYPE=Bridge
EOF

elif [[ $(hostname -f) =~ agent2 ]]
then
# config cloudbr bridge
    cat > /etc/sysconfig/network-scripts/ifcfg-cloudbr << EOF
DEVICE=cloudbr
ONBOOT=yes
HOTPLUG=no
IPADDR=192.168.10.4
GATEWAY=192.168.10.1
NETMASK=255.255.255.0
BOOTPROTO=none
#DEVICETYPE=ovs
#TYPE=OVSBridge
TYPE=Bridge
EOF

fi


# start openvswitch
#systemctl enable openvswitch
#systemctl start  openvswitch

#restart network to bring up cloudbr and eth1
/etc/init.d/network restart

#remove the legacy default gateway
ip route del 0/0

#ip link set eth1 up
#brctl addif cloudbr eth1

ip route add default via 192.168.10.2 dev cloudbr
#ovs-vsctl add-port cloudbr eth1

log_info "Starting cloudstack-agent service"
systemctl start cloudstack-agent
#########################################################
# finish install and configure process
#########################################################
log_info "Install utils package..."
yum install -y --quiet vim
