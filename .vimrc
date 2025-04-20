syntax on
filetype on
filetype plugin on
hi Pmenu ctermfg=black ctermbg=gray guibg=#444444
hi PmenuSel ctermfg=7 ctermbg=4 guibg=#555555 guifg=#ffffff

set background=dark
set number
set showmode
set showcmd
set noswapfile
set nobackup
set nocompatible
set noerrorbells
set wrap
set vb t_vb=
set ignorecase
set mouse-=a
set scrolloff=7
set fileencodings=utf-8,gb18030,ucs-bom,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
set fileformat=unix
set noexpandtab
set tabstop=8
set softtabstop=8
set shiftwidth=8
set shiftround
set smartindent
set backspace=indent,eol,start
set statusline+=%f
set statusline+=\ col:%c
set laststatus=2
set makeprg=mmake

" set mapping
inoremap jj <Esc>

" plug
call plug#begin('~/.vim/plugged')

" CocInstall coc-go
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'fannheyward/coc-rust-analyzer', {'do': 'npm install'}

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-rooter'
Plug 'tpope/vim-fugitive'

" copilot
" Plug 'github/copilot.vim'

call plug#end()

" coc.nvim configuration
inoremap <silent><expr> <TAB>
			\ coc#pum#visible() ? coc#pum#next(1) :
			\ CheckBackspace() ? "\<Tab>" :
			\ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
			\: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]  =~# '\s'
endfunction

nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> K :call ShowDocumentation()<CR>
nmap <leader>rn <Plug>(coc-rename)
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

function! ShowDocumentation()
	if CocAction('hasProvider', 'hover')
		call CocActionAsync('doHover')
	else
		call feedkeys('K', 'in')
	endif
endfunction

autocmd BufWritePre *.go silent call CocActionAsync('format')
autocmd CursorHold * silent call CocActionAsync('highlight')

" fzf configuration
let g:fzf_vim = {}

" vim-rooter
let g:rooter_targets = '/,*'
let g:rooter_patterns = ['.git']

