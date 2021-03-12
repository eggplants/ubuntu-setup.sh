# my-ubuntu-setup

A setup script for Ubuntu on PC

## Run

```bash
$ ./ubuntu-setup.sh
```

## Lint

```bash
$ shellcheck ubuntu-setup.sh
$ bash -n ubuntu-setup.sh
$ ./create-flow-list.sh
```

## Flow

```txt
FIRST: apt update && upgrade
 install required libs with apt
 install useful commands
 install and configure japanese input
 install docker
 install shellgei?
 install google-chrome
 install keybase
 logged in?
 install vscode
 install zoom
 install teams
 install scopatz/nanorc
 install steam
 install python
 install ruby
 install clisp
 install yarn
 setup gitconfig
 install dotfiles
 change default shell (bash -> zsh)
FINAL: apt autoremove && autoclean
```
