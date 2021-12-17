#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.zsh/common"

"$HOME/.dropbox-dist/dropboxd" &

blueman-applet &
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
# just keep my bloody screen on! I will turn it off with the switch
xset dpms 0 0 0 && xset s noblank && xset s off

# shellcheck disable=SC1090
[[ -e "$HOME/.xsession_$(hostname -s | tr '[:upper:]' '[:lower:]')" ]] && \
  source "$HOME/.xsession_$(hostname -s | tr '[:upper:]' '[:lower:]')"

exec i3
