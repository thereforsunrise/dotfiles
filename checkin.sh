#!/usr/bin/env bash

# supposedly the most reliable way to determine a script's path
# according to stack overflow :-(
SCRIPTPATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

mkdir -p "$HOME/Projects"

if [ ! -L "$HOME/Projects/dotfiles" ]; then
  ln -s "$HOME/.dotfiles/" "$HOME/Projects/dotfiles"
fi

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

install_stow() {
  if ! dpkg -l | grep stow &>/dev/null; then
    echo "Installing stow..."
    sudo apt install -y stow
  fi
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
    -exec basename {} \; | \
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

  if [ ! -L ~/.gitconfig_local ]; then
    ln -s ~/.gitconfig_personal ~/.gitconfig_local
  fi
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

setup_secret
checkout_scripts
install_stow
install_antigen
run_stow
change_shell
generate_gitconfigs
generate_msmtprc
