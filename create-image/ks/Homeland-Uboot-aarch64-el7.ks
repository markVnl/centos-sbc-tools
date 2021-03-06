# Basic setup information
url --url="http://mirror.centos.org/altarch/7/os/aarch64/"
install
keyboard us --xlayouts=us --vckeymap=us
lang en_US.UTF-8
rootpw centos
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --enabled --port=22
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=sshd,NetworkManager,chronyd,zram-swap
skipx
shutdown
bootloader --location=none

# Repositories to use
repo --name="base"    --baseurl=http://mirror.centos.org/altarch/7/os/aarch64/      --cost=100
repo --name="updates" --baseurl=http://mirror.centos.org/altarch/7/updates/aarch64/ --cost=100
repo --name="extras"  --baseurl=http://mirror.centos.org/altarch/7/extras/aarch64/  --cost=100
# Copr repo for epel-7-aarch64_SBC-tools owned by markvnl,
# this repo includes the kernel, uboot-images, aarch64-img-extra-config and zram
repo --name="sbc-tools"   --baseurl=https://copr-be.cloud.fedoraproject.org/results/markvnl/epel-7-aarch64_SBC-tools/epel-7-$basearch/ --cost=100

# Package setup
%packages
@core
NetworkManager-wifi
aarch64-img-extra-config
bcm283x-firmware
chrony
cloud-utils-growpart
dracut-config-generic
grub2-efi
grubby
kernel
nano
net-tools
shim
uboot-images-armv8
uboot-tools
wget
zram
-dracut-config-rescue
-ivtv*
-iwl*
-plymouth*
%end

# Disk setup
clearpart --initlabel --all 
part /boot/efi --fstype=vfat --size=256  --label=efi    --asprimary --ondisk img
part /boot     --fstype=ext4 --size=768  --label=boot   --asprimary --ondisk img
part /         --fstype=ext4 --size=2560 --label=rootfs --asprimary --ondisk img

%pre
#End of Pre script for partitions
%end


%post

## FIXME: workarounds for aarch64 {uboot,efi}-boot
echo "Setting up workarounds for aarch64 uboot-uefi..."
#
# Package aarch64-img-extra-config carries helper scripts/configs:
# - in /etc/kernel/{posttrans prerm} to let grubby update dtb-link in /boot
# - configuration in /etc/sysconfig/kernel  
# - rootfs-expand script

#
# The boot flag for 1st (fat32) efi-partion is set afterwards
#

# (re)configure GRUB2, does not work (yet), 
# mounted the image on a loop device:
#   mount ${loopdev}p3 ${mountpoint}
#   mount ${loopdev}p2 ${mountpoint}/boot
#   mount ${loopdev}p1 ${mountpoint}/boot/efi
#   mount --bind /proc ${mountpoint}/proc
#   mount --bind /dev  ${mountpoint}/dev
#   mount --bind /sys  ${mountpoint}/sys
#
# and ran:
#   chroot ${mountpoint} /bin/bash -c "/usr/sbin/grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg"
#

# time-out takes much longer on RPI's
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=2
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX=""
EOF


# fix for prestine (upstream) u-boot
mv /boot/efi/EFI/BOOT/BOOTAA64.EFI /boot/efi/EFI/BOOT/BOOTAA64.org
cp -P /boot/efi/EFI/centos/grubaa64.efi /boot/efi/EFI/BOOT/BOOTAA64.EFI 

# add (default disabled) Copr repo for epel-7-aarch64_SBC-tools owned by markvnl
cat > /etc/yum.repos.d/Copr_aarch64_SBC-tools.repo << EOF
# full name useful if yum-copr plugin is installed
# [copr:copr.fedorainfracloud.org:markvnl:epel-7-aarch64_SBC-tools]
# human readable name
[aarch64-sbc-tools]
name=Copr repo for epel-7-aarch64_SBC-tools owned by markvnl
baseurl=https://copr-be.cloud.fedoraproject.org/results/markvnl/epel-7-aarch64_SBC-tools/epel-7-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/markvnl/epel-7-aarch64_SBC-tools/pubkey.gpg
repo_gpgcheck=0
enabled=0
enabled_metadata=1

EOF


## FIXME: end

echo "copy Raspberry PI3s firmware und Das Uboot..."
# firmware RPI 3(+)
echo "enter directory:"
pushd /usr/share/bcm283x-firmware/
cp -r -p overlays /boot/efi/. 
cp -p bcm2710-rpi-3-b.dtb bcm2710-rpi-3-b-plus.dtb bootcode.bin config.txt /boot/efi/.
cp -p fixup_cd.dat fixup.dat fixup_db.dat fixup_x.dat /boot/efi/.
cp -p start_cd.elf start_db.elf start.elf start_x.elf /boot/efi/.
echo "leave directory"
popd

# Uboot RPI 3(+)
cp -P /usr/share/uboot/rpi_3/u-boot.bin /boot/efi/rpi3-u-boot.bin

echo "Write README file..."
cat >/root/README << EOF
== Homeland el7 development AARCH64 image ==

Note: this is a community effort not supported by centOS by any means
      it's just an "academic proof of concepts" 
      
      Please check /root/anaconda-ks.cfg on how this image came to life

      nevertheless : have fun and debug!  


(as usual) If you want to automatically resize your / partition to use the full sd-card, 
just type the following:

rootfs-expand

EOF


# Enable heartbeat LED
echo "ledtrig-heartbeat" > /etc/modules-load.d/sbc.conf

echo "Disabeling and Masking kdump.service..."
systemctl mask kdump.service

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Cleanup yum cache
yum clean all


%include ks/RPI-wifi.ks


%end
