
" deoplete for nvim
" ---

" General settings " {{{
" ---
autocmd MyAutoCmd CompleteDone * pclose!

let g:deoplete#max_list = 15
let g:deoplete#max_abbr_width = 35
let g:deoplete#max_menu_width = 20

let g:deoplete#skip_chars = ['(', ')', '<', '>']

let g:deoplete#enable_refresh_always = 0
let g:deoplete#auto_refresh_delay = 20
let g:deoplete#tag#cache_limit_size = 800000
let g:deoplete#file#enable_buffer_path = 1

call deoplete#custom#set('_', 'disabled_syntaxes', ['Comment', 'String'])


let g:deoplete#sources#jedi#statement_length = 1
let g:deoplete#sources#jedi#show_docstring = 1
let g:deoplete#sources#jedi#short_types = 1


" }}}
" Omni functions and patterns " {{{
" ---
let g:deoplete#omni#functions = get(g:, 'deoplete#omni#functions', {})
let g:deoplete#omni#functions.css = 'csscomplete#CompleteCSS'
let g:deoplete#omni#functions.html = 'htmlcomplete#CompleteTags'
let g:deoplete#omni#functions.markdown = 'htmlcomplete#CompleteTags'

let g:deoplete#omni_patterns = get(g:, 'deoplete#omni_patterns', {})
let g:deoplete#omni_patterns.html = '<[^>]*'

let g:deoplete#omni#input_patterns = get(g:, 'deoplete#omni#input_patterns', {})
let g:deoplete#omni#input_patterns.xml = '<[^>]*'
let g:deoplete#omni#input_patterns.md = '<[^>]*'
let g:deoplete#omni#input_patterns.css  = '^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]'
let g:deoplete#omni#input_patterns.scss = '^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]'
let g:deoplete#omni#input_patterns.sass = '^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]'
let g:deoplete#omni#input_patterns.python = ''
let g:deoplete#omni#input_patterns.javascript = ''
let g:deoplete#omni#input_patterns.php = '\w+|[^. \t]->\w*|\w+::\w*'
let g:deoplete#omni#input_patterns.tex = '\\(?:'
			\ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
			\ . '|\w*ref(?:\s*\{[^}]*|range\s*\{[^,}]*(?:}{)?)'
			\ . '|hyperref\s*\[[^]]*'
			\ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
			\ . '|(?:include(?:only)?|input)\s*\{[^}]*'
			\ . '|\w*(gls|Gls|GLS)(pl)?\w*(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
			\ . '|includepdf(\s*\[[^]]*\])?\s*\{[^}]*'
			\ . '|includestandalone(\s*\[[^]]*\])?\s*\{[^}]*'
			\ . '|usepackage(\s*\[[^]]*\])?\s*\{[^}]*'
			\ . '|documentclass(\s*\[[^]]*\])?\s*\{[^}]*'
			\ .')'
" }}}
" Ranking and Marks " {{{
" Default rank is 100, higher is better.
" call deoplete#custom#set('buffer',        'mark', 'ℬ')
" call deoplete#custom#set('tag',           'mark', '⌦')
" call deoplete#custom#set('omni',          'mark', '⌾')
" call deoplete#custom#set('ternjs',        'mark', '⌁')
" call deoplete#custom#set('jedi',          'mark', '⌁')
" call deoplete#custom#set('vim',           'mark', '⌁')
" call deoplete#custom#set('neosnippet',    'mark', '⌘')
" call deoplete#custom#set('around',        'mark', '⮀')
" call deoplete#custom#set('syntax',        'mark', '♯')
" call deoplete#custom#set('tmux-complete', 'mark', '⊶')
" 
" call deoplete#custom#set('vim',           'rank', 620)
" call deoplete#custom#set('jedi',          'rank', 610)
" call deoplete#custom#set('omni',          'rank', 600)
" call deoplete#custom#set('neosnippet',    'rank', 510)
" call deoplete#custom#set('member',        'rank', 500)
" call deoplete#custom#set('file_include',  'rank', 420)
" call deoplete#custom#set('file',          'rank', 410)
" call deoplete#custom#set('tag',           'rank', 400)
" call deoplete#custom#set('around',        'rank', 330)
" call deoplete#custom#set('buffer',        'rank', 320)
" call deoplete#custom#set('dictionary',    'rank', 310)
" call deoplete#custom#set('tmux-complete', 'rank', 300)
" call deoplete#custom#set('syntax',        'rank', 200)
" 
" }}} 
" Matchers and Converters " {{{
" ---

" Default sorters: ['sorter_rank']
" Default matchers: ['matcher_length', 'matcher_fuzzy']


" call deoplete#custom#set('_', 'converters', [
" 	\ 'converter_remove_paren',
" 	\ 'converter_remove_overlap',
" 	\ 'converter_truncate_abbr',
" 	\ 'converter_truncate_menu',
" 	\ 'converter_auto_delimiter',
" 	\ ])

" }}}
" Key-mappings " {{{
" ---

inoremap <expr><C-j> pumvisible() ? "\<Down>" : "\<C-j>"
inoremap <expr><C-k> pumvisible() ? "\<Down>" : "\<C-k>"
inoremap <expr><C-g> deoplete#undo_completion()

" <Tab> completion:
" 1. If popup menu is visible, select and insert next item
" 2. Otherwise, if within a snippet, jump to next input
" 3. Otherwise, if preceding chars are whitespace, insert tab char
" 4. Otherwise, start manual autocomplete
" imap <silent><expr><Tab> pumvisible() ? "\<C-n>"
" 	\ : (neosnippet#jumpable() ? "\<Plug>(neosnippet_jump)"
" 	\ : (<SID>is_whitespace() ? "\<Tab>"
" 	\ : deoplete#manual_complete()))
" 
" smap <silent><expr><Tab> pumvisible() ? "\<C-n>"
" 	\ : (neosnippet#jumpable() ? "\<Plug>(neosnippet_jump)"
" 	\ : (<SID>is_whitespace() ? "\<Tab>"
" 	\ : deoplete#manual_complete()))
" 
" inoremap <expr><S-Tab>  pumvisible() ? "\<C-p>" : "\<C-h>"
" 
" function! s:is_whitespace() "{{{
" 	let col = col('.') - 1
" 	return ! col || getline('.')[col - 1] =~? '\s'
" endfunction "}}}
" }}}

" vim: set ts=2 sw=2 tw=80 noet :
