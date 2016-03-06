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
log_info "Install cloudstack-management..."
yum install -y --quiet cloudstack-management

# install mysql-server, update the repo link if necessary
yum install -y --quiet 'http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm'

# install and configure mysql
log_info "Install mysql-server..."
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
cloudstack-setup-databases "cloud:cloudstack@localhost" \
--deploy-as="root:cloudstack" \
-m "cloudstack" \
-k "cloudstack" \
-i "192.168.10.2"

# finish the cloustack management server setup
cloudstack-setup-management --tomcat7

# config nfs share as primary and secondary storage
log_info "Install nfs-utils..."
yum install -y --quiet nfs-utils

mkdir -p /export/primary
mkdir -p /export/secondary

echo "/export  *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports

exportfs -a

cat >> /etc/sysconfig/nfs << EOF
LOCKD_TCPPORT=32803
LOCKD_UDPPORT=32769
MOUNTD_PORT=892
RQUOTAD_PORT=875
STATD_PORT=662
STATD_OUTGOING_PORT=2020
EOF

# This is a sandbox so we just disable security rules
for srv in "iptables firewalld"
do
    systemctl disable ${srv}
    systemctl stop  ${srv}
done

for srv in "rpc-bind nfs-server"
do
    systemctl enable ${srv}
    systemctl restart  ${srv}
done

# create the mount point on localhost, since it is also a nfs client
SEC_MOUNT="/mnt/secondary"
[[ ! -d ${SEC_MOUNT} ]] && mkdir -p ${SEC_MOUNT}

echo "$(hostname -f):/export/secondary   ${SEC_MOUNT}   nfs   defaults   0 0" >> /etc/fstab
mount ${SEC_MOUNT} 


# Uncomment this line when NFSv4 communication is needed between client and server
# sed -i 's/#Domain = local.domain.edu/Domain = acs-sandbox.priv/' /etc/idmapd.conf

# Install system vm template
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt \
-m /mnt/secondary \
-u http://cloudstack.apt-get.eu/systemvm/4.6/systemvm64template-4.6.0-kvm.qcow2.bz2 \
-h kvm \
-F

# change the permission for the logs
chmod -R 777 /var/log/cloudstack
chmod -R 777 /var/log/cloudstack-management

# Enable ip forward on cloudstack-mgmt-server
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# start cloudstack-management service
systemctl start cloudstack-management

# Install cloud-moneky
yum install -y --quiet python-pip python-devel
pip install cloudmonkey

#########################################################
# finish install and configure process
#########################################################
log_info "Install utils package..."
yum install -y --quiet vim
