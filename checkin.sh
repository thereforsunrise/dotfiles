#!/usr/bin/env bash

# supposedly the most reliable way to determine a script's path
# according to stack overflow :-(
SCRIPTPATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

mkdir -p "$HOME/Projects/$WORK_COMPANY_NAME"
mkdir -p "$HOME/.msmtpqueue"

if [ ! -L "$HOME/Projects/zaargy/dotfiles" ]; then
  ln -s "$HOME/.dotfiles/" "$HOME/Projects/zaargy/dotfiles"
fi

if [ ! -L "$HOME/Projects/work" ]; then
  ln -s "$HOME/Projects/$WORK_COMPANY_NAME" "$HOME/Projects/work"
fi

prompt_sudo() {
  # dummy command to get sudo session to we don't prompt later on
  sudo hostname &>/dev/null
}

setup_secret() {
  if [ ! -f "$HOME/.secret" ]; then
    echo "Copying example secrets file. "
    echo "You should fill this in before running this script again."
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
      git pull
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

  echo "Installing $package_name from $url..."

  (
    cd /tmp
    wget -O "$package_name.deb" "$url" && \
    sudo apt install "./$package_name.deb" && \
    rm "./$package_name.deb"
  )
}

install_packages() {
  sudo apt-get update

  cat "$SCRIPTPATH/packages" "packages.$(hostname -s | tr '[A-Z]' '[a-z]')" \
    2>/dev/null | \
    sort | uniq | \
    xargs sudo apt-get install -y &>/dev/null
}

install_braindump() {
  install_package_from_http_if_not_installed \
    "braindump" \
    "https://github.com/zaargy/braindump/releases/download/0.1/BrainDump_1.0.0_amd64.deb"
}

install_google_chrome() {
  install_package_from_http_if_not_installed \
    "google-chrome" \
    "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
}

install_atom() {
  install_package_from_http_if_not_installed \
    "atom" \
    "https://atom.io/download/deb"
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

install_slack() {
  install_package_from_http_if_not_installed \
    "slack-desktop" \
    "https://downloads.slack-edge.com/linux_releases/slack-desktop-4.12.2-amd64.deb"
}

install_discord() {
  install_package_from_http_if_not_installed \
    "discord" \
    "https://dl.discordapp.net/apps/linux/0.0.13/discord-0.0.13.deb"
}

install_docker() {
  is_package_installed "docker-ce" && return 0

  echo "Install Docker..."

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

install_antigen() {
  if [ ! -f ~/Projects/antigen.zsh ]; then
    echo "Installing antigen..."
    curl -L git.io/antigen > \
      ~/Projects/antigen.zsh
  fi
}

install_rbenv() {
  local rbenv_path="$HOME/.rbenv"

  [[ -d "$rbenv_path" ]] && return 0

  git clone https://github.com/rbenv/rbenv.git "$rbenv_path"
  mkdir -p "$rbenv_path"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$rbenv_path"/plugins/ruby-build
}

install_nvm() {
  [[ -d "$HOME/.nvm" ]] && return 0

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
}

install_youtubedl() {
  [[ -f "/usr/local/bin/youtube-dl" ]] && return 0

  sudo curl \
          -L https://yt-dl.org/downloads/latest/youtube-dl \
          -o /usr/local/bin/youtube-dl
  sudo chmod a+rx /usr/local/bin/youtube-dl
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

install_gh() {
  install_package_from_http_if_not_installed \
    "gh" \
    "https://github.com/cli/cli/releases/download/v1.5.0/gh_1.5.0_linux_amd64.deb"
}

run_stow() {
  find "$SCRIPTPATH" \
    -maxdepth 1 \
    -type d \
    -not \
    -name ".*" \
    -exec basename {} \; | sort | \
  while read stow_package; do
    echo "Stowing $stow_package..."
    stow --adopt "$stow_package"
  done
}

change_shell() {
  if [[ "$SHELL" != "/bin/zsh" ]]; then
    echo "Changing shell to zsh"
    chsh -s /bin/zsh
  fi
}

generate_gitconfigs() {
  source ~/.secret

  cat <<EOF > "$HOME/.gitconfig_work"
[user]
    name = $GIT_NAME
    email = $GIT_WORK_EMAIL
EOF

  cat <<EOF > "$HOME/.gitconfig_personal"
[user]
    name = $GIT_NAME
    email = $GIT_PERSONAL_EMAIL
EOF

  # hack to stop pesky atom modifying my gitconfig!
  chmod 444 ~/.dotfiles/git/.gitconfig
}

generate_msmtprc() {
  source ~/.secret

  cat <<EOF > "$HOME/.msmtprc"
account mail
host mail.messagingengine.com
from $MSMTP_EMAIL

auth on
user $MSMTP_EMAIL
password $MSMTP_PASSWORD

tls on
tls_starttls off
tls_fingerprint "$MSMTP_TLS_FINGERPRINT"

syslog LOG_MAIL
account default : mail
EOF
}

generate_vdirsyncer() {
  source ~/.secret

  mkdir -p "$HOME/.vdirsyncer"

  cat <<EOF > "$HOME/.vdirsyncer/config"
[general]
 status_path = "~/.vdirsyncer/status/"

[pair fastmail]
 a = "khal"
 b = "cal"
 collections = ["from a", "from b"]

[storage cal]
 type = "caldav"
 url = "https://caldav.messagingengine.com/"
 username = "$MSMTP_EMAIL"
 password = "$MSMTP_PASSWORD"
 read_only = "true"

[storage khal]
 type = "filesystem"
 path = "$HOME/.vdirsyncer/fastmail"
 fileext = ".ics"
 encoding = "utf-8"
 post_hook = null
EOF
}

echo -e "Checking into $HOSTNAME...\n"

prompt_sudo
setup_secret
checkout_scripts
install_packages
install_braindump
install_google_chrome
install_atom
install_spotify
install_slack
install_discord
install_docker
install_docker_compose
install_antigen
install_rbenv
install_nvm
install_youtubedl
install_awscli
install_tiddlydesktop
install_gh
run_stow
change_shell
generate_gitconfigs
generate_msmtprc
generate_vdirsyncer

if [ ! -L "$HOME/.config/autokey/data/" ]; then
  ln -s "$AUTOKEY_DATA" ~/.config/autokey/data
fi
