# text mode (no graphical mode)
text

# do not configure X
skipx

# install
install

# installation url
url --url=http://ftp.ntua.gr/pub/linux/centos/7/os/x86_64/

# Language support
lang en_US

# Keyboard
keyboard us

# Network
network --device eth0 --bootproto static --ip 192.168.1.2 --netmask 255.255.255.0 --gateway 192.168.1.254 --nameserver 8.8.8.8 --noipv6 --hostname centos7

# auth config
auth --useshadow --enablemd5

# root password
rootpw --iscrypted CHANGEME

# SElinux
selinux --disabled

# timezone
timezone  America/New_York

# bootloader
bootloader --location=mbr

# clear the MBR (Master Boot Record)
zerombr

# the Setup Agent is not started the first time the system boots
firstboot --disable

# Reboot after installation
reboot

# Logging lever
logging --level=info

# Remove all partitions
clearpart --all --initlabel

# create partitions on the system
part / --asprimary --fstype="ext4" --grow --size=1
part swap --recommended

# Packages installation
%packages
@core
wget
net-tools
--nobase
%end

%post
mkdir -p /root/.ssh
echo "MY_PUBLIC_SSH_KEY" > /root/.ssh/authorized_keys
%end
