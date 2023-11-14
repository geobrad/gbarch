#### REBOOT?

set -e  # Exit on failure

echo 'Connecting to WiFi'
systemctl start NetworkManager
nmcli device wifi connect GBWiFi


echo 'Installing fonts'
pacman -S ttf-liberation ttf-droid


# File system support
pacman -S ntfs-3g



# # For MacBook Air microphone jack (https://askubuntu.com/questions/984239/no-microphone-picked-up-on-ubuntu-16-04-on-macbook-pro)
# echo "options snd-hda-intel model=mba6" > /etc/modprobe.d/alsa-base.conf



#### Desktop - KDE Plasma
pacman -S plasma-meta plasma-wayland-session kde-system-meta kde-utilities-meta kde-network-meta
# pacman -S pulseaudio-bluetooth  # Bluetooth audio support
# systemctl enable bluetooth
# systemctl enable NetworkManager

#### Network service discovery and printing
# pacman -S nss-mdns cups print-manager
#**** Modify /etc/nsswitch.conf as per ArchWiki Avahi instructions
# systemctl enable avahi-daemon  # network service discovery
# systemctl enable cups


echo 'Installing KDE applications'
# pacman -S dolphin kwrite ark okular konsole ktorrent kio-gdrive

echo 'Installing other applications'
pacman -S opera inkscape gimp vlc openssh gparted 

echo 'Installing git'
pacman -S git
git config --global user.email "george.bradley@gmail.com"
git config --global user.name "George Bradley"

echo 'Installing docker and docker-compose'
pacman -S docker docker-compose
usermod -aG docker george
systemctl enable docker


echo 'Installing build tools and the paru AUR helper'
pacman -S base-devel  # Needed in order to build yay
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/paru-bin.tar.gz
tar -xf paru-bin.tar.gz
cd paru-bin
chmod a+w .  # Enable user running makepkg to write files
runuser -u george -- makepkg -risc
cd ..
rm -r paru-bin
rm paru-bin.tar.gz


echo 'Installing drivers for Canon PIXMA TS9160'
paru -S cnijfilter2 scangearmp2

echo 'Installing Node Version Manager'
paru -S nvm
echo '# Set up Node Version Manager' >> /home/george/.bashrc
echo 'source /usr/share/nvm/init-nvm.sh' >> /home/george/.bashrc

echo 'Installing VS Code'
paru -S virtual-studio-code-bin
# yay -S teams

#yay -S fingerprint-gui howdy
# TODO: configure fingerprint reader and facial recognition

# # Install driver for Macbook Air webcam
# pacman -S linux-headers  # required to build bcwc-pcie-git
# #***** Install from AUR: facetimehd-firmware bcwc-pcie-git


echo 'Enabling the desktop manager'
systemctl enable sddm

# TODO: Solid state drives - https://wiki.archlinux.org/title/Solid_state_drive

# TODO: Set up graphics cards for best performance and/or energy efficiency

# TODO: Security - https://wiki.archlinux.org/title/Security

# systemd-cryptenroll --recovery-key /dev/sdX
systemd-cryptenroll --wipe-slot=empty --tpm2-device=auto /dev/sdX
