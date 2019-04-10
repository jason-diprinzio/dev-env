#!/bin/bash

mkdir ~/Projects

git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
$(cd ~/.oh-my-zsh/custom/themes && git clone https://github.com/bhilburn/powerlevel9k.git)
scp -P8001 jason@jason.diprinz.io:powertheme.patch ~/.oh-my-zsh/custom/themes/powerlevel9k/powertheme.patch
$(cd ~/.oh-my-zsh/custom/themes/powerlevel9k && git apply powertheme.patch)
git clone https://github.com/powerline/fonts.git ~/Projects/fonts
$(cd ~/Projects/fonts && ./install.sh)
cp zshrc ~/.zshrc
git clone ssh://jason@jason.diprinz.io:8001/volume3/git/repos/vim-config.git ~/.oh-my-vim
cp vimrc ~/.vimrc
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

curl -L "https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1.tar.gz" > ~/Projects/cmake-3.14.1.tar.gz
$(cd ~/Projects; tar zxvf cmake-3.14.1.tar.gz)
$(cd ~/Projects/cmake-3.14.1/ && ./bootstrap; make && make install)
$(cd ~/.vim/bundle/YouCompleteMe; ./install.py --clang-completer --java-completer --go-completer)

