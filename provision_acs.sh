#!/bin/bash

# bring up vms, do the install
vagrant up --provider=virtualbox

if [[ $? -eq 0 ]]
then
    echo "Successfully bring up the sandbox environment, reboot to load some of the configs"
    vagrant reload
else
    echo "Failed to bring up the sandbox environment, run 'vagrant destroy' to clean up..."
fi
