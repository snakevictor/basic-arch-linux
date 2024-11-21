#!/bin/bash

# Author: Victor Monteiro Ribeiro
# Version: 1.0 rc1
# Email: victormribeiro.py@gmail.com

RED='\033[0;31m'
OFF='\033[0m'
GREEN='\033[0;32m'

workdir=$(pwd)

check_exit() {
    read -p "Should the process be aborted? (y/n) " check_exit
    if [[ $check_exit == "y" ]]; then
        exit 1
    fi
}

run_bash() {
    output=$(eval "$1" 2>&1)
    exit_code=$?
    echo "$output"

    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}\nAn error occurred with command: $1${OFF}"
        check_exit
    fi
}

# Prompt the user for the username
read -p "Please enter your username: " USERNAME

# Ensure the username is not empty
if [[ -z "$USERNAME" ]]; then
    echo -e "${RED}Error: Username cannot be empty.${OFF}"
    exit 1
fi

# Check if etc and home directories were downloaded
if [[ ! -d "$workdir/assets/etc" || ! -d "$workdir/assets/home" ]]; then
    echo -e "${RED}'/etc'or '/home' were not correctly imported, check downloaded files and try again${OFF}"
    exit 1
fi
echo -e "\n/etc and /home verified...\n"
sleep 1

# Check if system's etc and home directories exist
if [[ ! -d "/etc" || ! -d "/home" ]]; then
    echo -e "${RED}\nSystem's '/etc' or '/home' were not found, check installation\n${OFF}"
    exit 1
fi
echo -e "\nSystem's /etc and /home verified...\n"
sleep 1

echo -e "\nDisabling sudo password...\n"
sleep 1
# Disable sudo password for USERNAME
run_bash "echo \"$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL\" | sudo tee -a /etc/sudoers > /dev/null"


# Update system
echo -e "\nUpdating system...\n"
sleep 1
run_bash "sudo pacman -Syu --noconfirm"
echo -e "\nSystem updated!\n"


# Install packages from packages.txt
if [[ -f "$workdir/packages.txt" ]]; then
    mapfile -t packages < <(tr ' ' '\n' < "$workdir/packages.txt")
    echo -e "${#packages[@]} packages found: ${packages[*]}."

    for package in "${packages[@]}"; do
        if ! pacman -Qs $package > /dev/null; then
            echo -e "\nInstalling $package...\n"
            sleep 1
            run_bash "sudo pacman -S $package --noconfirm"
        else
            echo -e "\n${RED}$package already installed!\n${OFF}"
        fi
    done
else
    echo -e "${RED}packages.txt not found!${OFF}"
    check_exit
fi

echo -e "\nAll packages have been installed!\n"

# Git repositories to clone and install

echo -e "\nInstalling YAY...\n"
sleep 1

if ! pacman -Qs 'yay' > /dev/null; then
    run_bash "sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
else
    echo -e "${RED}\nYAY already installed...\n${OFF}"
fi

# NOT DONE!!! MIGHT NEED PROPER YAY SETUP BEFORE RUNNING
read -p "Would you like to install the AUR packages? (y/n) " check_exit
if [[ $check_exit == "y" ]]; then
    mapfile -t packages < <(tr ' ' '\n' < "$workdir/aur_packages.txt")
    echo "${#packages[@]} packages found: ${packages[*]}."

    for package in "${packages[@]}"; do
        if which $package &>/dev/null; then
            echo -e "\nInstalling $package...\n"
            run_bash "yay -S $package --noconfirm"
        else
            echo -e "\n${RED}$package already installed!\n${OFF}"
        fi
    done
fi

echo -e "\nRunning bash commands...\n"
# Define the autologin configuration string before declaring bashlist
AUTLOGIN_CONF="[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin username %I $TERM"

# Declare the bashlist
declare -A bashlist=(
    ["mkdir_autologin"]="sudo mkdir -p /etc/systemd/system/getty@tty1.service.d"
    ["create_autologin_conf"]="echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \"-p -f -- \\\\u\" --noclear --autologin \$USERNAME %I \$TERM' > /etc/systemd/system/getty@tty1.service.d/autologin.conf"
    ["daemon_reload"]="sudo systemctl daemon-reload"
    ["os_prober"]="sudo os-prober"
    ["vscode_auth_extensions"]="sudo chown -R $USER:$USER /opt/visual-studio-code/"
    ["update_initramfs"]="sudo mkinitcpio -p linux-zen"
    ["update_grub"]="sudo grub-mkconfig -o /boot/grub/grub.cfg"
)

read -p "Would you like to run the BASH commands? (y/n) " check_exit
if [[ $check_exit == "y" ]]; then
    for command in "${!bashlist[@]}"; do
        echo -e "\nExecuting ${bashlist[$command]}...\n"
        sleep 1
        if [[ $command == "vscode_auth_extensions" && $(pacman -Qs 'code' > /dev/null; echo $?) -eq 0 ]]; then
            echo "VSCode not installed. Skipping dir auth for extensions..."
            continue
        fi
        output=run_bash ${bashlist[$command]}
        if [[ $command == "os_prober" && -z "$output" ]]; then
            echo -e "${RED}\nNo other OS detected!\n${OFF}"
            continue
        fi

        run_bash "${bashlist[$command]}"
    done
elif [[ $check_exit == "n" ]]; then
    echo -e "\nBASH commands skipped..."
fi

echo -e "\nImporting config files...\n"
sleep 1
# Copy assets from repository to system
for dir in "/etc" "/home"; do
    assets="$workdir/assets$dir"
    sudo cp -r "$assets" "$dir"
done

echo -e "\nConfig files imported!\n"

# Make the script executable
run_bash "sudo chmod +x /home/$USERNAME/.config/waybar/scripts/nvtop_output.sh"

# Final message before reboot
echo -e "${GREEN}\nAll done! Do you want to reboot?(y/n)\n${OFF}"
read -p "" reboot
if [[ $reboot == "y" ]]; then
    echo -e "\nRebooting in... "
    for i in {5..1}; do
        echo -e " $i..."
        sleep 1
    done

    run_bash "reboot"
else
    exit 1
fi
