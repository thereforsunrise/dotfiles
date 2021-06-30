#!/usr/bin/env bash


source ~/.zsh/common

"$HOME/.dropbox-dist/dropboxd" &

blueman-applet &
braindump &
dunst &
google-chrome &
gtk-redshift &
imwheel -b "4 5" &
nm-applet &
parcellite &
pasystray &
xsetroot -solid '#282A36' &
setxkbmap -option caps:escape &
xset r rate 250 60 &
xset s off -dpm &

[[ -e "$HOME/.xsession_$(hostname -s | tr '[A-Z]' '[a-z'])" ]] && \
  source "$HOME/.xsession_$(hostname -s | tr '[A-Z]' '[a-z'])"

exec i3
