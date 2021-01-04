#!/usr/bin/env bash

export PATH="$HOME/bin:$HOME/Projects/code/scripts:$PATH"

source ~/.zsh/common

random-background.sh &
setxkbmap -option caps:escape &
xset r rate 250 60 &
imwheel -b "4 5"
parcellite &
pasystray &
xcompmgr &
nm-applet &
gnome-pomodoro  --no-default-window &
blueman-applet &
~/.dropbox-dist/dropboxd &
xset s off -dpms	&
gtk-redshift &
google-chrome &
braindump &

[[ -e "$HOME/.xsession_$(hostname -s | tr '[A-Z]' '[a-z'])" ]] && \
  source "$HOME/.xsession_$(hostname -s | tr '[A-Z]' '[a-z'])"

exec i3
