# Basic setup information
url --url="http://mirror.centos.org/altarch/7/os/armhfp/"
install
keyboard us --xlayouts=us --vckeymap=us
lang en_US.UTF-8
rootpw centos
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --enabled --port=22
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=sshd,NetworkManager,chronyd,zram-swap
shutdown
bootloader --location=mbr


# Repositories to use
repo --name="instCentOS"  --baseurl=http://mirror.centos.org/altarch/7/os/armhfp/ --cost=100
repo --name="instUpdates" --baseurl=http://mirror.centos.org/altarch/7/updates/armhfp/ --cost=100
repo --name="instExtras"  --baseurl=http://mirror.centos.org/altarch/7/extras/armhfp/ --cost=100
repo --name="instKern"    --baseurl=http://mirror.centos.org/altarch/7/kernel/armhfp/kernel-rpi2/ --cost=100
# Copr repo for epel-7-aarch64_SBC-tools owned by markvnl for zram.
# zram is a noarch package living in an aarch64-repo (copr does not have an armhfp build target)
repo --name="sbc-tools" --baseurl=https://copr-be.cloud.fedoraproject.org/results/markvnl/epel-7-aarch64_SBC-tools/epel-7-aarch64/ --cost=100

# Package setup
%packages
@core
net-tools
cloud-utils-growpart
chrony
uboot-images-armv7
raspberrypi2-kernel
#raspberrypi2-kernel-firmware
raspberrypi2-firmware
raspberrypi-vc-utils
zram
%end

# Disk setup
clearpart --initlabel --all
part /boot  --fstype=vfat --size=768  --label=boot   --asprimary --ondisk=img
part /      --fstype=ext4 --size=2560 --label=rootfs --asprimary --ondisk=img

%pre
#End of Pre script for partitions
%end


%post 
# Generating initrd
export kvr=$(rpm -q --queryformat '%{version}-%{release}' $(rpm -q raspberrypi2-kernel|tail -n 1))
dracut --force /boot/initramfs-$kvr.armv7hl.img $kvr.armv7hl


# Mandatory README file
cat >/root/README << EOF
== Homeland el7 ==

If you want to automatically resize your / partition, just type the following (as root user):
rootfs-expand

EOF



# Specific cmdline.txt files needed for raspberrypi2/3
cat > /boot/cmdline.txt << EOF
console=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
EOF

# Setting correct yum variable to use raspberrypi kernel repo
echo "rpi2" > /etc/yum/vars/kvariant

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Cleanup yum cache
yum clean all


%include ks/RPI-wifi.ks


%end
