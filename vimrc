set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive' " Git wrapper
Plugin 'scrooloose/syntastic' " Syntax checking
Plugin 'tpope/vim-surround' " Quoting and parenthesizing made simple
Plugin 'vim-airline/vim-airline' " Status bar
Plugin 'vim-airline/vim-airline-themes'
Plugin 'scrooloose/nerdcommenter' " Nice commenting
Plugin 'valloric/youcompleteme' " Code completion
Plugin 'godlygeek/tabular' " Tabs
Plugin 'honza/vim-snippets' " Snipets
Bundle 'flazz/vim-colorschemes'
Plugin 'vim-scripts/indentpython.vim'
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'scrooloose/nerdtree'

" All of your Plugins must be added before the following line
call vundle#end()            " required

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" Syntax highlight
filetype plugin indent on    " required
syntax on

" Add PEP8 indentation
"au BufNewFile,BufRead *.py set tabstop=4 softtabstop=4 shiftwidth=4 textwidth=79 expandtab autoindent fileformat=unix

" Display tabs at the beginning of a line in Python mode as bad.
"au BufRead,BufNewFile *.py,*.pyw match BadWhitespace /^\t\+/
" Make trailing whitespace be flagged as bad.
"au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

set tabstop=4       " Number of spaces that a <Tab> in the file counts for.
 
set shiftwidth=4    " Number of spaces to use for each step of (auto)indent.
set expandtab

" Make your code look pretty
let python_highlight_all=1
syntax on
set background=dark
set t_Co=256
colorscheme candyman

" Add UTF8 support
set encoding=utf-8

" System clipboard
set clipboard=unnamed

" Line numbers
set number

" Shift the wrapped line another four spaces to the right for Python files
autocmd FileType python set breakindentopt=shift:4

" Use a mouse
set mouse=a

" Save cursor place after reopening the file
augroup resCur
  autocmd!
  autocmd BufReadPost * call setpos(".", getpos("'\""))
augroup END

let g:airline_powerline_fonts = 1
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

set rtp+=/opt/homebrew/opt/fzf

