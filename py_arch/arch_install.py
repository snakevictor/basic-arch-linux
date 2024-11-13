import os
import shutil
import subprocess

import pacman  # type: ignore

"""
Python script to setup Arch Linux with custom config files and packages
"""

__author__ = "Victor Monteiro Ribeiro"
__version__ = "0.1"
__email__ = "victormribeiro.py@gmail.com"

workdir = os.getcwd()

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
        print(e)
        input("Press enter to exit...")
        exit(1)

print("\nInstallation complete!\n Importing config files...\n")

for dir in ["etc", "home"]:
    assets_home = workdir + dir
    shutil.copytree(assets_home, dir, dirs_exist_ok=True)

print("Config files imported!\n")

bashlist = [
    "os-prober",
    "sudo grub-mkconfig -o /boot/grub/grub.cfg",
    "sudo update-initramfs -u",
]
for command in bashlist:
    match command:
        case "sudo grub-mkconfig -o /boot/grub/grub.cfg":
            print("\nUpdating GRUB config...\n")
        case "sudo update-initramfs -u":
            print("\nUpdating initramfs...\n")
    process = subprocess.Popen(command, shell=True)
    output, error = process.communicate()
    if command == "os-prober":
        if not output:
            print("No OS detected!")
    if error:
        print("\n", error)
        check_exit = input("Should the process be aborted? (y/n)")
        if check_exit == "y":
            exit(1)

print("\nAll done! Rebooting...\n")
