" tab through emmet fields
function! s:move_to_next_emmet_area(direction)
  " go to next item in a popup menu
  if pumvisible()
    if (a:direction == 0)
      return "\<C-p>"
    else
      return "\<C-n>"
    endif
  endif

  " try to determine if we're within quotes or angle brackets.
  " if so, assume we're in an emmet fill area.
  let line = getline('.')
  if col('.') < len(line)
    let line = matchstr(line, '[">][^<"]*\%'.col('.').'c[^>"]*[<"]')

    if len(line) >= 2
      if (a:direction == 0)
        return "\<Plug>(emmet-move-prev)"
      else
        return "\<Plug>(emmet-move-next)"
      endif
    endif
  endif

  " return a regular tab character
  return "\<tab>"
endfunction

" expand an emmet sequence like ul>li*5
function! s:expand_emmet_sequence()
  " first try to expand any neosnippets
  if neosnippet#expandable_or_jumpable()
    return "\<Plug>(neosnippet_expand_or_jump)"
  endif

  " expand anything emmet thinks is expandable
  if emmet#isExpandable()
    return "\<Plug>(emmet-expand-abbr)"
  endif

	if pumvisible()
		return "\<C-n>"
	endif
endfun

" using <C-s> requires a line in .bashrc/.zshrc/etc. to prevent
" linux terminal driver from freezing the terminal on ctrl-s:
"     stty -ixon -ixoff
" see: http://unix.stackexchange.com/questions/12107/how-to-unfreeze-after-accidentally-pressing-ctrl-s-in-a-terminal#12108
" also: http://stackoverflow.com/questions/6429515/stty-hupcl-ixon-ixoff

autocmd FileType html,hbs,handlebars,css,scss imap <buffer><expr><C-l> <sid>expand_emmet_sequence()
autocmd FileType html,hbs,handlebars,css,scss imap <buffer><expr><S-TAB> <sid>move_to_next_emmet_area(0)
autocmd FileType html,hbs,handlebars,css,scss imap <buffer><expr><TAB> <sid>move_to_next_emmet_area(1)
