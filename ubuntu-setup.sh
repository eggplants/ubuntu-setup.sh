#!/bin/bash
# shellcheck disable=SC1090,SC1091

#####################
# interactive setup #
#####################

readonly INSTALL_WAIT_OFF=${1-0}

function cmd_exist() {
  which "$1" >/dev/null && {
    echo "${1}: command already exists"
  } || return 1
}

function file_exist() {
  [ -f "$1" ] && {
    echo "${1}: file already exists"
  } || return 1
}

function wait_enter() {
  [[ "$INSTALL_WAIT_OFF" = 1 ]] && return 0
  for ((i = 0; i++ < 3; )); do
    printf '%0*d\n' "$i"{,} | tr 0-9 v
    sleep 0.15
  done
  if [ $# -eq 0 ]; then
    echo -n '[ENTER]'
    read -r
  else
    echo -n "[${*} - ENTER Y/n]:"
    read -r sel
    [[ "$sel" =~ Y|y ]] && return 0 || return 1
  fi
}

mkdir -p ~/prog

echo '[FIRST: apt update && upgrade]'
sudo apt update -y && sudo apt upgrade -y

wait_enter install required libs with apt && (
  cmd_exist byobu && exit
  sudo apt install git curl wget w3m zsh gcc byobu \
    pinentry-tty build-essential \
    autoconf automake libtool autoconf-doc \
    libtool-doc libreadline-dev obs-studio -y
)

wait_enter install useful commands && (
  cmd_exist jq && exit
  sudo apt install emacs-nox jq feh tree shellcheck peek unar -y
  sudo snap install yq nkf
)

wait_enter install gh && (
  cmd_exist gh && exit
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update
  sudo apt install gh -y
)

wait_enter install and configure japanese input && (
  sudo apt install ibus-mozc -y
  ibus restart
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'jp'), ('ibus', 'mozc-jp')]"
)

wait_enter install docker && (
  cmd_exist docker && exit
  sudo apt install apt-transport-https ca-certificates software-properties-common -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(
      lsb_release -cs
    ) stable" -y
  sudo apt install docker-ce -y
  sudo groupadd docker
  sudo gpasswd -a "$USER" docker
  sudo systemctl restart docker
  echo "After exit and re-login, docker can be executed without sudo."
  wait_enter install shellgei? && (
    sudo docker pull theoldmoon0602/shellgeibot
  )
)

wait_enter install google-chrome && (
  cmd_exist google-chrome && exit
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install ./google-chrome-stable_current_amd64.deb -y

  # fiahfy/youtube-live-chat-flow
  local v
  v="$(curl -s https://github.com/fiahfy/youtube-live-chat-flow/releases |
             egrep "css-truncate-target.*>v" -m1 |
             sed -E 's/^.*>(.*)<.*/\1/'
  )"
  cd ~/Downloads
  mkdir -p ./.yt_flow
  cd ./.yt_flow
  wget "https://github.com/fiahfy/youtube-live-chat-flow/releases/download/${v}/archive.zip"
  unzip archive.zip && rm archive.zip
  google-chrome --load-extension="${PWD}/app"
)

wait_enter install keybase && (
  cmd_exist run_keybase && exit
  curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
  sudo apt install ./keybase_amd64.deb -y
  run_keybase
  while :; do
    wait_enter logged in? && break
  done
  echo "pinentry-program $(which pinentry-tty)" >~/.gnupg/gpg-agent.conf
  gpgconf --kill gpg-agent
  keybase pgp export | gpg --import
  GPG_TTY="$(tty)"
  export GPG_TTY
  # !tw
  while :; do
    { keybase pgp export --secret | gpg --allow-secret-key --import; } && break
    echo retry
    sleep 1
  done
)

wait_enter install vscode && (
  cmd_exist code && exit
  curl -L https://go.microsoft.com/fwlink/?LinkID=760868 -o code_latest.deb
  sudo apt install ./code_latest.deb -y
  code
)

wait_enter install zoom && (
  cmd_exist zoom && exit
  wget http://zoom.us/client/latest/zoom_amd64.deb
  sudo apt install ./zoom_amd64.deb -y
  sudo apt install libgl1-mesa-glx libegl1-mesa libxcb-xtest0 -y
  zoom
)

wait_enter install teams && (
  cmd_exist teams && exit
  curl -L https://go.microsoft.com/fwlink/p/?LinkID=2112886 -o teams_latest.deb
  sudo apt install ./teams_latest.deb -y
  teams
)

wait_enter 'install scopatz/nanorc' && (
  file_exist ~/.nano/gitcommit.nanorc && exit
  curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
)

wait_enter install steam && (
  cmd_exist steam && exit
  curl -OL https://cdn.akamai.steamstatic.com/client/installer/steam.deb
  sudo apt install libgl1-mesa-dri libgl1 libc6 ./steam.deb -y
  steam &
  wait
)

wait_enter install peek && (
  cmd_exist peek && exit
  sudo add-apt-repository ppa:peek-developers/stable -y
  sudo apt update
  sudo apt install peek -y
  peek --version
)

wait_enter install python && (
  cmd_exist python && exit
  cmd_exist pyenv && exit
  sudo apt install libssl-dev libbz2-dev libreadline-dev libsqlite3-dev zlib1g-dev libffi-dev -y
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  cat <<'A' >>~/.bashrc
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="~/.pyenv/shims:$PATH"
which pyenv > /dev/null && {
  eval "$(pyenv init -)"
}
A
  source ~/.bashrc
  PY_LATEST="$(
    pyenv install -l | tac | grep '^ *3[^a-z]*$' -m1
  )"
  pyenv install "${PY_LATEST-3.9.7}"
  pyenv global "${PY_LATEST-3.9.7}"
  pyenv rehash
  python -V
)

wait_enter install ruby && (
  cmd_exist ruby && exit
  cmd_exist rbenv && exit
  sudo apt install libssl-dev zlib1g-dev -y
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  cat <<'A' >>~/.bashrc
export PATH="~/.rbenv/bin:$PATH"
export PATH="~/.rbenv/shims:$PATH"
which rbenv > /dev/null && {
  eval "$(rbenv init -)"
}
A
  source ~/.bashrc
  # RB2_LATEST RB3_LATEST
  RB2_LATEST="$(
    rbenv install -l |& tac | grep '^ *2[^a-z]*$' -m1 | awk '$0=$1'
  )"
  RB3_LATEST="$(
    rbenv install -l |& tac | grep '^ *3[^a-z]*$' -m1 | awk '$0=$1'
  )"
  rbenv install "${RB2_LATEST-2.7.2}"
  rbenv install "${RB3_LATEST-3.0.0}"
  rbenv global "${RB2_LATEST-2.7.2}"
  rbenv rehash
  ruby -v
)

wait_enter install node && (
  cmd_exist n && exit
  sudo apt install nodejs npm -y
  sudo npm install bats n yarn -g
  sudo n stable
  sudo apt purge nodejs npm -y
  curl https://cli-assets.heroku.com/install.sh | sh
  heroku login
)

wait_enter install clisp && (
  cmd_exist ros && exit
  sudo apt install libcurl4-openssl-dev
  git clone https://github.com/roswell/roswell
  cd ./roswell || exit 1
  ./bootstrap && ./configure && make
  sudo make install
  yes '(exit)' | ros run
  cd ../
  rm -rf roswell
)

wait_enter install go && (
  cmd_exist go && exit
  wget https://dl.google.com/go/go1.17.1.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  go --version
  rm go1.17.1.linux-amd64.tar.gz
)

wait_enter install cargo && (
  cmd_exist cargo && exit
  curl https://sh.rustup.rs -sSf | sh -s -- -y
)

wait_enter install yarn && (
  cmd_exist yarn && exit
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  sudo apt-add-repository 'deb https://dl.yarnpkg.com/debian/ stable main' -y
  sudo apt install yarn -y
  yarn -v
)

wait_enter install wine && (
  cmd_exist wine && exit
  curl -sS https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
  sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ groovy main' -y
  sudo apt update
  sudo apt install --install-recommends winehq-staging winetricks -y
)

wait_enter install java && (
  sudo apt install default-jre default-jdk maven -y
  sudo chmod +x /etc/profile.d/maven.sh
)

wait_enter setup gitconfig && (
  file_exist ~/.gitconfig && exit
  echo -n "github token?> "
  read -s token
  cat <<"A" >>~/.netrc
machine github.com
login eggplants
password $token
machine gist.github.com
login eggplants
password $token
A
  gpg -e -r w10776e8w@yahoo.co.jp ~/.netrc
  rm -i ~/.netrc
  sudo chmod +x \
    /usr/share/doc/git/contrib/credential/netrc/git-credential-netrc.perl
  git config --global credential.helper \
    /usr/share/doc/git/contrib/credential/netrc/git-credential-netrc.perl
  git config --global user.name eggplants
  git config --global user.email w10776e8w@yahoo.co.jp
  git config --global user.signingkey "$(
    gpg --list-secret-keys | tac | grep ^sec -m1 -B1 | head -1 | awk '$0=$1'
  )"
  git config --global gpg.program "$(which gpg)"
  git config --global commit.gpgsign true
  git config --global help.autocorrect 1
  git config --global pull.rebase false
)

wait_enter install dotfiles && (
  wget -nv https://raw.githubusercontent.com/fumiyas/home-commands/master/echo-sd
  sudo install -m 0755 echo-sd /usr/local/bin/echo-sd
  rm echo-sd
  file_exist ~/.weatherCast.sh && exit
  git clone https://github.com/eggplants/dotfiles
  cd ./dotfiles || exit 1
  cp -r .*env .*rc .*sh_aliases .*.sh .byobu/ ~
  cd ..
  rm -rf ./dotfiles
)

wait_enter change default shell '(bash -> zsh)' && (
  [ "$SHELL" = '/bin/zsh' ] && echo 'chsh: SHELL already changed to zsh' && exit
  chsh -s /bin/zsh
)

echo '[FINAL: apt autoremove && autoclean]'
sudo apt autoremove -y && sudo apt autoclean -y
[ -f ./*.deb ] && rm -i ./*.deb
