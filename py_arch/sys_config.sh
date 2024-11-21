#!/bin/bash

# Author: Victor Monteiro Ribeiro
# Version: 1.0 rc1
# Email: victormribeiro.py@gmail.com

RED='\033[0;31m'
OFF='\033[0m'
GREEN='\033[0;32m'
workdir=$(pwd)

# Prompt the user for confirmation
confirm_action() {
    local prompt="$1"
    local response
    read -p "$prompt (y/n): " response
    [[ "$response" == "y" ]]
}

# Check if a command succeeded, exit otherwise
run_command() {
    local cmd="$1"
    local description="$2"
    echo -e "${GREEN}$description${OFF}"
    eval "$cmd" 2>/dev/null
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}Error: $description failed. Command: $cmd${OFF}"
        confirm_action "Do you want to continue?" || exit $exit_code
    fi
}

# Install packages from a list
install_packages() {
    local package_list="$1"
    if [[ -f "$package_list" ]]; then
        read -ra packages < "$package_list"
        echo -e "${GREEN}Found ${#packages[@]} packages to install: ${packages[*]}${OFF}"

        for package in "${packages[@]}"; do
            if ! pacman -Q "$package" &>/dev/null; then
                echo -e "${GREEN}Installing $package...${OFF}"
                run_command "sudo pacman -S $package --noconfirm" "Installing $package"
            else
                echo -e "${RED}$package is already installed.${OFF}"
            fi
        done
    else
        echo -e "${RED}Package list $package_list not found.${OFF}"
    fi
}

install_yay() {
    if pacman -Qs yay > /dev/null; then
        echo -e "${GREEN}YAY is already installed.${OFF}"
    else
        echo -e "${GREEN}YAY is not installed. Installing...${OFF}"

        # Ensure required dependencies are installed
        run_command "sudo pacman -S --needed git base-devel --noconfirm" "Installing base-devel and git"

        # Check if the 'yay' folder already exists
        if [[ -d "yay" ]]; then
            echo -e "${RED}Directory 'yay' already exists in $(pwd). Removing it to proceed.${OFF}"
            run_command "rm -rf yay" "Removing existing 'yay' directory"
        fi

        # Clone and build YAY
        run_command "git clone https://aur.archlinux.org/yay.git" "Cloning yay repository"
        run_command "cd yay && makepkg -si --noconfirm" "Building and installing yay"
    fi
}

main(){
    echo -e "${GREEN}Starting system setup...${OFF}"

    # Prompt the user for the username
    read -p "Please enter your username: " USERNAME
    read -p "Please enter your terminal: " TERM

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

    # Disable sudo password for USERNAME
    run_command "echo \"$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL\" | sudo tee -a /etc/sudoers > /dev/null" "${GREEN}Disabling SUDO password...${OFF}"
    # Update system
    confirm_action "Do you want to update the system?" && run_command "sudo pacman -Syu --noconfirm" "System update"


    # Install packages from packages.txt
    #install_packages "$workdir/packages.txt"
    echo -e "\nAll packages have been installed!\n"

    echo -e "\nInstalling YAY...\n"
    sleep 1
    # Install YAY if not installed
    install_yay

    # NOT DONE!!! MIGHT NEED PROPER YAY SETUP BEFORE RUNNING
    read -p "Would you like to install the AUR packages? (y/n) " confirm_action
    if [[ $confirm_action == "y" ]]; then
        mapfile -t packages < <(tr ' ' '\n' < "$workdir/aur_packages.txt")
        echo "${#packages[@]} packages found: ${packages[*]}."

        for package in "${packages[@]}"; do
            if ! pacman -Qi "$package" &>/dev/null; then
                echo -e "\nInstalling $package...\n"
                run_command "yay -S $package --noconfirm" "Installing $package"
            else
                echo -e "\n${RED}$package already installed!\n${OFF}"
            fi
        done
    fi

    echo -e "\n${RED}CHANGING DIRECTORY PERMISSIONS FOR HOME & ETC/default & ETC/modprobe.d & ETC/pacman.d${OFF}"
    
    folders=("/home" "etc/default/grub" "etc/modprobe.d" "etc/pacman.d/mirrorlist" "etc/systemd/system/getty@tty1.service.d/")
		
    for folder in "${folders[@]}"; do
    	sudo chmod -R u+rwx "$folder"
    done
    
    echo -e "\nImporting config files...\n"
    sleep 1
    # Copy assets from repository to system
    for dir in "/etc" "/home"; do
        assets="$workdir/assets$dir"
        sudo rsync -av --progress "$assets/" "$dir/"
    done
    echo -e "\nConfig files imported!\n"

    echo -e "\nRunning bash commands...\n"
    # Define the autologin configuration string before declaring bashlist
    AUTLOGIN_CONF="[Service]
    ExecStart=
    ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin username %I $TERM"

    # Declare the bashlist
    declare -A bashlist=(
        ["enable_getty"]="sudo systemctl enable getty@tty1"
        ["mkdir_autologin"]="sudo mkdir -p /etc/systemd/system/getty@tty1.service.d"
        ["create_autologin_conf"]="sudo echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \"-p -f -- \\\\u\" --noclear --autologin \$USERNAME %I \$TERM' > /etc/systemd/system/getty@tty1.service.d/autologin.conf"
        ["daemon_reload"]="sudo systemctl daemon-reload"
        ["os_prober"]="sudo os-prober"
        ["vscode_auth_extensions"]="sudo chown -R $USER:$USER /opt/visual-studio-code/"
        ["update_initramfs"]="sudo mkinitcpio -p linux-zen"
        ["update_grub"]="sudo grub-mkconfig -o /boot/grub/grub.cfg"
    )

    order=(
        "enable_getty"
        "mkdir_autologin"
        "create_autologin_conf"
        "daemon_reload"
        "os_prober"
        "update_initramfs"
        "update_grub"
        "vscode_auth_extensions"
    )

    read -p "Would you like to run the BASH commands? (y/n) " confirm_action
    if [[ $confirm_action == "y" ]]; then
        for command in "${order[@]}"; do
            echo -e "\nExecuting ${bashlist[$command]}...\n"
            sleep 1
            if [[ $command == "vscode_auth_extensions" && $(pacman -Qs 'code' > /dev/null; echo $?) -eq 0 ]]; then
                echo "VSCode not installed. Skipping dir auth for extensions..."
                continue
            fi
            output=run_command ${bashlist[$command]}
            if [[ $command == "os_prober" && -z "$output" ]]; then
                echo -e "${RED}\nNo other OS detected!\n${OFF}"
                continue
            fi

            run_command "${bashlist[$command]}"
        done
    elif [[ $confirm_action == "n" ]]; then
        echo -e "\nBASH commands skipped..."
    fi


    # Make the script executable
    run_command "sudo chmod +x /home/$USERNAME/.config/waybar/scripts/nvtop_output.sh"
    
    for folder in "${folders[@]}"; do
    	if [ $folder != "/home" ]; then 
    	    sudo chmod -R -w+x "$folder"
    	fi
    done
    
    # Final message before reboot
    echo -e "${GREEN}\nAll done! Do you want to reboot?(y/n)\n${OFF}"
    read -p "" reboot
    if [[ $reboot == "y" ]]; then
        echo -e "\nRebooting in... "
        for i in {5..1}; do
            echo -e " $i..."
            sleep 1
        done

        run_command "reboot"
    else
        exit 1
    fi
}

main "$@"
