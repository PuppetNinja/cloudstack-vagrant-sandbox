#!/bin/bash

# The process of configuration follows
# http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/management-server/index.html

# set hostname
# the hostname has been set by vagrant

# install ntp
yum install -y ntp

# configure cloudstack repo info
cat > /etc/yum.repos.d/cloudstack.repo << EOF
[cloudstack]
name=cloudstack
baseurl=http://cloudstack.apt-get.eu/centos/7/4.8/
enabled=1
gpgcheck=0
EOF

# install cloudstack-management
yum install -y cloudstack-management

# install mysql-server, update the repo link if necessary
yum install -y http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
yum install -y mysql-server




