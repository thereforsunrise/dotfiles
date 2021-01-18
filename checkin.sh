#!/usr/bin/env bash

# supposedly the most reliable way to determine a script's path
# according to stack overflow :-(
SCRIPTPATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

mkdir -p "$HOME/Projects"
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

install_packages() {
  sudo apt-get update

  cat "$SCRIPTPATH/packages" "packages.$(hostname -s | tr '[A-Z]' '[a-z]')" \
    2>/dev/null | \
    sort | uniq | \
    xargs sudo apt-get install -y &>/dev/null
}

install_docker() {
  if dpkg -l | grep docker-ce &>/dev/null; then
    return 0
  fi

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
}

install_antigen() {
  if [ ! -f ~/Projects/antigen.zsh ]; then
    echo "Installing antigen..."
    curl -L git.io/antigen > \
      ~/Projects/antigen.zsh
  fi
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
install_docker
install_antigen
run_stow
change_shell
generate_gitconfigs
generate_msmtprc
