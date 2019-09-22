# Basic setup information
url --url="http://mirror.centos.org/altarch/7/os/armhfp/"
install
keyboard us --xlayouts=us --vckeymap=us
lang en_US.UTF-8
rootpw centos
timezone --isUtc --nontp UTC
selinux --disabled
firewall --enabled --port=22
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=sshd,NetworkManager,chronyd
shutdown
bootloader --location=mbr


# Repositories to use
repo --name="base"          --baseurl=http://mirror.centos.org/altarch/7/os/armhfp/      --cost=100
repo --name="updates"       --baseurl=http://mirror.centos.org/altarch/7/updates/armhfp/ --cost=100
repo --name="extras"        --baseurl=http://mirror.centos.org/altarch/7/extras/armhfp/  --cost=100
repo --name="centos-kernel" --baseurl=http://mirror.centos.org/altarch/7/kernel/armhfp/kernel-generic/  --cost=100

# Package setup
%packages
@core
kernel-lpae
grubby
dracut-config-generic
-dracut-config-rescue
chrony
net-tools
cloud-utils-growpart
%end

# Disk setup
clearpart --initlabel --all
part /boot --fstype=ext4 --size=500  --label=boot   --asprimary --ondisk img
part /     --fstype=ext4 --size=2000 --label=rootfs --asprimary --ondisk img

%pre
#End of Pre script for partitions
%end


%post

# Setting correct yum variable to use mainline kernel repo
echo "Setting up kernel variant..."
echo "generic" > /etc/yum/vars/kvariant


# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Cleanup yum cache
yum clean all

%end
