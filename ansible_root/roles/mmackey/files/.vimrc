syntax on
filetype plugin indent on

set nonu
colorscheme delek
set colorcolumn=85

" Have all indents be 2 spaces, have tabs replaced with spaces, and have the >> and
" << operators peforms indents of 2 spaces
set tabstop=2 shiftwidth=2 expandtab

:set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<,nbsp:.

"-----------------------------------------------------
" SEARCH configurations
"-----------------------------------------------------
" search highlighting
" NOTE: Use ':noh' or ',h' to turn off search highlighting until next search
:set hlsearch

" show match as search proceeds
:set incsearch

" ignore case if search pattern is all lowercase, case-sensitive otherwise
set smartcase

"-----------------------------------------------------
" From: http://stackoverflow.com/questions/7652820/how-to-disable-the-auto-comment-in-shell-script-vi-editing
"-----------------------------------------------------
" Needed to stop vim from automatically commenting out any text I paste to a file
" Search for highlighted text
" from an external source (that starts with a #...not sure if only in this case??)
set paste

"-----------------------------------------------------
" From: https://www.cs.swarthmore.edu/help/vim/etc.html
"-----------------------------------------------------
" Allow mouse to move cursor
set mouse=a

"#------------------------------------------------------------------------------------------
"#------------------------------------------------------------------------------------------
"# START: .vimrc.OLD
"#------------------------------------------------------------------------------------------
"#------------------------------------------------------------------------------------------
" IMPORTANT:
"   see ~/.vim/bundle/vim-sensible/plugin/sensible.vim for more config options.
"
" NOTE: it appears that plugin file takes precedence / is evaluated last b/c putting
" things like 'set noautoindent' in here don't seem to work b/c it sets autoindenting
" there via 'set autoindent'

"" Next 3 lines from vim-pathogen plugin at:
""  - https://github.com/tpope/vim-pathogen
"execute pathogen#infect()
"syntax on
"filetype plugin indent on
"
"set nonu
"colorscheme delek
"set colorcolumn=85

"" Have all indents be 4 spaces, have tabs replaced with spaces, and have the >> and
"" << operators peforms indents of 4 spaces
""set tabstop=2 shiftwidth=2 expandtab
"
":set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<,nbsp:.
"
""-----------------------------------------------------
"" SEARCH configurations
""-----------------------------------------------------
"" search highlighting
"" NOTE: Use ':noh' or ',h' to turn off search highlighting until next search
":set hlsearch
"
"" show match as search proceeds
":set incsearch
"
"" ignore case if search pattern is all lowercase, case-sensitive otherwise
"set smartcase
"
""-----------------------------------------------------
"" From: https://github.com/derekwyatt/vim-config/blob/master/vimrc
""-----------------------------------------------------
"" change the mapleader from \ to ,
"let mapleader=","
"
"" Turn off that stupid highlight search
"nmap <silent> ,n :nohls<CR>
"
"" Quickly edit/reload the vimrc file
"nmap <silent> <leader>ev :e $MYVIMRC<CR>
"" this next one turns of highlighting for some reason when re-loading .vimrc ??
"nmap <silent> <leader>sv :so $MYVIMRC<CR>
"
""-----------------------------------------------------
"" From: http://vim.wikia.com/wiki/Search_for_visually_selected_text
""-----------------------------------------------------
"" Search for highlighted text
"vnorem // y/<c-r>"<cr>
"
""-----------------------------------------------------
"" From: http://stackoverflow.com/questions/7652820/how-to-disable-the-auto-comment-in-shell-script-vi-editing
""-----------------------------------------------------
"" Needed to stop vim from automatically commenting out any text I paste to a file
"" Search for highlighted text
"" from an external source (that starts with a #...not sure if only in this case??)
"set paste
"
""-----------------------------------------------------
"" From: https://www.cs.swarthmore.edu/help/vim/etc.html
""-----------------------------------------------------
"" Allow mouse to move cursor
"set mouse=a
