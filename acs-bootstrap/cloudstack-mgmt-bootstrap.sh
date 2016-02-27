#!/bin/bash

# The process of configuration follows
# http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/management-server/index.html

source bootstrap-utils.sh

yum install -y --quiet expect

#########################################################
# start install and configure process
#########################################################
# set hostname
# the hostname has been set by Vagrantfile

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
yum install -y --quiet cloudstack-management

# install mysql-server, update the repo link if necessary
yum install -y --quiet 'http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm'

# install and configure mysql
yum install -y --quiet mysql-server

cat > /etc/my.cnf.d/cloudstack.cnf << EOF
[mysqld]
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format = 'ROW'
EOF

systemctl restart mysqld

expect -c "
set timeout 30

spawn mysql_secure_installation

expect \"Enter current password for root\"
send   \"\r\"

expect \"Set root password\"
send   \"Y\r\"

expect \"New password\"
send   \"cloudstack\r\"

expect \"Re-enter new password\"
send   \"cloudstack\r\"

expect \"Remove anonymous users\"
send   \"Y\r\"

expect \"Disallow root login remotely\"
send   \"Y\r\"

expect \"Remove test database and access to it\"
send   \"Y\r\"

expect \"Reload privilege tables now\"
send   \"Y\r\"

expect eof
"
# config selinux, add sudo just ensure setenforce is run as root
if getenforce | grep 'Enforcing'
then
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
fi

# setup cloudstack database
cloudstack-setup-databases cloud:cloudstack@localhost \
--deploy-as=root:cloudstack \
-m cloudstack \
-k cloudstack 
# finish this after editing vagrant file
#-i <management_server_ip>

# config nfs share as primary and secondary storage
yum install -y nfs-utils

mkdir -p /export/primary
mkdir -p /export/secondary

echo "/export  *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports

exportfs -a

# create the mount point on localhost
SEC_MOUNT="/mnt/secondary"
[[ ! -d ${SEC_MOUNT} ]] && mkdir -p ${SEC_MOUNT} 

echo "$(hostname -f):/secondary ${SEC_MOUNT}   nfs  nfsvers=3,rw   0 0" >> /etc/fstab

mount /mnt/secondary
#########################################################
# finish install and configure process
#########################################################
yum install -y vim



