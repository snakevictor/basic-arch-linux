import os
import shutil
import subprocess
import time


"""
Python script to setup Arch Linux with custom config files and packages
"""

__author__ = "Victor Monteiro Ribeiro"
__version__ = "0.4"
__email__ = "victormribeiro.py@gmail.com"

workdir = os.getcwd()


def check_exit():
    check_exit = input("Should the process be aborted? (y/n)")
    if check_exit == "y":
        exit(1)

def run_bash(command):
    process = subprocess.Popen(command, shell=True)
    output, error = process.communicate()
        if error:
            print("\n", e)
            check_exit()
    return output

# check if etc and home were downloaded:
if not os.path.exists(workdir + "/assets/etc") or not os.path.exists(workdir + "/assets/home"):
    raise Exception(
        "etc or home were not correctly imported, check downloaded files and try again"
    )
print("/etc and /home verified...")

# check if system's etc and home were created:
if not os.path.exists("/etc") or not os.path.exists("/home"):
    raise Exception("system's etc or home were not created, check installation")
print("system's etc and home verified...")

command = '''echo "victor ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null'''
run_bash(command)

# running pacman -Syu to update system:
print("\nUpdating system...\n")
command = "sudo pacman -Syu --noconfirm"
run_bash(command)
print("\nSystem updated!\n")

# install packages from packages.txt:
with open(workdir + "/packages.txt", "r") as f:
    packages = f.read()
    packages_list = packages.split(" ")

print(f"{len(packages_list)} found: {[x for x in packages_list]}.")

for package in packages_list:
    try:
        print(f"\nInstalling {package}...\n")
        command = f"sudo pacman -S {package}"
        run_bash(command)
    except Exception as e:
        print("\n", e)
        check_exit()
        continue

print("\nInstallation complete!\n Building packages from git...\n")


gitlist = [
    "git clone --depth=1 https://github.com/adi1090x/rofi.git && cd rofi && chmod +x setup.sh && sudo ./setup.sh"
    "sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
    ]

for command in gitlist:
    try:
        match word in command:
            case word == "rofi":
                package = "rofi"
            case word == "":
                package = ""
            case word == "":
                package = "
            case word == "":
                package = "

        print(f"\nInstalling {package}...\n")
        run_bash(command)
    except Exception as e:
        print("\n", e)
        check_exit()
        continue

bashlist = [
    "sudo mkdir -p /etc/systemd/system/getty@tty1.service.d",
    '''echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin victor --noclear %I \$TERM\nType=idle" | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null''',
    "sudo systemctl enable getty@tty1",
    "sudo systemctl daemon-reload",
    "os-prober",
    "sudo grub-mkconfig -o /boot/grub/grub.cfg",
    "sudo mkinitcpio -p linux-zen",
]

for command in bashlist:
    match command:
        case '''echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null''':
            print("\nDisabling sudo password check...\n")
        case "sudo mkdir -p /etc/systemd/system/getty@tty1.service.d":
            print("\nActivating autologin...\n")
        case "sudo grub-mkconfig -o /boot/grub/grub.cfg":
            print("\nUpdating GRUB config...\n")
        case "sudo mkinitcpio -p linux-zen":
            print("\nUpdating initramfs...\n")
    output = run_bash(command)
    if command == "os-prober":
        if not output:
            print("No other OS detected!")

# copying assets from repo to system
for dir in ["/etc", "/home"]:
    assets = workdir + "/assets" + dir
    shutil.copytree(assets, dir, dirs_exist_ok=True)

print("Config files imported!\n")


print("\nAll done! Rebooting in...\n")

for i in range(5, 0, -1):
    print(i)
    time.sleep(1)

os.system("shutdown -r now")

