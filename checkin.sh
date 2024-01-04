#!/usr/bin/env bash

# supposedly the most reliable way to determine a script's path
# according to stack overflow :-(
SCRIPTPATH="$(cd "$(dirname "$0")" || exit >/dev/null 2>&1 ; pwd -P)"

log() {
  echo -e "[$(date --iso-8601=minutes)] \t ${1}"
}

create_standard_dirs() {
  rm -rf ~/Desktop ~/Documents ~/Downloads ~/Music \
    ~/Pictures ~/Public ~/Templates ~/Videos/

  mkdir -p "$HOME/Projects/$GITHUB_USERNAME"
  mkdir -p "$HOME/Projects/$WORK_COMPANY_NAME"
  mkdir -p "$HOME/.msmtpqueue"
  mkdir -p "$HOME/Mail/.mutt"

  if [ ! -L "$HOME/Projects/thereforsunrise/dotfiles" ]; then
    ln -s "$HOME/.dotfiles/" "$HOME/Projects/thereforsunrise/dotfiles"
  fi

  if [ ! -L "$HOME/Projects/work" ]; then
    ln -s "$HOME/Projects/$WORK_COMPANY_NAME" "$HOME/Projects/work"
  fi
}

prompt_sudo() {
  # dummy command to get sudo session to we don't prompt later on
  sudo hostname &>/dev/null
}

setup_secret() {
  if [ ! -f "$HOME/.secret" ]; then
    log "Copying example secrets file. "
    log "You should fill this in before running this script again."
    cp "$SCRIPTPATH/secret.example" "$HOME/.secret"
    exit 1
  fi
}

checkout_scripts() {
  if [ ! -d ~/Projects/thereforsunrise/scripts ]; then
    git clone git@github.com:thereforsunrise/scripts.git ~/Projects/thereforsunrise/scripts
  else
    (
      cd ~/Projects/thereforsunrise/scripts || exit
      git pull 1>/dev/null
    )
  fi
}

is_package_installed() {
  dpkg -l | grep "\<${1}\> " &>/dev/null
}

is_binary_installed() {
  [[ -f "$1" ]]
}

install_package_from_http_if_not_installed() {
  local package_name="$1"
  local url="$2"

  is_package_installed "$package_name" && return 0

  log "Installing $package_name from $url..."

  (
    cd /tmp || exit
    wget -O "$package_name.deb" "$url" && \
    sudo apt install -y "./$package_name.deb" && \
    rm "./$package_name.deb"
  )
}

install_awscli() {
  is_binary_installed "/usr/local/bin/aws" && return 0

  curl \
    -s \
    -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "/tmp/awscliv2.zip"

  (
    cd /tmp || exit
    unzip awscliv2.zip
    sudo ./aws/install
  )
}

install_espanso() {
  install_package_from_http_if_not_installed \
    "espanso" \
    "https://github.com/federico-terzi/espanso/releases/latest/download/espanso-debian-amd64.deb"

    sudo espanso service register
    sudo espanso service start
}



install_packages() {
  log "Updating apt cache.."
  sudo apt-get update 1>/dev/null

  cat "$SCRIPTPATH/packages" "packages.$(hostname -s | tr '[:upper:]' '[:lower:]')" 2>/dev/null | \
    xargs sudo apt-get install -y 1>/dev/null

  install_awscli
  install_espanso
}

expand_templates() {
  find "$SCRIPTPATH" \
    -type f \
    -name "*.esub" | \
  while read -r template; do
    log "Expanding template $template..."

    real_config="${template%.*}"

    envsubst < "$template" > "$real_config"
    if ! grep "${real_config//$SCRIPTPATH/}" "$SCRIPTPATH/.gitignore" &>/dev/null; then
      echo "${real_config//$SCRIPTPATH/}" >> "$SCRIPTPATH/.gitignore"
    fi
  done
}

run_stow() {
  find "$SCRIPTPATH" \
    -maxdepth 1 \
    -type d \
    -not \
    -name ".*" \
    -exec basename {} \; | sort | \
  while read -r stow_package; do
    log "Stowing $stow_package..."
    stow --adopt "$stow_package"
  done
}

install_cron() {
  local expression="$1"
  local command="$2"
  (crontab -l ; echo "$expression $command") | sort - | uniq - | crontab -
}

install_crons() {
  log "Installing crons..."
  install_cron "*/5 * * * *" "$HOME/Projects/thereforsunrise/scripts/runqueue.sh"
  install_cron "*/5 * * * *" "$HOME/Projects/thereforsunrise/scripts/dyndns.sh '$UPDATE_URL' '$UPDATE_SECRET' '$(hostname -s)'"
  install_cron "*/5 * * * *" "$HOME/Projects/thereforsunrise/scripts/dyndns.sh '$UPDATE_URL' '$UPDATE_SECRET' '$(hostname -s)-int' 'internal'"
  install_cron "*/30 * * * *" "bash -c '$HOME/Projects/thereforsunrise/scripts/sunrise-and-sunset.sh' > '$HOME/.sunset-sunrise'"
}

change_shell() {
  if [[ "$SHELL" != "/bin/zsh" ]]; then
    log "Changing shell to zsh"
    chsh -s /bin/zsh
  fi
}

make_git_config_readonly() {
  # hack to stop pesky atom modifying my gitconfig!
  chmod 444 ~/.dotfiles/git/.gitconfig
}

copy_msmtp_scripts() {
  for e in msmtp-enqueue.sh msmtp-runqueue.sh msmtp-listqueue.sh; do
    if [ ! -f "/usr/local/bin/$e" ]; then
      sudo cp "/usr/share/doc/msmtp/examples/msmtpqueue/$e" /usr/local/bin
      sudo chmod 755 "/usr/local/bin/$e"
    fi
  done
}

generate_mrconfig() {
  generate-mrconfig
}

allow_passwordless_sudo_for_current_user() {
  local USER="$(whoami)"

  echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$USER" > /dev/null
}

configure_thinkfan() {
  if [[ $(hostname -s) == "data" ]]; then
cat <<EOF | sudo tee /etc/thinkfan.conf >/dev/null
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon8/temp1_input
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon8/temp2_input
hwmon /sys/devices/platform/coretemp.0/hwmon/hwmon8/temp3_input

(0,	0,	60)
(1,	60,	65)
(2,	65,	70)
(3,	70,	75)
(4,	75,	80)
(5,	80,	85)
(7,	85,	32767)
EOF
  fi
}

generate_secret_example() {
  cat ~/.secret | cut -f1 -d= | xargs -I {} echo {}= | \
    tee "$SCRIPTPATH/.secret.example" >/dev/null
}

if [[ -n "$1" ]]; then
  eval "$1"
  exit
fi

log "Checking into $HOSTNAME..."

create_standard_dirs
prompt_sudo
setup_secret
checkout_scripts
install_packages
expand_templates
run_stow
make_git_config_readonly
change_shell
allow_passwordless_sudo_for_current_user
generate_secret_example
