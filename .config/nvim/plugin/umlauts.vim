
" German umlauts 
"---------------------------------------------------------

" Toggle umlaut bindings on/off
command! UmlautsToggle call <sid>UmlautsToggle()

" german umlauts, technically not abbreviations
let g:umlauts_enabled = 0
let g:umlauts_prefix_map = '"'
let g:umlaut_abbr = [ 
			\ ['a', 'ä'], ['o', 'ö'], ['u', 'ü'], ['A', 'Ä'], 
			\ ['O', 'Ö'], ['U', 'Ü'], ['ss', 'ß'] ]

function! s:UmlautsToggle()
	" Toggle Setting
	if g:umlauts_enabled
		let g:umlauts_enabled = 0
	else
		let g:umlauts_enabled = 1
	endif
	
	" Perform mapping
	for [map_from, map_to] in g:umlaut_abbr
		if g:umlauts_enabled 
			execute 'inoremap' g:umlauts_prefix_map . map_from map_to
		else
			execute 'iunmap' g:umlauts_prefix_map . map_from
		endif
	endfor

endfunction
