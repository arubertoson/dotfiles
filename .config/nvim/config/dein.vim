"
" Load Plugins from yaml file
function! s:dein_load_yaml(filename) abort
	if executable('yaml2json') && exists('*json_decode')
		" Decode YAML using the CLI tool yaml2json
		" See: https://github.com/koraa/large-yaml2json-json2yaml
		let g:denite_plugins = json_decode(
					\ system('yaml2json', readfile(a:filename)))
	else
		" Fallback to use python and PyYAML
	python << endpython
import vim, yaml
with open(vim.eval('a:filename'), 'r') as f:
	vim.vars['denite_plugins'] = yaml.load(f.read())
endpython
	endif

	for plugin in g:denite_plugins
		call dein#add(plugin['repo'], extend(plugin, {}, 'keep'))
	endfor
	unlet g:denite_plugins
endfunction

"
" Initialize
let s:path = expand('$VARPATH/dein')
let s:plugins_path = expand('$VIMPATH/config/plugins.yaml')
if dein#load_state(s:path)
	call dein#begin(s:path, [expand('<sfile>'), s:plugins_path])
	try
		call s:dein_load_yaml(s:plugins_path)
	catch /.*/
		echoerr v:exception
		echomsg 'Error loading config/plugins.yaml...'
		echomsg 'Caught: ' v:exception
		echoerr 'Please run: pip install --user PyYAML'
	endtry

	if isdirectory(expand('$VIMPATH/dev'))
		call dein#local(expand('$VIMPATH/dev'), {'frozen': 1, 'merged': 0})
	endif
	call dein#end()
	call dein#save_state()
	if dein#check_install()
		if ! has('nvim')
			set nomore
		endif
		call dein#install()
	endif
endif

"
" Load Plugin Mappings
call SourceFile('plugins/all.vim')

filetype plugin indent on
syntax enable

if ! has('vim_starting')
	call dein#call_hook('source')
	call dein#call_hook('post_source')
endif
