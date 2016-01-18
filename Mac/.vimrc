set nobackup 
set nocp
set softtabstop=4
set tabstop=4
set shiftwidth=4
set et
set ignorecase
set hlsearch
set noswapfile

set ai
set ruler
set showcmd
set incsearch
syn on

" Disable the sh.vim plugin from modifying the iskeyword setting
let g:sh_noisk=1

colo desert

function SetMarkdown()
    set filetype=markdown
    set linebreak
    set wrap
endfunction

au BufRead,BufNewFile *.md call SetMarkdown()

