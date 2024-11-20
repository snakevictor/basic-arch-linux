#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi

PATH=$PATH:~/.config/rofi/scripts

# Created by `pipx` on 2024-11-11 14:36:26
export PATH="$PATH:/home/victor/.local/bin"

export PATH=$PATH:/home/victor/.spicetify
