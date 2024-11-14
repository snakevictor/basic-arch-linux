#!/bin/bash

# Author: Victor Monteiro Ribeiro
# Version: 0.4
# Email: victormribeiro.py@gmail.com

workdir=$(pwd)

check_exit() {
    read -p "Should the process be aborted? (y/n) " check_exit
    if [[ $check_exit == "y" ]]; then
        exit 1
    fi
}

run_bash() {
    eval "$1"
    if [[ $? -ne 0 ]]; then
        echo -e "\nAn error occurred with command: $1"
        check_exit
    fi
}

# Prompt the user for the username
read -p "Please enter your username: " USERNAME

# Ensure the username is not empty
if [[ -z "$USERNAME" ]]; then
    echo "Error: Username cannot be empty."
    exit 1
fi

# Check if etc and home directories were downloaded
if [[ ! -d "$workdir/assets/etc" || ! -d "$workdir/assets/home" ]]; then
    echo "'/etc'or '/home' were not correctly imported, check downloaded files and try again"
    exit 1
fi
echo "/etc and /home verified..."

# Check if system's etc and home directories exist
if [[ ! -d "/etc" || ! -d "/home" ]]; then
    echo "System's '/etc' or '/home' were not found, check installation"
    exit 1
fi
echo "System's /etc and /home verified..."

echo -e "\nDisabling sudo password...\n"
# Disable sudo password for USERNAME
run_bash "echo \"$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL\" | sudo tee -a /etc/sudoers > /dev/null"

# Update system
echo -e "\nUpdating system...\n"
run_bash "sudo pacman -Syu --noconfirm"
echo -e "\nSystem updated!\n"

# Install packages from packages.txt
if [[ -f "$workdir/packages.txt" ]]; then
    mapfile -t packages < <(tr ' ' '\n' < "$workdir/packages.txt")
    echo "${#packages[@]} packages found: ${packages[*]}."

    for package in "${packages[@]}"; do
        echo -e "\nInstalling $package...\n"
        run_bash "sudo pacman -S $package --noconfirm"
    done
else
    echo "packages.txt not found!"
    exit 1
fi

echo -e "\nInstallation complete!\nBuilding packages from git...\n"

# Git repositories to clone and install
declare -A gitlist=(
    ["rofi"]="git clone --depth=1 https://github.com/adi1090x/rofi.git && cd rofi && chmod +x setup.sh && sudo ./setup.sh"
    ["yay"]="sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
)

for package in "${!gitlist[@]}"; do
    echo -e "\nInstalling $package...\n"
    run_bash "${gitlist[$package]}"
done

# Additional bash commands
declare -A bashlist=(
    ["mkdir_autologin"]="sudo mkdir -p /etc/systemd/system/getty@tty1.service.d"
    ["create_autologin_conf"]='eval echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \"-p -f -- \\u\" --noclear --autologin $USERNAME %I $TERM" | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null'
    ["daemon_reload"]="sudo systemctl daemon-reload"
    ["os_prober"]="os-prober"
    ["update_grub"]="sudo grub-mkconfig -o /boot/grub/grub.cfg"
    ["update_initramfs"]="sudo mkinitcpio -p linux-zen"
)

for command in "${!bashlist[@]}"; do
    echo -e "\nExecuting ${bashlist[$command]}...\n"
    run_bash "${bashlist[$command]}"
    if [[ $command == "os_prober" && -z $(os-prober) ]]; then
        echo "No other OS detected!"
    fi
done

# Copy assets from repository to system
for dir in "/etc" "/home"; do
    assets="$workdir/assets$dir"
    sudo cp -r "$assets" "$dir"
done

echo "Config files imported!"

# Make the script executable
sudo chmod +x /home/$USERNAME/.config/waybar/scripts/nvtop_output.sh

# Final message before reboot
echo -e "\nAll done! Rebooting in...\n"
for i in {5..1}; do
    echo "$i"
    sleep 1
done

sudo shutdown -r now
135
