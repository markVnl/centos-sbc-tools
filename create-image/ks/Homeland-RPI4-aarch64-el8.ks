# Basic setup information
url --url="/http://mirror.centos.org/centos/8/BaseOS/aarch64/os/"
install
keyboard us --xlayouts=us --vckeymap=us
lang en_US.UTF-8
rootpw centos
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --enabled --port=22
network --bootproto=dhcp --device=eth0 --activate --onboot=on
services --enabled=sshd,NetworkManager,chronyd,zram-swap
shutdown
bootloader --location=mbr

# Repositories to use
repo --name="instBaseOS"  --baseurl=http://mirror.centos.org/centos/8/BaseOS/aarch64/os/ --cost=100
repo --name="instAppStream" --baseurl=http://mirror.centos.org/centos/8/AppStream/aarch64/os/ --cost=100
# Copr repo for Raspberry_PI4 owned by markvnl conaining the kernel, zram and aarch64-img-extra-config
repo --name="coprRPI4" --baseurl=https://download.copr.fedorainfracloud.org/results/markvnl/Raspberry_PI4/epel-8-$basearch/ --cost=100

# Package setup
%packages
@core
NetworkManager-wifi
net-tools
chrony
cloud-utils-growpart
nano
raspberrypi2-kernel4
raspberrypi2-firmware
zram
aarch64-img-extra-config
-tuned
which
-dracut-config-rescue
-kernel-tools
-iwl*
%end

# Disk setup
clearpart --initlabel --all
part /boot  --fstype=vfat --size=768  --label=boot   --asprimary --ondisk=img
part /      --fstype=ext4 --size=2560 --label=rootfs --asprimary --ondisk=img


%pre
# nothing to do
%end


%post 

# Specific cmdline.txt files needed for raspberrypi
cat > /boot/cmdline.txt << EOF
console=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
EOF

# Mandatory README file
cat >/root/README << EOF
== Homeland el8 ==

If you want to automatically resize your / partition, just type the following (as root user):
rootfs-expand
EOF

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Cleanup yum cache
yum clean all


# add (default disabled) Copr repo for epel-7-aarch64_SBC-tools owned by markvnl
cat > /etc/yum.repos.d/Copr_Raspberry_PI4.repo << EOF
# full name useful if yum-copr plugin is installed
# [copr:copr.fedorainfracloud.org:markvnl:Raspberry_PI4]
# human readable name
[copr_kernel]
name=Copr repo for Raspberry_PI4 owned by markvnl
baseurl=https://download.copr.fedorainfracloud.org/results/markvnl/Raspberry_PI4/epel-8-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/markvnl/Raspberry_PI4/pubkey.gpg
repo_gpgcheck=0
enabled=0
enabled_metadata=1
EOF


%include ks/RPI-wifi.ks


%end
