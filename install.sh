#!/bin/sh

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
mkfs.ext4 /dev/sdFS 
# if installing to a flash device, add option: -O "^has_journal" to reduce disk reads/writes ??
# and change to `bfq` I/O schedule (echo bfq > /sys/block/sdFS/queue/scheduler)

# Mount the root and EFI partitions
mount /dev/sdFS /mnt
mkdir /mnt/boot
mount /dev/sdEFI /mnt/root

# Install base packages, kernel and firmware
pacstrap /mnt base linux linux-firmware

# Set up fstab to mount the partitions (identified by UUID) on startup
genfstab -U /mnt >> /mnt/etc/fstab

# chroot into the new installation
arch-chroot /mnt

# Set time zone to Australia/Melbourne and generate /etc/adjtime
ln -sf /usr/share/zoneinfo/Australia/Melbourne
hwclock -systohc

#******** Edit /etc/locale.gen and uncomment: ********
# en_US.UTF-8 UTF-8
# en_AU.UTF-8 UTF-8

#Generate locales
locale-gen

# Set the LANG variable
echo "LANG=en_AU.UTF-8" > /etc/locale.conf

# Set the hostname
echo "gbarch" > /etc/hostname

# Create and activate swap file
$SWAP_UUID=fafd318b-12de-45be-bb1b-c7266cb927a5
swapon /dev/disks/by-uuid/$SWAP_UUID
echo "UUID=$SWAP_UUID none swap defaults 0 0" >> /etc/fstab

# To enable hybernate/resume
#*** Append "resume" to HOOKS= in /etc/mkinitcpio.conf
#Add resume=PARTUUID=.... and resume_offset=.... to the kernel parameters to be provided by the boot loader

# IF the installation is on a removable medium:

  # Install a generic set of video drivers
  pacman -S xf86-video-vesa xf86-video-ati xf86-video-intel xf86-video-amdgpu xf86-video-nouveau xf86-video-fbdev

  # Install support for Broadcom wireless on MacBook Air 2017
  pacman-S broadcom-wl

  #********* Edit /etc/mkinitcpio.conf "HOOKS=": "block" and "keyboard" before "autodetect"

  # (Re)generate the initramfs image
  mkinitcpio -P

  #********* If installing to a flash device, configure systemd journal to store in RAM.

# ENDIF


# Set root password
echo "Setting the root password . . ."
passwd

#********* Install or configure boot loader including microcode *********
# If installing onto a removable medium, use the fallback image for greater compatibility.


#*** Uncomment "#ParallelDownloads = 5" in /etc/pacman.conf

# WiFi
pacman -S networkmanager  # also a dependency of plasma-nm
pacman -S --asdeps dhcpcd  # optional dependency of networkmanager
systemctl enable dhcpcd
systemctl enable NetworkManager


# File system support
pacman -S ntfs-3g


# Add `george` user and give sudo rights without password
groupadd wheel # also used by KDE Plasma to determine who is an "Administrator"
useradd -m -G wheel george
passwd george
pacman -S sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers


#### REBOOT?


# For MacBook Air microphone jack (https://askubuntu.com/questions/984239/no-microphone-picked-up-on-ubuntu-16-04-on-macbook-pro)
echo "options snd-hda-intel model=mba6" > /etc/modprobe.d/alsa-base.conf



#### Desktop - KDE Plasma
pacman -S plasma-desktop
pacman -S kdeplasma-addons
pacman -S plasma-nm  # network management
pacman -S plasma-pa  # audio management
pacman -S powerdevil  # power management
pacman -S kscreen  # multi-screen layout management
pacman -S bluedevil pulseaudio-bluetooth  # Bluetooth manager and audio support
systemctl enable bluetooth

#### Network service discovery and printing
pacman -S nss-mdns  # mDNS host name resolution
#**** Modify /etc/nsswitch.conf as per ArchWiki Avahi instructions
systemctl enable avahi-daemon  # network service discovery
pacman -S cups system-config-printer
systemctl enable cups


#### Apps
pacman -S breeze-gtk kde-gtk-config  # Enable the KDE look for GTK applications (e.g. Firefox)
pacman -S dolphin  # File manager
pacman -S kwrite  # Basic text editor
pacman -S ark  # graphical archive manager
pacman -S okular  # document reader
pacman -S firefox plasma-browser-integration  # Web browser
pacman -S konsole  # Terminal emulator
pacman -S ktorrent
pacman -S discover packagekit-qt5  # Applications manager and support for Arch repos
pacman -S code  # VS Code
pacman -S git
pacman -S pyenv
pacman -S inkscape
pacman -S gimp
pacman -S vlc
pacman -S filezilla
pacman -S openssh
pacman -S gparted
pacman -S neovim
pacman -S zip unzip

git config --global user.email "george.bradley@gmail.com"
git config --global user.name "George Bradley"

pacman -S docker docker-compose
usermod -aG docker george
systemctl enable docker


# Install base dependencies for building packages from source (using base-devel-meta from AUR)
pacman -S --asdeps fakeroot  # needed to run makepkg (below)
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/base-devel-meta.tar.gz
tar -xf base-devel-meta.tar.gz
cd base-devel-meta
chmod a+w .  # Enable user running makepkg to write files
runuser -u george -- makepkg -rsc
pacman -U base-devel-meta-*.pkg.tar.zst
cd ..

#***** Install printer driver for Canon PIXMA TS9160 from AUR *****
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/cnijfilter2.tar.gz
tar -xf cnijfilter2.tar.gz
cd cnijfilter2
chmod a+w .  # Enable user running makepkg to write files
runuser -u george -- makepkg -rsc
pacman -U cnijfilter2-*.pkg.tar.zst
cd ..

#***** Install scan driver for Canon PIXMA TS9160 from AUR *****
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/scangearmp2.tar.gz
tar -xf scangearmp2.tar.gz
cd scangearmp2
chmod a+w .  # Enable user running makepkg to write files
runuser -u george -- makepkg -rsc
pacman -U scangearmp2-*.pkg.tar.zst
cd ..


# Install Node Version Manager from AUR
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/nvm.tar.gz
tar -xf nvm.tar.gz
cd nvm
chmod a+w .  # Enable user running makepkg to write files
runuser -u george -- makepkg -rsc
pacman -U nvm-*.pkg.tar.zst
cd ..
#***** Add the following to /home/george/.bashrc (without the leading #'s)
# # Set up Node Version Manager
# source /usr/share/nvm/init-nvm.sh


# Install Microsoft Teams ('teams') from AUR


# Install driver for Macbook Air webcam
pacman -S linux-headers  # required to build bcwc-pcie-git
#***** Install from AUR: facetimehd-firmware bcwc-pcie-git


#### Desktop manager
pacman -S sddm
pacman -S sddm-kcm  # Plasma configuration tool for sddm
systemctl enable sddm


# Google Drive
pacman -S kio-gdrive


# TODO: Install and configure smartmontools to monitor hard disk health



# For ThinkPad P15s

pacman -S alsa-firmware
pacman -S sof-firmware

