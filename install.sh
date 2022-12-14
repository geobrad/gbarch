#!/bin/sh

ESP_UUID=<UUID of EFI system partition>
FS_UUID=<UUID of file system partition>
SWAP_UUID=<UUID of swap partition>


######################################
# Script to install and configure Arch Linux - WORK IN PROGRESS
#
# To run directly from (e.g.) GitHub with arguments:
# # curl -s http://github.com/gbradley/archinst/script.sh | bash -s args
#
######################################

# Prerequisites
# - Linux (type 8300) partition on which Arch will be installed
# - EFI partition

#######################################
# Run from the Arch installation medium:

# Format the linux file system (root) partition as ext4
mkfs.ext4 /dev/disk/by-uuid/$FS_UUID
# if installing to a flash device, add option: -O "^has_journal" to reduce disk reads/writes ??
# and change to `bfq` I/O schedule (echo bfq > /sys/block/sdFS/queue/scheduler)

mkswap /dev/disk/by-uuid/$SWAP_UUID

# Mount the root and EFI partitions
mount /dev/disk/by-uuid/$FS_UUID /mnt
mkdir /mnt/boot
mount /dev/disk/by-uuid/$ESP_UUID /mnt/root

# Install base packages, kernel and firmware
pacstrap /mnt base linux-lts linux-firmware vi dhcpcd intel-ucode nvidia-lts alsa-firmware sof-firmware alsa-plugins

# Set up fstab to mount the partitions (identified by UUID) on startup
genfstab -U /mnt >> /mnt/etc/fstab

# chroot into the new installation
arch-chroot /mnt

# Set time zone to Australia/Melbourne and generate /etc/adjtime
ln -sf /usr/share/zoneinfo/Australia/Melbourne
hwclock -systohc

#******** Edit /etc/locale.gen and uncomment: ********
# en_AU.UTF-8 UTF-8

#Generate locales
locale-gen

# Set the LANG variable
echo "LANG=en_AU.UTF-8" > /etc/locale.conf

# Set the hostname
echo "gbarch" > /etc/hostname

# Create and activate swap file
swapon /dev/disks/by-uuid/$SWAP_UUID
echo "UUID=$SWAP_UUID none swap defaults 0 0" >> /etc/fstab

systemctl enable dhcpcd

# To enable hybernate/resume
#*** Append "resume" to HOOKS= in /etc/mkinitcpio.conf
#Add resume=UUID=<UUID of swap partition> to the kernel parameters (in the boot loader)

# # IF the installation is on a removable medium:

#   # Install a generic set of video drivers
#   pacman -S xf86-video-vesa xf86-video-ati xf86-video-intel xf86-video-amdgpu xf86-video-nouveau xf86-video-fbdev

#   # Install support for Broadcom wireless on MacBook Air 2017
#   pacman-S broadcom-wl

#   #********* Edit /etc/mkinitcpio.conf "HOOKS=": "block" and "keyboard" before "autodetect"

#   # (Re)generate the initramfs image
#   mkinitcpio -P

#   #********* If installing to a flash device, configure systemd journal to store in RAM.

# # ENDIF


# Set root password
echo "Setting the root password . . ."
passwd

#********* Install or configure boot loader including microcode *********
# If installing onto a removable medium, use the fallback image for greater compatibility.


#*** Uncomment "#ParallelDownloads = 5" and "#Color" in /etc/pacman.conf



# File system support
pacman -S ntfs-3g


# Add `george` user and give sudo rights without password
groupadd wheel # also used by KDE Plasma to determine who is an "Administrator"
useradd -m -G wheel george
passwd george
pacman -S sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers


#### REBOOT?


# # For MacBook Air microphone jack (https://askubuntu.com/questions/984239/no-microphone-picked-up-on-ubuntu-16-04-on-macbook-pro)
# echo "options snd-hda-intel model=mba6" > /etc/modprobe.d/alsa-base.conf



#### Desktop - KDE Plasma
pacman -S plasma-meta
pacman -S pulseaudio-bluetooth  # Bluetooth audio support
systemctl enable bluetooth
systemctl enable NetworkManager

#### Network service discovery and printing
pacman -S nss-mdns cups print-manager
#**** Modify /etc/nsswitch.conf as per ArchWiki Avahi instructions
systemctl enable avahi-daemon  # network service discovery
systemctl enable cups


#### Apps
pacman -S dolphin kwrite ark okular firefox konsole ktorrent code pyenv inkscape gimp vlc openssh gparted kio-gdrive

pacman -S git
git config --global user.email "george.bradley@gmail.com"
git config --global user.name "George Bradley"

pacman -S docker docker-compose
usermod -aG docker george
systemctl enable docker


# Install base-devel group and yay
pacman -S base-devel  # Needed in order to build yay
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
tar -xf yay.tar.gz
cd yay
chmod a+w .  # Enable user running makepkg to write files
runuser -u george -- makepkg -risc
cd ..
rm -r yay
rm yay.tar.gz


# Replace base-devel group with base-devel-meta package
yay -S base-devel-meta
pacman -Qqegt base-devel | pacman -Rs -  # Remove base-devel packages that are not required (by base-devel-meta)
pacman -Qqeg base-devel | sudo pacman -D --asdeps -  # Mark remaining base-devel packages as dependencies

#***** Install printer driver for Canon PIXMA TS9160 from AUR *****
yay -S cnijfilter2 scangearmp2

yay -S nvm
#***** Add the following to /home/george/.bashrc (without the leading #'s)
# # Set up Node Version Manager
# source /usr/share/nvm/init-nvm.sh


yay -S teams

#yay -S fingerprint-gui howdy
# TODO: configure fingerprint reader and facial recognition

# # Install driver for Macbook Air webcam
# pacman -S linux-headers  # required to build bcwc-pcie-git
# #***** Install from AUR: facetimehd-firmware bcwc-pcie-git



systemctl enable sddm

# TODO: Install and configure smartmontools to monitor hard disk health

# TODO: Set up graphics cards for best performance and/or energy efficiency


