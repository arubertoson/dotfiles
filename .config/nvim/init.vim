" Setup dein  ---------------------------------------------------------------{{{
  if (!isdirectory(expand("$HOME/.config/nvim/repos/github.com/Shougo/dein.vim")))
    call system(expand("mkdir -p $HOME/.config/nvim/repos/github.com"))
    call system(expand("git clone https://github.com/Shougo/dein.vim $HOME/.config/nvim/repos/github.com/Shougo/dein.vim"))
  endif


set runtimepath+=~/.config/nvim/repos/github.com/Shougo/dein.vim

call dein#begin(expand('~/.config/nvim'))

call dein#add('Shougo/dein.vim')
call dein#add('Shougo/denite.nvim')

call dein#add('Shougo/deoplete.nvim')
call dein#add('zchee/deoplete-clang')

" Snippets
call dein#add('SirVer/ultisnips')
call dein#add('honza/vim-snippets')

" Experimental
"
"jj
" call dein#add('kien/rainbow_parentheses.vim')
call dein#add('haya14busa/incsearch.vim')

" Taskwiki
call dein#add('tbabej/taskwiki')
call dein#add('vimwiki/vimwiki')
call dein#add('powerman/vim-plugin-AnsiEsc')
call dein#add('blindFS/vim-taskwarrior')
call dein#add('majutsushi/tagbar')
"

call dein#add('w0rp/ale')
call dein#add('benekastah/neomake')
call dein#add('vhdirk/vim-cmake')

" Text Editing
call dein#add('godlygeek/tabular')
call dein#add('Tpope/vim-commentary')
call dein#add('tpope/vim-repeat')
call dein#add('tpope/vim-abolish')
call dein#add('tpope/vim-surround')
call dein#add('wellle/targets.vim')
call dein#add('justinmk/vim-sneak')
call dein#add('triglav/vim-visual-increment')

" Code Linting
call dein#add('rhysd/vim-clang-format')

" call dein#add('junegunn/fzf', { 'build': './install --all', 'merged': 0 }) 
" call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })

call dein#add('kristijanhusak/vim-hybrid-material')
call dein#add('morhetz/gruvbox')

call dein#add('tmhedberg/SimpylFold', {'on_ft': 'python'})

if dein#check_install()
   call dein#install()
" let pluginsExist=1
endif

call dein#end()
filetype plugin indent on


" ================ General Config ====================


set number                      "Line numbers are good
set cursorline                  "Highlight the line the cursor is on
set colorcolumn=99              "Highlight the character limit
set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000                "Store lots of :cmdline history
set showcmd                     "Show incomplete cmds down the bottom
set gcr=a:blinkon0              "Disable cursor blink
set visualbell                  "No sounds
set autoread                    "Reload files changed outside vim
set laststatus=2                "Enabling statusline at all times
if &encoding != 'utf-8'
    set encoding=utf-8          "Necessary to show Unicode glyphs
endif
set spelllang=fr,en
set mouse=a                     "Mouse in terminal
set clipboard=unnamed           "use system clipboard by default
set inccommand=nosplit          "use incremental replace
set diffopt+=vertical           "prefer vertical diffs


" "Setting the colorscheme
if &t_Co >= 256 || has("gui_running")
    set termguicolors
    set background=dark

    let g:gruvbox_italic=1
    let g:enable_bold_font = 1

    colorscheme gruvbox
endif
 
if &t_Co > 2 || has("gui_running")
    "switch syntax highlighting on, when the terminal has colors
    syntax on
endif

" neomake options
autocmd! BufWritePost * Neomake
let g:neomake_cpp_clang_maker = {
            \ 'exe': 'clang++',
            \ 'args': ['-fsyntax-only', '-std=c++14', '-Wall', '-Wextra'],
            \ 'errorformat':
            \ '%-G%f:%s:,' .
            \ '%f:%l:%c: %trror: %m,' .
            \ '%f:%l:%c: %tarning: %m,' .
            \ '%f:%l:%c: %m,'.
            \ '%f:%l: %trror: %m,'.
            \ '%f:%l: %tarning: %m,'.
            \ '%f:%l: %m',
            \ }
let g:neomake_cpp_clangtidy_maker = {
            \ 'exe': 'clang-tidy',
            \ 'args': ['--checks="modernize-*,readability-*,misc-*,clang-analyzer-*"'],
            \ 'errorformat':
            \ '%E%f:%l:%c: fatal error: %m,' .
            \ '%E%f:%l:%c: error: %m,' .
            \ '%W%f:%l:%c: warning: %m,' .
            \ '%-G%\m%\%%(LLVM ERROR:%\|No compilation database found%\)%\@!%.%#,' .
            \ '%E%m',
            \ }
let g:neomake_cpp_enabled_makers = ['clang', 'clangtidy']



" rainbow parens
" au VimEnter * RainbowParenthesesToggle
" au Syntax * RainbowParenthesesLoadRound
" au Syntax * RainbowParenthesesLoadSquare
" au Syntax * RainbowParenthesesLoadBraces

" ANTLR syntax highlighting
" au BufRead,BufNewFile *.g set filetype=antlr3
" au BufRead,BufNewFile *.g4 set filetype=antlr4

" This makes vim act like all other editors, buffers can
" exist in the background without being in a window.
set hidden

" ================ Search Settings  =================

set incsearch        "Find the next match as we type the search
set viminfo='100,f1  "Save up to 100 marks, enable capital marks

set hlsearch
let g:incsearch#auto_nohlsearch = 1
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

map zn <Plug>(incsearch-nohl0):let @/='\<<C-R>=expand("<cword>")<CR>\>'<CR>:set hlsearch<CR>
map czn zncgn


let mapleader=" "

" ================ Turn Off Swap Files ==============
set noswapfile
set nobackup
set nowb


" ================ Indentation ======================

set autoindent
set smartindent
set smarttab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab

autocmd Filetype go setlocal noexpandtab tabstop=4 shiftwidth=4 softtabstop=4
autocmd Filetype c,cpp,javascript setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2

filetype plugin on
filetype indent on

" Display tabs and trailing spaces visually
set list listchars=trail:·,tab:┊\ ,extends:>,precedes:<,nbsp:·

set nowrap       "Don't wrap lines
set linebreak    "Wrap lines at convenient points


" =================== Clang =======================

let g:clang_format#code_style = "llvm"
autocmd FileType c,cpp,objc nnoremap <buffer><Leader>ef :<C-u>ClangFormat<CR>
autocmd FileType c,cpp,objc vnoremap <buffer><Leader>ef :C-u>ClangFormat<CR>

nmap <Leader>et :ClangFormatAutoToggle<CR>

" ================ Completion =======================

set wildmenu                "enable ctrl-n and ctrl-p to scroll thru matches
set completeopt-=preview    "no scratch window

" deoplete options
let g:deoplete#enable_at_startup = 1
inoremap <silent><expr> <Tab>
            \ pumvisible() ? "\<C-n>" : "<Tab>"

" deoplete-clang opions
let g:deoplete#sources#clang#libclang_path = "/usr/lib/libclang.so"
let g:deoplete#sources#clang#clang_header ="/usr/include/clang"
"
let g:deoplete#sources#clang#std = {
            \ 'c': 'c11', 
            \ 'cpp': 'c++1z', 
            \ 'objc': 'c11',  
            \ 'objcpp': 'c++1z'}
" let g:deoplete#sources#clang#flags = [
"             \ "-I .",
"             \ "-I /usr/local/include",
"             \ "-I /usr/include",
"             \ "-isystem /usr/include/c++/6.3.1"
"             \ ]



" ================ Scrolling ========================

set scrolloff=8         "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=1

" ================ GUI Options ======================
set guioptions=aegimrLt
:map <C-U> <C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y><C-Y>
:map <C-D> <C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E><C-E>
