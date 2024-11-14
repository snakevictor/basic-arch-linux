import os
import shutil
import subprocess
import time

import pacman  # type: ignore

"""
Python script to setup Arch Linux with custom config files and packages
"""

__author__ = "Victor Monteiro Ribeiro"
__version__ = "0.3"
__email__ = "victormribeiro.py@gmail.com"

workdir = os.getcwd()


def check_exit():
    check_exit = input("Should the process be aborted? (y/n)")
    if check_exit == "y":
        exit(1)


# check if etc and home were downloaded:
if not os.path.exists(workdir + "/etc") or not os.path.exists(workdir + "/home"):
    raise Exception(
        "etc or home were not correctly imported, check downloaded files and try again"
    )
print("/etc and /home verified...")

# check if system's etc and home were created:
if not os.path.exists("/etc") or not os.path.exists("/home"):
    raise Exception("system's etc or home were not created, check installation")
print("system's etc and home verified...")

# running pacman -Syu to update system:
print("\nUpdating system...\n")
command = "sudo pacman -Syu --noconfirm"
process = subprocess.Popen(command, shell=True)
output, error = process.communicate()
if error:
    print("\n", error)
    check_exit()
print("\nSystem updated!\n")

# install packages from packages.txt:
with open(workdir + "/packages.txt", "r") as f:
    packages = f.read()
    packages_list = packages.split(" ")

print(f"{len(packages_list)} found: {[x for x in packages_list]}.")

for package in packages:
    try:
        print(f"\nInstalling {package}...\n")
        pacman.install(package)
    except Exception as e:
        print("\n", e)
        check_exit()
        continue

print("\nInstallation complete!\n Importing config files...\n")

# copying assets from repo to system
for dir in ["/etc", "/home"]:
    assets = workdir + dir
    shutil.copytree(assets, dir, dirs_exist_ok=True)

print("Config files imported!\n")

bashlist = [
    "os-prober",
    "sudo grub-mkconfig -o /boot/grub/grub.cfg",
    "sudo mkinitcpio -p linux-zen",
]

for command in bashlist:
    match command:
        case "sudo grub-mkconfig -o /boot/grub/grub.cfg":
            print("\nUpdating GRUB config...\n")
        case "sudo mkinitcpio -p linux-zen":
            print("\nUpdating initramfs...\n")
    process = subprocess.Popen(command, shell=True)
    output, error = process.communicate()
    if command == "os-prober":
        if not output:
            print("No OS detected!")
    if error:
        print("\n", error)
        check_exit()

print("\nAll done! Rebooting in...\n")

for i in range(5, 0, -1):
    print(i)
    time.sleep(1)

os.system("shutdown -r now")
