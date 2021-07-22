# Kickstart to build image for Raspberry Pi 4 

# General setup:
keyboard us --xlayouts=us --vckeymap=us
rootpw fedora
selinux --enforcing
firewall --enabled --port=22:tcp
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=sshd,NetworkManager,chronyd,zram-swap
shutdown
bootloader --location=none
lang en_US.UTF-8

# Disk setup:
clearpart --initlabel --all
part /boot --asprimary --fstype=vfat --size=1024 --label=boot
part / --asprimary --fstype=ext4 --size=3072 --label=rootfs

# Repo setup:
repo --name="fedora"    --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name="updates"   --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
# rpi-kernel
repo --name="rpi-kernel" --baseurl=https://vps01.havak.nl/fedora/$releasever/devel/$basearch

# Package selection:
%packages
@core
chrony
cloud-utils-growpart
NetworkManager-wifi
bash-completion
nano
zram
raspberrypi2-kernel4
raspberrypi2-firmware
%end

# Post install scripts:
%post

# Write initial boot line to cmdline.txt (we will update the root partuuid further down)
cat > /boot/cmdline.txt << EOF
console=ttyAMA0,115200 console=tty1 root= rootfstype=ext4 elevator=deadline rootwait
EOF

# FIXME: raspberrypi2-kernel(4) defaults to conservative governory.
cat > /etc/systemd/system/cpu_governor.service << EOF
# raspberrypi2-kernel(4) defaults to conservative governory.

[Unit]
Description=Set cpu governor to ondemand

[Service]
Type=oneshot
ExecStart=/bin/sh -c " for i in {0..3}; do echo ondemand > /sys/devices/system/cpu/cpu\$i/cpufreq/scaling_governor; done"

[Install]
WantedBy=multi-user.target
EOF

systemctl enable cpu_governor.service

# FIXME: Allow ssh RootLogin in the development-stage
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


# Write README :
cat >/root/README << EOF
== Fedora Raspberry Pi Image  ==

A unofficial image running Fedora with a specific kernel for the Raspberry Pi
NOTE: this image boots the Raspberry OS way: no bootloader, no initramfs

EOF


# Cleanup before shipping an image

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Clean yum cache
yum clean all

%end

# Add the PARTUUID of the rootfs partition to the kernel command line
%post --nochroot
# Extract the UUID of the rootfs partition from /etc/fstab
UUID_ROOTFS="$(/bin/cat $INSTALL_ROOT/etc/fstab | \
/bin/awk -F'[ =]' '/\/ / {print $2}')"
# Get the PARTUUID of the rootfs partition
PART_UUID_ROOTFS="$(/sbin/blkid  "$(/sbin/blkid --uuid $UUID_ROOTFS)" | \
/bin/awk '{print $NF}' | /bin/tr -d '"' )"
# Configure the kernel commandline
/bin/sed -i "s/root= /root=${PART_UUID_ROOTFS} /" $INSTALL_ROOT/boot/cmdline.txt
echo "cmdline.txt looks like this, please review:"
/bin/cat $INSTALL_ROOT/boot/cmdline.txt

%end
