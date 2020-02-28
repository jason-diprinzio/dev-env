#!/bin/bash
intall_dir=/home/jason/projects

mkdir ""${install_dir}""

git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
$(cd ~/.oh-my-zsh/custom/themes && git clone https://github.com/bhilburn/powerlevel9k.git)
$(cd ~/.oh-my-zsh/custom/themes/powerlevel9k && git apply ~/Projects/sandbox/powertheme.patch)
git clone https://github.com/powerline/fonts.git "${install_dir}"/fonts
$(cd "${install_dir}"/fonts && ./install.sh)
cp zshrc ~/.zshrc

$(cd "${install_dir}" && git clone https://github.com/vim/vim.git)
$(cd "${install_dir}"/vim && ./configure --prefix=/usr/local --with-compiledby=jasondiprinzio --with-features=huge --enable-multibyte --enable-terminal --enable-pythoninterp --enable-python3interp --enable-perlinterp --enable-xim)
$(cd "${install_dir}"; make && sudo make install)

git clone git@github.com:jason-diprinzio/vim-config.git ~/.oh-my-vim
cp vimrc ~/.vimrc
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

curl -L "https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1.tar.gz" > "${install_dir}"/cmake-3.14.1.tar.gz
$(cd "${install_dir}"; tar zxvf cmake-3.14.1.tar.gz)
$(cd "${install_dir}"/cmake-3.14.1/ && ./bootstrap; make && make install)
$(cd ~/.vim/bundle/YouCompleteMe; ./install.py --clang-completer --java-completer --go-completer)

