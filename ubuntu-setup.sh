#!/usr/bin/env bash

# FOR Ubuntu 24.04 noble

set -eux

cd ~
mkdir -p prog
mkdir -p _setup
cd _setup

if ! [[ -f ~/.sec.key ]]; then
  echo "need: ~/.sec.key"
  exit 1
fi

gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'

# apt
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y \
  byobu curl feh ffmpeg git \
  ibus-mozc imagemagick jq pinentry-tty pkg-config \
  rhythmbox unar w3m wget zsh

# for python + ruby
sudo apt install -y \
  libssl-dev libbz2-dev libncurses5-dev libncursesw5-dev \
  libffi-dev libreadline-dev libsqlite3-dev tk-dev liblzma-dev \
  libyaml-dev

# mozc
ibus restart
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'jp'), ('ibus', 'mozc-jp')]"

# rancher desktop
curl -s 'https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key' | gpg --dearmor |
  sudo dd status=none of='/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg]'\
     'https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./' | 
  sudo dd status=none of='/etc/apt/sources.list.d/isv-rancher-stable.list'
sudo apt update
sudo apt install rancher-desktop -y
# https://github.com/rancher-sandbox/rancher-desktop/issues/4524#issuecomment-2079041512
sudo ln -s /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fddock

# google chrome
wget 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
sudo apt install ./google-chrome-stable_current_amd64.deb -y

# Qfinder
curl -s 'https://www.qnap.com/ja-jp/utilities/essentials' |
  grep -oEm1 'https://[^"]+/QNAPQfinderProUbuntux64[^"]+\.deb' | xargs wget
sudo apt install ./QNAPQfinderProUbuntux64*.deb -y

# import key
export GPG_TTY="$(tty)"
echo "pinentry-program $(which pinentry-tty)" > ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
cat ~/.sec.key | gpg --allow-secret-key --import
rm ~/.sec.key

# code
wget --trust-server-names -O code_latest.deb 'https://go.microsoft.com/fwlink/?LinkID=760868'
sudo apt install ./code_latest.deb -y

# nanorc
git clone --depth 1 --single-branch 'https://github.com/serialhex/nano-highlight' ~/.nano
cat <<'A'>>~/.nanorc
include "~/.nano/*.nanorc"

set autoindent
set constantshow
set linenumbers
set tabsize 4
set softwrap

# Color
set titlecolor white,red
set numbercolor white,blue
set selectedcolor white,green
set statuscolor white,green
A

# steam
wget 'https://cdn.akamai.steamstatic.com/client/installer/steam.deb'
sudo apt install ./steam.deb -y

# python
git clone 'https://github.com/pyenv/pyenv.git' ~/.pyenv
git clone 'https://github.com/pyenv/pyenv-update.git' ~/.pyenv/plugins/pyenv-update
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
latest_python="$(curl -s 'https://endoflife.date/api/python.json' | jq -r '.[0].cycle')"
pyenv install "$latest_python"
pyenv global "$latest_python"
pip install pipx
pipx install getjump poetry yt-dlp

# ruby
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
eval "$(~/.rbenv/bin/rbenv init - bash)"
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
echo 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' >> ~/.zshrc
git clone 'https://github.com/rbenv/ruby-build.git' "$(rbenv root)"/plugins/ruby-build
latest_ruby="$(curl -s 'https://endoflife.date/api/ruby.json' | jq -r '.[0].latest')"
rbenv install "$latest_ruby"
rbenv global "$latest_ruby"

# node
sudo apt install nodejs npm -y
sudo npm install bats n yarn -g
sudo n stable
sudo apt purge nodejs npm -y

# rust
curl 'https://sh.rustup.rs' | sh -s -- -y
source ~/.cargo/env
cargo install alacritty
sudo update-alternatives --install /usr/bin/x-terminal-emulator \
  x-terminal-emulator ~/.cargo/bin/alacritty 50
mkdir -p ~/.config/alacritty
curl -o- 'https://codeload.github.com/eendroroy/alacritty-theme/tar.gz/refs/heads/master' |
  tar xzf - alacritty-theme-master/themes
mv alacritty-theme-master ~/.config/alacritty
echo 'import = [' >> ~/.config/alacritty/alacritty.toml
find ~/.config/alacritty/alacritty-theme-master/themes -type f -name '*toml' |
  sed 's/^.*/  # "&",/' >> ~/.config/alacritty/alacritty.toml
echo ']' >> ~/.config/alacritty/alacritty.toml

# starship
curl -sS 'https://starship.rs/install.sh' | sh -s -- -y
echo 'eval "$(starship init bash)"' >> ~/.bashrc
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
cat <<'A'>>~/.config/starship.toml
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = false

format = '''\[\[\[${username}@${hostname}:\(${time}\):${directory}:${memory_usage}\]\]\] $package
->>> '''

right_format = '$git_status$git_branch$git_commit$git_state'

[character]
success_symbol = "[>](bold green)"
error_symbol = "[✗](bold red)"

[username]
disabled = false
style_user = "red bold"
style_root = "red bold"
format = '[$user]($style)'
show_always = true

[hostname]
disabled = false
ssh_only = false
style = "bold blue"
format = '[$hostname]($style)'

[time]
disabled = false
format = '[$time]($style)'

[directory]
# truncation_length = 10
truncation_symbol = '…/'
format = '[$path]($style)[$read_only]($read_only_style)'
# truncate_to_repo = false

[memory_usage]
disabled = false
threshold = -1
style = "bold dimmed green"
format = "[$ram_pct]($style)"

[package]
disabled = fals
format = '[$symbol$version]($style)'
A

# hackgen
curl -s 'https://api.github.com/repos/yuru7/HackGen/releases/latest' |
  grep -oEm1 'https://.*/HackGen_NF_v.*.zip' | xargs wget
unar HackGen_NF_v*.zip
mv ./HackGen_NF_v*/ hackgen
sudo mv ./hackgen /usr/share/fonts/truetype/
cat <<'A'>>~/.config/alacritty/alacritty.toml
[font]
size = 10.0

[font.bold]
family = "HackGen Console NF"
style = "Bold"

[font.bold_italic]
family = "HackGen Console NF"
style = "Bold Italic"

[font.italic]
family = "HackGen Console NF"
style = "Italic"

[font.normal]
family = "HackGen Console NF"
style = "Regular"
A

# xclicker
curl -s 'https://api.github.com/repos/robiot/xclicker/releases/latest' |
  grep -oEm1 'https://.*/xclicker_[^_]+_amd64.deb' | xargs wget
sudo apt install ./xclicker_*_amd64.deb -y

# go
sudo apt install -y golang-go

# clisp
curl -s 'https://api.github.com/repos/roswell/roswell/releases/latest' |
  grep -oEm1 'https://.*_amd64.deb' | xargs wget
sudo apt install ./roswell_*_amd64.deb
ros install sbcl-bin

# java
sudo apt install default-jre openjdk-21-jdk maven -y

# wine
: || {
CODENAME="$(lsb_release -c | cut -f2)"
sudo dpkg --add-architecture i386
sudo apt install libfaudio0 -y
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/mantic/winehq-${CODENAME}.sources"
sudo apt update
sudo apt install --install-recommends winehq-devel winetricks -y
winecfg
winetricks fonts allfonts
}

# git
echo -n "github token?> "
# Copy generated fine-grained PAT and paste.
# Required permission: Gist, Contents
read -s -r token
cat << A >> ~/.netrc
machine github.com
login eggplants
password ${token}
machine gist.github.com
login eggplants
password ${token}
A
  git_email="$(
    gpg --list-keys | grep -Em1 '^uid' |
    rev | cut -f1 -d ' ' | tr -d '<>' | rev
  )"
  gpg -e -r "$git_email" ~/.netrc
  rm ~/.netrc
  sudo chmod +x \
    /usr/share/doc/git/contrib/credential/netrc/git-credential-netrc.perl
  git config --global credential.helper \
    /usr/share/doc/git/contrib/credential/netrc/git-credential-netrc.perl
  git config --global user.name eggplants
  git config --global user.email "$git_email"
  git config --global user.signingkey "$(
    gpg --list-secret-keys | tac | grep -m1 -B1 '^sec' | head -1 | awk '$0=$1'
  )"
  git config --global gpg.program "$(which gpg)"
  git config --global commit.gpgsign true
  git config --global help.autocorrect 1
  git config --global pull.rebase false

# runcat
wget https://github.com/win0err/gnome-runcat/releases/latest/download/runcat@kolesnikov.se.shell-extension.zip
gnome-extensions install ./runcat@kolesnikov.se.shell-extension.zip --force
gdbus call --session \
           --dest org.gnome.Shell.Extensions \
           --object-path /org/gnome/Shell/Extensions \
           --method org.gnome.Shell.Extensions.InstallRemoteExtension \
           "runcat@kolesnikov.se"

# zsh
[[ "$SHELL" = "$(which zsh)" ]] || chsh -s "$(which zsh)"
cat <<'A' <~/.zshrc >.zshrc.tmp
#!/usr/bin/env zsh

# load zprofile
[[ -f ~/.zprofile ]] && source ~/.zprofile

# completion
autoload -U compinit
compinit -u
zstyle ':completion:*' menu select

# enable opts
setopt correct
setopt autocd
setopt nolistbeep
setopt aliasfuncdef
setopt appendhistory
setopt histignoredups
# setopt sharehistory
setopt extendedglob
setopt incappendhistory
setopt interactivecomments
setopt prompt_subst

# alias
alias ll='ls -lGF --color=auto'
alias ls='ls -GF --color=auto'

# save cmd history up to 100k
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
HISTFILESIZE=2000
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# enable less to show bin
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable colorized prompt
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac

# enable colorized ls
export LSCOLORS=gxfxcxdxbxegedabagacag
export LS_COLORS='di=36;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;46'
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"

export JAVA_HOME="/usr/lib/jvm/default-java"
export PATH="$PATH:$JAVA_HOME/bin"
export CLASSPATH=".:$JAVA_HOME/jre/lib:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar"
export M2_HOME="/opt/maven"
export MAVEN_HOME="/opt/maven"
export PATH="$PATH:$M2_HOME/bin"

export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin"

export GPG_TTY="$(tty)"

A
mv ~/.zshrc ~/.zshrc.bak
mv .zshrc.tmp ~/.zshrc

byobu-enable
echo '_byobu_sourced=1 . /usr/bin/byobu-launch 2>/dev/null || true' > ~/.zprofile

sudo apt autoremove -y
sudo apt autoclean -y

shutdown -r 1
