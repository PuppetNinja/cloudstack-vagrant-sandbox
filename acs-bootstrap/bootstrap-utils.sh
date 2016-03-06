#!/bin/bash
#########################################################
# utility functions
#########################################################
log_info() {
  echo "INFO: $1"
}

log_warn() {
  echo "WARN: $1"
}

log_error() {
  echo "ERROR: $1"
  exit 255
}

reset_rt_pw() {
# reset root password to acs
  expect -c "
set timeout 30

spawn passwd root

expect \"New password:\"
send   \"cloudstack\r\"

expect \"Retype new password:\"
send   \"cloudstack\r\"

expect eof
"
}

#########################################################
# install expect and reset root password
#########################################################
log_info "Install Expect..."
yum install -y --quiet expect

reset_rt_pw

cat >> /etc/hosts << EOF
192.168.10.2   cloudstack-mgmt.acs-sandbox.priv cloudstack-mgmt
192.168.10.3   cloudstack-agent1.acs-sandbox.priv cloudstack-agent1
192.168.10.4   cloudstack-agent2.acs-sandbox.priv cloudstack-agent2
EOF
