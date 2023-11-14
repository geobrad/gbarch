#!/bin/bash
######################################
# Script to install and configure Arch Linux - WORK IN PROGRESS
#
# To run directly from (e.g.) GitHub with arguments:
# # curl -s http://github.com/gbradley/archinst/script.sh | bash -s args
#
######################################

# Prerequisites
# - arch-install-scripts package installed
# - Unused partition on which Arch will be installed
# - EFI system partition (ESP)

esp_uuid=52FC-FD2B
root_partuuid=05ace2b0-9b75-40c4-9c9b-82a4aa8b7a76
mapping_name=arch2rootfs
hostname=gbarch
uki_filename=arch2.efi
uki_fallback_filename=arch2-fallback.efi

set -e  # Exit on any command failure

# Set up the root partition based on:
# https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system#Simple_encrypted_root_with_TPM2_and_Secure_Boot

root_partition=/dev/disk/by-partuuid/$root_partuuid

echo 'About to mount into the following partition:'
echo
blkid "$root_partition"
echo
read -p "Press enter to continue . . ."


echo 'Encrypting the root partition'
cryptsetup luksFormat "$root_partition"
# -y : ask for the passphrase twice
# -v : verbose
systemd-cryptenroll "$root_partition" --recovery-key
read -p "SAVE THIS RECOVERY KEY!! Press enter to continue . . ."
systemd-cryptenroll "$root_partition" --wipe-slot=empty

echo 'Opening the encrypted partition'
cryptsetup open "$root_partition" "$mapping_name"

echo 'Creating the root filesystem'
mkfs.ext4 "/dev/mapper/$mapping_name"

echo 'Mounting the root filesystem'
mount "/dev/mapper/$mapping_name" /mnt
mount --mkdir "/dev/disk/by-uuid/$esp_uuid" /mnt/efi


echo 'Installing base packages, kernel, firmware'
pacstrap /mnt base linux linux-firmware networkmanager sudo sbsigntools tpm2-tss


echo 'Configuring mkinitcpio hooks'
sed -i '/^HOOKS=/aHOOKS=(systemd autodetect modconf kms keyboard block sd-encrypt filesystems fsck)' /mnt/etc/mkinitcpio.conf
sed -i '0,/^HOOKS=/s/./#&/' /mnt/etc/mkinitcpio.conf  # Comment out old HOOKS=() line

echo 'Setting locale'
sed -i '/en_AU.UTF-8 UTF-8/s/^#//g' /mnt/etc/locale.gen  # Uncomment: #en_AU.UTF-8 UTF-8
echo "LANG=en_AU.UTF-8" > /mnt/etc/locale.conf
touch /mnt/etc/vconsole.conf

echo 'Setting the hostname'
echo "$hostname" > /mnt/etc/hostname

echo 'Allowing wheel group to sudo'
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //g' /mnt/etc/sudoers

#*** Uncomment "#ParallelDownloads = 5" and "#Color" in /etc/pacman.conf
sed -i '/^#ParallelDownloads/s/^#//g' /mnt/etc/pacman.conf
sed -i '/^#Color/s/^#//g' /mnt/etc/pacman.conf

echo 'Setting up unified kernel image'
# Reference: https://wiki.archlinux.org/title/Unified_kernel_image

# Copy kernel command line configuration files
cp -r ./cmdline.d /mnt/etc
sed -i "/^rd.luks.name=/s/<UUID>/$(blkid -o value -s UUID $root_partition)/g" /mnt/etc/cmdline.d/rootfs.conf

# Modify mkinitcpio presets
sed -i '/_image=/s/^./#&/g' /mnt/etc/mkinitcpio.d/linux.preset
sed -i '/_uki=/s/^#//g' /mnt/etc/mkinitcpio.d/linux.preset
sed -i "/^default_uki=/s/\/arch-linux.efi/\/$uki_filename/g" /mnt/etc/mkinitcpio.d/linux.preset
sed -i '/default_options=/s/^#//g' /mnt/etc/mkinitcpio.d/linux.preset
sed -i "/^fallback_uki=/s/\/arch-linux-fallback.efi/\/$uki_fallback_filename/g" /mnt/etc/mkinitcpio.d/linux.preset

cp ./uki-sign /mnt/etc/initcpio/post/
cp ~/MOK.* /mnt



echo 'Setting time zone'
ln -sf /usr/share/zoneinfo/Australia/Melbourne /mnt/etc/localtime

echo 'Setting time zone to Australia/Melbourne and generating /etc/adjtime'
arch-chroot /mnt hwclock --systohc

echo 'Generating locale(s)'
arch-chroot /mnt locale-gen

echo 'Generating the unified kernel image'
arch-chroot /mnt mkinitcpio -P

echo 'Locking the root password'
arch-chroot /mnt passwd --lock root

echo 'Adding the primary user'
arch-chroot /mnt useradd -m -G wheel george
arch-chroot /mnt passwd george

echo "Done; now boot into $uki_filename"

# # chroot into the new installation
# cp ./local-install.sh /mnt/
# arch-chroot /mnt /local-install.sh


# rm /mnt/local-install.sh

