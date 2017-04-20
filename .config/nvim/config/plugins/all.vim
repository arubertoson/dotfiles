
" Plugin Settings
"---------------------------------------------------------
if dein#tap('denite.nvim') "{{{

	" Search
	nnoremap <silent><Leader>ss :<C-u>Denite line<CR>
	nnoremap <silent><Leader>sl :<C-u>Denite file_rec/locate<CR>
	nnoremap <silent><Leader>sj :<C-u>Denite jump<CR>
	nnoremap <silent><Leader>st :<C-u>Denite outline<CR>
	nnoremap <silent><Leader>sg :<C-u>Denite grep -buffer-name=grep<CR>
	nnoremap <silent><Leader>sd :<C-u>Denite directory_rec -default-action=cd<CR>
	nnoremap <silent><Leader>sb :<C-u>Denite buffer file_old -default-action=switch<CR>


	" Project
	nnoremap <silent><Leader>pf :<C-u>Denite file_rec<CR>
	nnoremap <silent><Leader>pb :<C-u>Denite buffer file_old/project<CR>
	nnoremap <silent><Leader>pp :<C-u>Denite directory_rec/project<CR>
	nnoremap <silent><Leader>ps :<C-u>Denite session<CR>

	" Utils
	nnoremap <silent><Leader>h  :<C-u>Denite help<CR>
	nnoremap <silent><Leader><Space> :<C-u>Denite filetype command<CR>
	nnoremap <silent><Leader>r :<C-u>Denite register<CR>

	nnoremap <silent><Leader>se :<C-u>Denite location_list<CR>
	nnoremap <silent><Leader>sq :<C-u>Denite quickfix<CR>
endif

if dein#tap('vim-g')
	nnoremap <silent><Leader>swg :<C-u>Google
	nnoremap <silent><Leader>swf :<C-u>Googlef
endif

" if dein#tap('vim-gtrans')
" 	nnoremap <silent><Leader>swt <Plug>(operator-gtrans-buffer){motion}
" 	nnoremap <silent><Leader>swe <Plug>(operator-gtrans-echom){motion}
" endif

"}}}
if dein#tap('accelerated-jk') "{{{
	nmap <silent>j <Plug>(accelerated_jk_gj)
	nmap <silent>k <Plug>(accelerated_jk_gk)
endif

"}}}
if dein#tap('incsearch.vim') "{{{
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
endif

"}}}
if dein#tap('vim-indent-guides') "{{{
	nmap <silent><Leader>ti :<C-u>IndentGuidesToggle<CR>
endif

"}}}
" TODO: Better keybindings
if dein#tap('vim-bookmarks') "{{{
	nmap ma :<C-u>cgetexpr bm#location_list()<CR>
		\ :<C-u>Denite quickfix -buffer-name=list<CR>
	nmap mn <Plug>BookmarkNext
	nmap mp <Plug>BookmarkPrev
	nmap mm <Plug>BookmarkToggle
	nmap mi <Plug>BookmarkAnnotate
endif

"}}}
if dein#tap('goyo.vim') "{{{
	nnoremap [Window]g :Goyo<CR>
endif

"}}}
if dein#tap('vim-expand-region') "{{{
	xmap v <Plug>(expand_region_expand)
	xmap <S-v> <Plug>(expand_region_shrink)
endif

"}}}
if dein#tap('vim-operator-replace') "{{{
	xmap p <Plug>(operator-replace)
endif

"}}}
if dein#tap('vim-operator-surround') "{{{
	map <silent>sa <Plug>(operator-surround-append)
	map <silent>sd <Plug>(operator-surround-delete)
	map <silent>sr <Plug>(operator-surround-replace)
	nmap <silent>saa <Plug>(operator-surround-append)<Plug>(textobj-multiblock-i)
	nmap <silent>sdd <Plug>(operator-surround-delete)<Plug>(textobj-multiblock-a)
	nmap <silent>srr <Plug>(operator-surround-replace)<Plug>(textobj-multiblock-a)
endif

"}}}
if dein#tap('vim-operator-flashy') "{{{
	map y <Plug>(operator-flashy)
	nmap Y <Plug>(operator-flashy)$
endif

"}}}
if dein#tap('vim-niceblock') "{{{
	xmap I  <Plug>(niceblock-I)
	xmap A  <Plug>(niceblock-A)
endif

"}}}
if dein#tap('dsf.vim') "{{{
	nmap dsf <Plug>DsfDelete
	nmap csf <Plug>DsfChange
endif

"}}}
if dein#tap('sideways.vim') "{{{
	nnoremap <silent> m" :SidewaysJumpLeft<CR>
	nnoremap <silent> m' :SidewaysJumpRight<CR>
	omap <silent> a, <Plug>SidewaysArgumentTextobjA
	xmap <silent> a, <Plug>SidewaysArgumentTextobjA
	omap <silent> i, <Plug>SidewaysArgumentTextobjI
	xmap <silent> i, <Plug>SidewaysArgumentTextobjI
endif

"}}}
if dein#tap('CamelCaseMotion') "{{{
	nmap <silent> e <Plug>CamelCaseMotion_e
	xmap <silent> e <Plug>CamelCaseMotion_e
	omap <silent> e <Plug>CamelCaseMotion_e
	nmap <silent> w <Plug>CamelCaseMotion_w
	xmap <silent> w <Plug>CamelCaseMotion_w
	omap <silent> w <Plug>CamelCaseMotion_w
	nmap <silent> b <Plug>CamelCaseMotion_b
	xmap <silent> b <Plug>CamelCaseMotion_b
	omap <silent> b <Plug>CamelCaseMotion_b
endif

"}}}
if dein#tap('vim-textobj-multiblock') "{{{
	omap <silent> ab <Plug>(textobj-multiblock-a)
	omap <silent> ib <Plug>(textobj-multiblock-i)
	xmap <silent> ab <Plug>(textobj-multiblock-a)
	xmap <silent> ib <Plug>(textobj-multiblock-i)
endif

"}}}
if dein#tap('vim-textobj-function') "{{{
	omap <silent> af <Plug>(textobj-function-a)
	omap <silent> if <Plug>(textobj-function-i)
	xmap <silent> af <Plug>(textobj-function-a)
	xmap <silent> if <Plug>(textobj-function-i)
endif
"}}}
