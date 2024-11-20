#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias sups='sudo pacman -S'
alias logout='hyprctl dispatch exit'
alias reboot="sudo reboot"
PS1='[\u@\h \W]\$ '

export PATH=$PATH:/home/victor/.spicetify
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
