#!/bin/bash
set -v
base_dir=~/projects/dev-env
install_dir=~/projects

mkdir -p "${install_dir}"

git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp "${base_dir}"/zshrc ~/.zshrc

$(cd ~/.oh-my-zsh/custom/themes && git clone https://github.com/bhilburn/powerlevel9k.git)
$(cd ~/.oh-my-zsh/custom/themes/powerlevel9k && git apply "${base_dir}/powertheme.patch")

git clone https://github.com/powerline/fonts.git "${install_dir}"/fonts
$(cd "${install_dir}"/fonts && bash -c ./install.sh)

python_version=$(python3 --version | cut -d " " -f 2 | cut -d "." -f1-2)
if [ "Darwin" == $(uname) ]; then
    export CFLAGS="-isystem /System/Volumes/Data/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Headers"
    extra_params=--with-python3-config-dir=/System/Volumes/Data/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/Current/lib/python${python_version}/config-${python_version}-darwin
fi

$(cd "${install_dir}" && git clone https://github.com/vim/vim.git)
$(cd "${install_dir}"/vim && bash -c ./configure --prefix=/usr/local --with-compiledby=jasondiprinzio --with-features=huge --enable-multibyte --enable-channel --enable-terminal --enable-python3interp=dynamic --enable-perlinterp --enable-xim ${extra_params})
$(cd "${install_dir}"; make -j && sudo make install)

git clone https://github.com/jason-diprinzio/oh-my-vim.git ~/.oh-my-vim
cp "${base_dir}"/vimrc ~/.vimrc
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

$(cd ~/.vim/bundle/YouCompleteMe; ./install.py --clang-completer --java-completer --go-completer --rust-completer --ts-completer)
