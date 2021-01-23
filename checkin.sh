#!/usr/bin/env bash

# supposedly the most reliable way to determine a script's path
# according to stack overflow :-(
SCRIPTPATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

mkdir -p "$HOME/Projects/work"
mkdir -p "$HOME/.msmtpqueue"

if [ ! -L "$HOME/Projects/dotfiles" ]; then
  ln -s "$HOME/.dotfiles/" "$HOME/Projects/dotfiles"
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
  dpkg -l | grep "$1" &>/dev/null
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
}

generate_msmtprc() {
  source ~/.secret

  cat <<EOF > "$HOME/.msmtprc"
account fastmail
host mail.messagingengine.com
from $MSMTP_EMAIL

auth on
user $MSMTP_EMAIL
password $MSMTP_PASSWORD

tls on
tls_starttls off
tls_fingerprint "48:50:EB:01:67:E8:22:24:1A:B1:74:F4:B5:0A:98:16:F4:06:92:97:70:76:92:AF:B0:EE:0D:4D:89:6E:4A:09"

syslog LOG_MAIL
account default : fastmail
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
install_antigen
install_rbenv
install_nvm
install_youtubedl
run_stow
change_shell
generate_gitconfigs
generate_msmtprc
