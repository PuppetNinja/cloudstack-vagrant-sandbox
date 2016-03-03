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

log_info "Install openvswitch..."
cat > /etc/yum.repos.d/CentOS-cloud.repo << EOF
[cloud]
name=CentOS-$releasever - Cloud
baseurl=http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-liberty
gpgcheck=0
EOF

yum install -y --quiet openvswitch


#########################################################
# finish install and configure process
#########################################################
log_info "Install utils package..."
yum install -y --quiet vim
