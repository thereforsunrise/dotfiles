#!/usr/bin/env bash

run_if_on_path () {
  if type "$1" >/dev/null 2>/dev/null; then
    "$@" &
  else
    echo "Couldn't run $@ as it wasn't found on the path" >> $HOME/.xsession-log
  fi
}

source ~/.zsh/common

run_if_on_path "$HOME/.dropbox-dist/dropboxd"
run_if_on_path "blueman-applet"
run_if_on_path "braindump"
run_if_on_path "dunst"
run_if_on_path "google-chrome"
run_if_on_path "gtk-redshift"
run_if_on_path "imwheel" "-b" "4 5"
run_if_on_path "nm-applet"
run_if_on_path "parcellite"
run_if_on_path "pasystray"
run_if_on_path "random-background.sh"
run_if_on_path "setxkbmap" "-option" "caps:escape"
run_if_on_path "xset" "r" "rate" "250" "60"
run_if_on_path "xset" "s" "off" "-dpm"

[[ -e "$HOME/.xsession_$(hostname -s | tr '[A-Z]' '[a-z'])" ]] && \
  source "$HOME/.xsession_$(hostname -s | tr '[A-Z]' '[a-z'])"

exec i3
