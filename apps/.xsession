#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.zsh/common"

"$HOME/.dropbox-dist/dropboxd" &

blueman-applet &
dunst &
imwheel -b "4 5" &
nm-applet &
parcellite &
pasystray &
xsetroot -solid '#282A36' &
setxkbmap -option caps:escape &
xset r rate 300 80 &
# just keep my bloody screen on! I will turn it off with the switch
xset dpms 0 0 0 && xset s noblank && xset s off

redshift -l manual -l 51.5:0.127 &

# shellcheck disable=SC1090
[[ -e "$HOME/.xsession_$(hostname -s | tr '[:upper:]' '[:lower:]')" ]] && \
  source "$HOME/.xsession_$(hostname -s | tr '[:upper:]' '[:lower:]')"

#xrandr --dpi 162

exec i3

