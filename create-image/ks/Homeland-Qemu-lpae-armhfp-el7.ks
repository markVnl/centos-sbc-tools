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
bootloader --location=partition


# Repositories to use
repo --name="inst-base"          --baseurl=http://mirror.centos.org/altarch/7/os/armhfp/      --cost=100
repo --name="inst-updates"       --baseurl=http://mirror.centos.org/altarch/7/updates/armhfp/ --cost=100
repo --name="inst-extras"        --baseurl=http://mirror.centos.org/altarch/7/extras/armhfp/  --cost=100
repo --name="inst-centos-kernel" --baseurl=http://mirror.centos.org/altarch/7/kernel/armhfp/kernel-generic/  --cost=100
repo --name="inst-markvnl"       --baseurl=http://vps01.havak.nl/centos/7/devel/armhfp/       --cost=100

# Package setup
%packages
@core
kernel-lpae
grub2-efi
grubby
dracut-config-generic
-dracut-config-rescue
chrony
net-tools
cloud-utils-growpart
%end

# Disk setup
clearpart --all --initlabel
part /boot/efi --fstype=vfat --size=256  --label=efi    --asprimary --ondisk img
part /         --fstype=ext4 --size=3072 --label=rootfs --asprimary --ondisk img

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


#
# Create grub.cfg
# 
%post --nochroot
/usr/bin/mount --bind /dev $INSTALL_ROOT/dev
/usr/sbin/chroot $INSTALL_ROOT /bin/bash -c \
"/usr/sbin/grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg"
/usr/bin/umount $INSTALL_ROOT/dev
%end
