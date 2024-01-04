#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.zsh/common" &
"$HOME/.dropbox-dist/dropboxd" &

dunst &
imwheel -b "4 5" &
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
unclutter -idle 1 &

#nm-applet &
#blueman-applet &
##parcellite &
#pasystray &
#cbatticon &

xsetroot -solid '#282A36' &
setxkbmap -option caps:escape & 
xset r rate 300 70 &
xset dpms 0 0 0 &
xset s noblank &
xset s off &
xrdb ~/.Xresources &

[[ -e "$HOME/.xsession_$(hostname -s | tr '[:upper:]' '[:lower:]')" ]] && \
  source "$HOME/.xsession_$(hostname -s | tr '[:upper:]' '[:lower:]')" &&

exec i3
