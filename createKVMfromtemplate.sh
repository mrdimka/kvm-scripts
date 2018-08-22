#!/bin/bash

function ubuntuNetwork {

cat <<EOF > "$kvm_mnt_dir"/etc/network/interfaces

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
        address $IPaddress
        netmask $NETMASK
        network $NETWORK
        broadcast $BROADCAST
        gateway $GATEWAY
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers 8.8.8.8
EOF

cat <<EOF > "$kvm_mnt_dir"/etc/networks
default         0.0.0.0
loopback        127.0.0.0
link-local      169.254.0.0
localnet        $NETWORK
EOF

echo "$new_kvm_name" > "$kvm_mnt_dir"/etc/hostname
rm -rf "$kvm_mnt_dir"/etc/ssh/ssh_host*
chroot $kvm_mnt_dir /bin/bash -c "dpkg-reconfigure openssh-server"


}

function ubuntu16Network {

cat <<EOF > "$kvm_mnt_dir"/etc/network/interfaces

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ens3
iface ens3 inet static
        address $IPaddress
        netmask $NETMASK
        network $NETWORK
        broadcast $BROADCAST
        gateway $GATEWAY
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers 8.8.8.8
EOF

cat <<EOF > "$kvm_mnt_dir"/etc/networks
default         0.0.0.0
loopback        127.0.0.0
link-local      169.254.0.0
localnet        $NETWORK
EOF

echo "$new_kvm_name" > "$kvm_mnt_dir"/etc/hostname
rm -rf "$kvm_mnt_dir"/etc/ssh/ssh_host*
chroot $kvm_mnt_dir /bin/bash -c "dpkg-reconfigure openssh-server"


}

function ubuntu18Network {
echo "ubuntu 18 my address"

echo $IPaddress > "$kvm_mnt_dir"/root/myaddr

cat <<EOF > "$kvm_mnt_dir"/etc/netplan/01-netcfg.yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      addresses: [ $IPaddress/25 ]
      gateway4: $GATEWAY
      nameservers:
          addresses:
              - "8.8.8.8"
EOF


cat <<EOF > "$kvm_mnt_dir"/etc/networks
default         0.0.0.0
loopback        127.0.0.0
link-local      169.254.0.0
localnet        $NETWORK
EOF

echo "$new_kvm_name" > "$kvm_mnt_dir"/etc/hostname
rm -rf "$kvm_mnt_dir"/etc/ssh/ssh_host*
#chroot $kvm_mnt_dir /bin/bash -c "export PATH="/bin:$PATH" && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure openssh-server"
chroot $kvm_mnt_dir /bin/bash -c "export PATH="/bin:$PATH" && dpkg-reconfigure openssh-server"


}

function centosNetwork {

cat <<EOF > "$kvm_mnt_dir"/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=static
BROADCAST=$BROADCAST
IPADDR=$IPaddress
NETMASK=$NETMASK
NETWORK=$NETWORK
ONBOOT=yes
EOF

cat <<EOF > "$kvm_mnt_dir"/etc/sysconfig/network
NETWORKING=yes
NETWORKING_IPV6=no
HOSTNAME=$new_kvm_name
GATEWAY=$GATEWAY
EOF

echo "$new_kvm_name" > "$kvm_mnt_dir"/etc/hostname

}




if [ ! -z $1 ]
 then
  echo "Using config file $1"
  source $1
 else
  echo "No config file is used"
  exit 1
fi


if [[ -z $template_kvm || -z $new_kvm_name || -z $kvm_image_dir || -z $kvm_xml_dir || -z $kvm_mnt_dir || -z $IPaddress || -z $NETWORK || -z $NETMASK || -z $BROADCAST || -z $GATEWAY ]]
 then
  echo "some variables are missing from config file"
  exit 1
 else
  echo "All variables OK"
fi

if [[ -f "$kvm_image_dir"/"$new_kvm_name".img || -f "$kvm_xml_dir"/"$new_kvm_name".xml ]];
 then 
  echo "KVM img file exists. Please check before executing the script"
  exit 1
 else
  echo "Everything seems OK..."
fi


if [[ "$template_kvm" == "centos5" || "$template_kvm" == "centos6" || "$template_kvm" == "centos7" || "$template_kvm" == "ubuntu12" || "$template_kvm" == "ubuntu14" || "$template_kvm" == "ubuntu16"  || "$template_kvm" == "ubuntu18" ]]
 then 
  echo "Known template... continuing"

  # copy template img file
  echo "Copying template image file..."
  cp $kvm_image_dir/{"$template_kvm"-default,"$new_kvm_name"}.img


  # copy xml
  echo "Copying xml file..."
  cp "$kvm_xml_dir"/{"$template_kvm","$new_kvm_name"}.xml

  # change remove uuid and mac from xml
  echo "Removing uuid and mac address from xml file..."
  sed -i /uuid/d "$kvm_xml_dir"/"$new_kvm_name".xml
  sed -i '/mac address/d' "$kvm_xml_dir"/"$new_kvm_name".xml
  sed -i s/"$template_kvm"/"$new_kvm_name"/ "$kvm_xml_dir"/"$new_kvm_name".xml

  #define xml
  echo "Defining xml file"
  virsh define "$kvm_xml_dir"/"$new_kvm_name".xml

  # change/configure network settings - kpartx, mount etc
  echo "Mounting image file to configure network"
  kpartx -a "$kvm_image_dir"/"$new_kvm_name".img
  sleep 20
  mount /dev/mapper/loop0p1 $kvm_mnt_dir

   case $template_kvm in
   	centos5) 
			echo "Configuring network for centos 5 template"
			centosNetwork
			;;
    centos6) 
      echo "Configuring network for centos 6 template"
      centosNetwork
      ;;  
    centos7) 
      echo "Configuring network for centos 7 template"
      centosNetwork
      ;;
		ubuntu12) 
			echo "Configuring network for ubuntu 12 template"
			ubuntuNetwork
			;;
		ubuntu14) 
			echo "Configuring network for ubuntu 14 template"
			ubuntuNetwork
			;;
		ubuntu16) 
			echo "Configuring network for ubuntu 16 template"
			ubuntu16Network
			;;
		ubuntu18) 
			echo "Configuring network for ubuntu 18 template"
			ubuntu18Network
			;;
	 esac

   if [ -z "$ssh_keys" ]
    then
    echo "no ssh keys found to add"
   else
    echo "Adding ssh keys found"
    mkdir "$kvm_mnt_dir"/root/.ssh/
    # double quotes needed on ssh_keys variable otherwise new lines won't be added when adding multiple ssh keys
    echo "$ssh_keys" > "$kvm_mnt_dir"/root/.ssh/authorized_keys
   fi
  
  echo "Umounting image file"
  umount $kvm_mnt_dir
  kpartx -d "$kvm_image_dir"/"$new_kvm_name".img
  echo "Script finished..."
  echo "DON'T forget to change the root password..."
  exit 0

 else
  echo "Unknown template.. Exiting !!!" 
  exit 1
fi


