" This is the oh my vim directory
let $OH_MY_VIM="/Users/jason.diprinzio/.oh-my-vim"
let &runtimepath=substitute(&runtimepath, '^', $OH_MY_VIM.",", 'g')

" Select the packages you need
let g:oh_my_vim_packages=[
            \'git', 
            \'indentLine',
            \'basic',
            \'vim',
            \'neobundle'
            \'sessions', 
            \'tools', 
            \]

exec ':so ' $OH_MY_VIM."/vimrc"

