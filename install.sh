#!/bin/bash

# Arch Linux Auto-Installer for Hyper-V
# Warning: This script will erase all data on the target disk. Use with caution!

set -e

# Set up disk partitions
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart primary fat32 1MiB 261MiB
parted -s /dev/sda set 1 esp on
parted -s /dev/sda mkpart primary ext4 261MiB 100%

# Format partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount partitions
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Install base system
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure system
arch-chroot /mnt /bin/bash <# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "arch-hyper-v" > /etc/hostname

# Set root password
echo "root:password" | chpasswd

# Install and configure bootloader (GRUB)
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install necessary packages
pacman -S --noconfirm networkmanager sudo vim

# Enable NetworkManager
systemctl enable NetworkManager

# Install Hyprland and dependencies
pacman -S --noconfirm hyprland xorg-server xorg-xinit libinput

# Install SDDM (display manager)
pacman -S --noconfirm sddm
systemctl enable sddm

# Create a user
useradd -m -G wheel -s /bin/bash user
echo "user:password" | chpasswd

# Configure sudo
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Exit chroot
EOF

# Unmount partitions
umount -R /mnt

echo "Installation complete. You can now reboot into your new Arch Linux system."
