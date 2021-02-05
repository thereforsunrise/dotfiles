#!/usr/bin/env bash

# supposedly the most reliable way to determine a script's path
# according to stack overflow :-(
SCRIPTPATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

log() {
  echo -e "[$(date --iso-8601=minutes)] \t ${1}"
}

create_standard_dirs() {
  mkdir -p "$HOME/Projects/$WORK_COMPANY_NAME"
  mkdir -p "$HOME/.msmtpqueue"

  if [ ! -L "$HOME/Projects/zaargy/dotfiles" ]; then
    ln -s "$HOME/.dotfiles/" "$HOME/Projects/zaargy/dotfiles"
  fi

  if [ ! -L "$HOME/Projects/work" ]; then
    ln -s "$HOME/Projects/$WORK_COMPANY_NAME" "$HOME/Projects/work"
  fi

  if [ ! -L "$HOME/.config/autokey/data/" ]; then
    if [ -d  "$AUTOKEY_DATA" ]; then
      rm -rf "$AUTOKEY_DATA"
      mkdir -p "$HOME/.config/autokey"
      ln -s "$AUTOKEY_DATA" "$HOME/.config/autokey/data"
    fi
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
  if [ ! -d ~/Projects/scripts ]; then
    git clone git@github.com:zaargy/scripts.git ~/Projects/scripts
  else
    (
      cd ~/Projects/scripts
      git pull 1>/dev/null
    )
  fi
}

is_package_installed() {
  dpkg -l | grep "\<${1}\>" &>/dev/null
}

install_package_from_http_if_not_installed() {
  local package_name="$1"
  local url="$2"

  is_package_installed "$package_name" && return 0

  log "Installing $package_name from $url..."

  (
    cd /tmp
    wget -O "$package_name.deb" "$url" && \
    sudo apt install "./$package_name.deb" && \
    rm "./$package_name.deb"
  )
}

install_antigen() {
  if [ ! -f ~/Projects/antigen.zsh ]; then
    log "Installing antigen..."
    curl -L git.io/antigen > \
      ~/Projects/antigen.zsh
  fi
}

install_atom() {
  install_package_from_http_if_not_installed \
    "atom" \
    "https://atom.io/download/deb"
}


install_aws_rotate_key() {
  [[ -f "/usr/local/bin/aws-rotate-key" ]] && return 0

  curl \
    -L "https://github.com/stefansundin/aws-rotate-key/releases/download/v1.0.7/aws-rotate-key-1.0.7-linux_amd64.zip" \
    -o "/tmp/aws-rotate-key-1.0.7-linux_amd64.zip"

  (
    cd /tmp/
    unzip "aws-rotate-key-1.0.7-linux_amd64.zip"
    sudo mv aws-rotate-key /usr/local/bin
  )

  sudo chmod +x /usr/local/bin/aws-rotate-key
}

install_awscli() {
  [[ -f "/usr/local/bin/aws" ]] && return 0

  curl \
    -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "/tmp/awscliv2.zip"

  (
    cd /tmp
    unzip awscliv2.zip
    sudo ./aws/install
  )
}

install_braindump() {
  install_package_from_http_if_not_installed \
    "braindump" \
    "https://github.com/zaargy/braindump/releases/download/0.1/BrainDump_1.0.0_amd64.deb"
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
  sudo apt-get install docker-ce docker-ce-cli containerd.io

  sudo gpasswd -a "$USER" docker
}

install_docker_compose() {
  [[ -f "/usr/local/bin/docker-compose" ]] && return 0

  sudo curl \
        -L "https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
}

install_espanso() {
  install_package_from_http_if_not_installed \
    "espanso" \
    "https://github.com/federico-terzi/espanso/releases/latest/download/espanso-debian-amd64.deb"

  espanso start
}

install_gh() {
  install_package_from_http_if_not_installed \
    "gh" \
    "https://github.com/cli/cli/releases/download/v1.5.0/gh_1.5.0_linux_amd64.deb"
}

install_google_chrome() {
  install_package_from_http_if_not_installed \
    "google-chrome" \
    "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
}

install_nvm() {
  [[ -d "$HOME/.nvm" ]] && return 0

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
}

install_rbenv() {
  local rbenv_path="$HOME/.rbenv"

  [[ -d "$rbenv_path" ]] && return 0

  git clone https://github.com/rbenv/rbenv.git "$rbenv_path"
  mkdir -p "$rbenv_path"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$rbenv_path"/plugins/ruby-build
}

install_slack() {
  install_package_from_http_if_not_installed \
    "slack-desktop" \
    "https://downloads.slack-edge.com/linux_releases/slack-desktop-4.12.2-amd64.deb"
}

install_spotify() {
  is_package_installed "spotify-client" && return 0

  curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | \
    sudo apt-key add -

  echo "deb http://repository.spotify.com stable non-free" | \
    sudo tee /etc/apt/sources.list.d/spotify.list

  sudo apt-get update && \
    sudo apt-get install spotify-client
}

install_roam() {
  [[ -f "/opt/roam/roam" ]] && return 0

  if ! npm list -g | grep nativefier; then
    npm install -g nativefier
  fi

  (
    cd /tmp
    nativefier -n Roam --full-screen  "https://roamResearch.com"
    sudo mv /tmp/Roam-linux-x64 /opt/roam/
  )

  ln -s /opt/roam/Roam /opt/roam/roam
}

install_youtubedl() {
  [[ -f "/usr/local/bin/youtube-dl" ]] && return 0

  sudo curl \
          -L https://yt-dl.org/downloads/latest/youtube-dl \
          -o /usr/local/bin/youtube-dl
  sudo chmod a+rx /usr/local/bin/youtube-dl
}

install_packages() {
  log "Updating apt cache.."
  sudo apt-get update 1>/dev/null

  cat "$SCRIPTPATH/packages" "packages.$(hostname -s | tr '[A-Z]' '[a-z]')" 2>/dev/null | \
    xargs sudo apt-get install -y 1>/dev/null

  install_antigen
  install_atom
  install_aws_rotate_key
  install_awscli
  install_braindump
  install_discord
  install_docker
  install_docker_compose
  install_espanso
  install_gh
  install_google_chrome
  install_nvm
  install_rbenv
  install_slack
  install_spotify
  install_roam
  install_youtubedl
}

expand_templates() {
  find "$SCRIPTPATH" \
    -type f \
    -name "*.esub" | \
  while read template; do
    log "Expanding template $template..."

    real_config="${template%.*}"

    envsubst < "$template" > "$real_config"
    if ! grep $(echo $real_config | sed "s#$SCRIPTPATH##") "$SCRIPTPATH/.gitignore" &>/dev/null; then
      echo $(echo $real_config | sed "s#$SCRIPTPATH##") >> "$SCRIPTPATH/.gitignore"
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
  while read stow_package; do
    log "Stowing $stow_package..."
    stow --adopt "$stow_package"
  done
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
