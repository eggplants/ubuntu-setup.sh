# my-ubuntu-setup

A setup script for Ubuntu on PC

## Run

```bash
./ubuntu-setup.sh
```

## Lint

```bash
shellcheck ubuntu-setup.sh
bash -n ubuntu-setup.sh
./create-flow-list.sh
```

## Flow

```txt
FIRST: apt update && upgrade
 install commands with apt
 install gh
 install and configure japanese input
 install docker
 install shellgei?
 install google-chrome
 install keybase
 logged in?
 install vscode
 install slack
 install scopatz/nanorc
 install steam
 install peek
 install python
 install ruby
 install node
 install clisp
 install go
 install cargo
 install wine
 install java
 setup gitconfig
 install dotfiles
 change default shell (bash -> zsh)
 install runcat
FINAL: apt autoremove && autoclean
```
