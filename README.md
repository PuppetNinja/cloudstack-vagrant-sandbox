This project creates a sandbox to set up a small scale cloudstack with vagrant

I will switch to use vagrant-libvirt, originally I saw there is VT-x enabled in latest Virtualbox 5,

however, according to https://www.virtualbox.org/ticket/4032

"I'm sorry but that depends on the definition of benefit. VirtualBox is an open source software but that does not mean that Oracle doesn't want to earn revenue with that product. To earn revenue we need to implement features which customers prefer to pay for."

Install vagrant plugin vagrant-libvirt:
    vagrant plugin install vagrant-libvirt

enable nested virtualization on host:
    echo 'options kvm-intel nested=y' >> /etc/modprobe.d/nest_kvm.conf

After installation process is finished, log into http://192.168.10.2:8080/client from the host

ref: 60 recipes of apache cloudstack
