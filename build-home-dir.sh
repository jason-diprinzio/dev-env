#!/bin/bash
mkdir -p ~/.xmonad

cp zshrc ~/.zshrc
cp vimrc ~/.vimrc
cp tmux.conf ~/.tmux.conf
cp ycm_extra_conf.py ~/.ycm_extra_conf.py
cp gitignore ~/.gitignore

if [ "Linux" == $(uname) ]; then
	mkdir ~/.xmonad
	cp xmonad.hs ~/.xmonad/xmonad.hs
	mkdir ~/.config/i3
	cp i3-config ~/.config/i3/config
fi
