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

is_python_package_installed() {
  pip3 list | grep "\<${1}\>" &>/dev/null
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

install_antigen() {
  if ! is_binary_installed "$HOME/Projects/antigen.zsh"; then
    log "Installing antigen..."
    curl -s -L git.io/antigen > \
      ~/Projects/antigen.zsh
  fi
}

install_atom() {
  install_package_from_http_if_not_installed \
    "atom" \
    "https://atom.io/download/deb"
}


install_aws_rotate_key() {
  is_binary_installed "/usr/local/bin/aws-rotate-key" && return 0

  curl \
    -s \
    -L "https://github.com/stefansundin/aws-rotate-key/releases/download/v1.0.7/aws-rotate-key-1.0.7-linux_amd64.zip" \
    -o "/tmp/aws-rotate-key-1.0.7-linux_amd64.zip"

  (
    cd /tmp || exit
    unzip "aws-rotate-key-1.0.7-linux_amd64.zip"
    sudo mv aws-rotate-key /usr/local/bin
  )

  sudo chmod +x /usr/local/bin/aws-rotate-key
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

install_bitwarden() {
  is_binary_installed "/usr/local/bin/bw" && return 0

  curl \
    -s \
    -L "https://github.com/bitwarden/cli/releases/download/v1.20.0/bw-linux-1.20.0.zip" \
    -o "/tmp/bw-linux-1.20.0.zip"

  (
    cd /tmp || exit
    unzip bw-linux-1.20.0.zip -d bw
    sudo mv bw /opt
  )

  sudo ln -s /opt/bw/bw /usr/local/bin/bw
  sudo chmod +x /usr/local/bin/bw
}

install_bootiso() {
  is_binary_installed "/usr/local/bin/bootiso" && return 0

  sudo curl \
        -s \
        -L "https://git.io/bootiso" \
        -o /usr/local/bin/bootiso

  sudo chmod +x /usr/local/bin/bootiso
}

install_braindump() {
  install_package_from_http_if_not_installed \
    "braindump" \
    "https://github.com/thereforsunrise/braindump/releases/download/0.1/BrainDump_1.0.0_amd64.deb"
}

install_brave() {
  is_package_installed "brave-browser" && return 0

  curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | \
    sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
  echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo apt update
  sudo apt install -y brave-browser
}

install_cli53() {
  is_binary_installed "/usr/local/bin/cli53" && return 0

  sudo curl \
        -s \
        -L "https://github.com/barnybug/cli53/releases/download/0.8.18/cli53-linux-amd64" \
        -o /usr/local/bin/cli53

  sudo chmod +x /usr/local/bin/cli53
}

install_circlecicli() {
  is_binary_installed "/usr/local/bin/circleci" & return 0

  curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh | \
    sudo bash
}

install_copilot() {
  is_binary_installed "/usr/local/bin/copilot" & return 0

  sudo curl \
        -s \
        -L "https://github.com/aws/copilot-cli/releases/latest/download/copilot-linux" \
        -o /usr/local/bin/copilot

  sudo chmod +x /usr/local/bin/copilot
}

install_discord() {
  install_package_from_http_if_not_installed \
    "discord" \
    "https://dl.discordapp.net/apps/linux/0.0.13/discord-0.0.13.deb"
}

install_docker() {
  is_package_installed "docker-ce" && return 0

  log "Install Docker..."

  # we install docker prereqs in install_packages
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo apt-key add -

  sudo apt-key fingerprint 0EBFCD88

  sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  sudo gpasswd -a "$USER" docker
}

install_docker_compose() {
  is_binary_installed "/usr/local/bin/docker-compose" && return 0

  sudo curl \
        -s \
        -L "https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose

  sudo chmod +x /usr/local/bin/docker-compose
}

install_dropbox() {
  install_package_from_http_if_not_installed \
    "dropbox" \
    "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2020.03.04_amd64.deb"
}

install_ecscli() {
  is_binary_installed "/usr/local/bin/ecs-cli" && return 0

  curl \
    -s \
    -L "https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest" \
    -o "/tmp/ecs-cli"

  sudo mv /tmp/ecs-cli /usr/local/bin/ecs-cli
  sudo chmod 755 /usr/local/bin/ecs-cli
}

install_elixir() {
  is_package_installed "elixir" && return 0

  log "Install Elixir..."

  curl \
    -s \
    -L "https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb" \
    -o "/tmp/erlang-solutions_2.0_all.deb"

  (
    cd /tmp || exit
    sudo dpkg -i "erlang-solutions_2.0_all.deb"
  )

  sudo apt-get update
  sudo apt-get install -y esl-erlang elixir
}

install_espanso() {
  install_package_from_http_if_not_installed \
    "espanso" \
    "https://github.com/federico-terzi/espanso/releases/latest/download/espanso-debian-amd64.deb"

  [[ $(systemctl --user is-enabled espanso) != "enabled" ]] && \
    espanso start
}

install_gh() {
  install_package_from_http_if_not_installed \
    "gh" \
    "https://github.com/cli/cli/releases/download/v1.5.0/gh_1.5.0_linux_amd64.deb"
}

install_google_chrome() {
  install_package_from_http_if_not_installed \
    "google-chrome-stable" \
    "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
}

install_google_endpoint_verification() {
  is_package_installed "endpoint-verification" && return 0

  echo "deb https://packages.cloud.google.com/apt endpoint-verification main" | \
    sudo tee -a /etc/apt/sources.list.d/endpoint-verification.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo apt-key add -

  sudo apt-get update && \
    sudo apt install endpoint-verification
}

install_k6() {
  is_package_installed "k6" && return 0

  curl -Ss https://dl.k6.io/key.gpg | sudo apt-key add -

  echo "deb https://dl.k6.io/deb stable main" | \
    sudo tee /etc/apt/sources.list.d/k6.list

  sudo apt-get update && \
    sudo apt install k6
}

install_kindle() {
  is_binary_installed "/opt/kindle/kindle" && return 0

  if ! npm list -g | grep nativefier; then
    sudo npm install -g nativefier
  fi

  (
    cd /tmp || exit
    nativefier -n kindle --full-screen  "https://https://read.amazon.com/"
    sudo mv /tmp/kindle-linux-x64 /opt/kindle
  )

  # https://github.com/nativefier/nativefier/issues/851 update WM_CLASS
  t=$(mktemp)
  jq '.name="kindle"' /opt/kindle/resources/app/package.json  > "$t"
  sudo mv "$t" /opt/kindle/resources/app/package.json
}

install_nvm() {
  [[ -d "$HOME/.nvm" ]] && return 0

  # what could go wrong?!
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

  zsh -c "nvm install node"
  zsh -c "nvm use node"
}

install_pulumi() {
  is_binary_installed "$HOME/.pulumi/bin/pulumi" && return 0

  curl -fsSL https://get.pulumi.com/ | sh
}

install_lite() {
  is_binary_installed "/usr/local/bin/lite" && return 0

  curl \
    -s \
    -L "https://github.com/rxi/lite/releases/download/v1.11/lite.zip" \
    -o "/tmp/lite.zip"

  (
    cd /tmp || exit
    unzip lite.zip -d lite
    sudo mv lite /opt
  )

  sudo ln -s /opt/lite/lite /usr/local/bin/lite
}

install_logseq() {
  is_binary_installed "/usr/local/bin/logseq" && return 0

  curl \
    -s \
    -L "https://github.com/logseq/logseq/releases/download/0.5.2/Logseq-linux-x64-0.5.2.AppImage" \
    -o "/tmp/Logseq-linux-x64-0.5.2.AppImage"

  (
    cd /tmp || exit
    sudo mv Logseq-linux-x64-0.5.2.AppImage /usr/local/bin/logseq
  )

  sudo chmod 755 /usr/local/bin/logseq
}

install_rbenv() {
  local rbenv_path="$HOME/.rbenv"

  [[ -d "$rbenv_path" ]] && return 0

  git clone https://github.com/rbenv/rbenv.git "$rbenv_path"
  mkdir -p "$rbenv_path"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$rbenv_path"/plugins/ruby-build
}

install_sessionmanager() {
  install_package_from_http_if_not_installed \
    "session-manager-plugin" \
    "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb"
}
install_signal() {
  is_package_installed "signal-desktop" && return 0

  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
  sudo cp signal-desktop-keyring.gpg /usr/share/keyrings/signal-desktop-keyring.gpg

  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
    sudo tee -a /etc/apt/sources.list.d/signal-xenial.list

  sudo apt update && sudo apt install signal-desktop
}


install_slack() {
  install_package_from_http_if_not_installed \
    "slack-desktop" \
    "https://downloads.slack-edge.com/linux_releases/slack-desktop-4.12.2-amd64.deb"
}

install_spotify() {
  is_package_installed "spotify-client" && return 0

  curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | \
    sudo apt-key add -

  echo "deb http://repository.spotify.com stable non-free" | \
    sudo tee /etc/apt/sources.list.d/spotify.list

  sudo apt-get update && \
    sudo apt-get install -y spotify-client
}

install_steam() {
  install_package_from_http_if_not_installed \
    "steam-launcher" \
    "https://cdn.akamai.steamstatic.com/client/installer/steam.deb"
}

install_steampipe() {
  is_binary_installed "/usr/local/bin/steampipe" && return 0

  sudo /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/turbot/steampipe/main/install.sh)"
}

install_steampipe_plugins() {
  plugins=<<EOF
aws
bitbucket
steampipe
EOF

  for plugin in plugins; do
    if steampipe plugin list | grep "$plugin" &>/dev/null; then
      steampipe plugin install "$plugin"
    fi
  done
}

install_sublime() {
  is_package_installed "sublime-text" && return 0

  curl -sS https://download.sublimetext.com/sublimehq-pub.gpg | \
    sudo apt-key add -

  echo "deb https://download.sublimetext.com/ apt/stable/" | \
    sudo tee /etc/apt/sources.list.d/sublime-text.list

  sudo apt-get update && \
    sudo apt-get install -y sublime-text
}

install_roam() {
  is_binary_installed "/opt/roam/roam" && return 0

  [[ -f "/opt/roam/roam" ]] && return 0

  if ! npm list -g | grep nativefier; then
    sudo npm install -g nativefier
  fi

  (
    cd /tmp || exit
    nativefier -n roam --full-screen  "https://roamResearch.com"
    sudo mv /tmp/roam-linux-x64 /opt/roam/
  )

  # https://github.com/nativefier/nativefier/issues/851 update WM_CLASS
  t=$(mktemp)
  jq '.name="roam"' /opt/roam/resources/app/package.json  > "$t"
  sudo mv "$t" /opt/roam/resources/app/package.json
}

install_unetbootin() {
  is_package_installed "unetbootin" && return 0

  sudo add-apt-repository -y ppa:gezakovacs/ppa
  sudo apt-get update && \
    sudo apt-get install -y unetbootin
}

install_youtubedl() {
  is_binary_installed "/usr/local/bin/youtube-dl" && return 0

  sudo curl \
        -s \
        -L https://yt-dl.org/downloads/latest/youtube-dl \
        -o /usr/local/bin/youtube-dl

  sudo chmod +x /usr/local/bin/youtube-dl
}

install_yq() {
  is_binary_installed "/usr/local/bin/yq" && return 0

  sudo curl \
        -s \
        -L https://github.com/mikefarah/yq/releases/download/v4.18.1/yq_linux_amd64 \
        -o /usr/local/bin/yq

  sudo chmod +x /usr/local/bin/yq
}

install_zoom() {
  install_package_from_http_if_not_installed \
    "zoom" \
    "https://zoom.us/client/latest/zoom_amd64.deb"
}

install_packages() {
  log "Updating apt cache.."
  sudo apt-get update 1>/dev/null

  cat "$SCRIPTPATH/packages" "packages.$(hostname -s | tr '[:upper:]' '[:lower:]')" 2>/dev/null | \
    xargs sudo apt-get install -y 1>/dev/null

  install_antigen
  install_atom
  install_aws_rotate_key
  install_awscli
  install_bitwarden
  install_bootiso
  #install_brave
  #install_kindle
  install_braindump
  install_cli53
  install_circlecicli
  install_copilot
  install_discord
  install_docker
  install_docker_compose
  install_dropbox
  install_ecscli
  install_elixir
  install_espanso
  install_gh
  install_google_chrome
  install_google_endpoint_verification
  install_k6
  install_lite
  install_logseq
  install_nvm
  install_pulumi
  install_rbenv
  install_sessionmanager
  install_signal
  install_slack
  install_spotify
  install_steam
  install_steampipe
  install_steampipe_plugins
  install_sublime
  install_roam
  install_unetbootin
  install_youtubedl
  install_yq
  install_zoom
}

install_python_packages() {
  if ! is_python_package_installed "gita"; then
    pip3 install -U gita
  fi
}

install_atom_packages() {
  apm install save-hooks
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
  install_cron "*/1 * * * *" "$HOME/Projects/thereforsunrise/scripts/runqueue.sh"
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
install_atom_packages
install_python_packages
expand_templates
run_stow
install_crons
make_git_config_readonly
change_shell
copy_msmtp_scripts
generate_mrconfig
allow_passwordless_sudo_for_current_user
configure_thinkfan
generate_secret_example
