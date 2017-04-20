
" denite.nvim
" -----------


" INTERFACE
call denite#custom#option('default', 'prompt', '> ')
call denite#custom#option('default', 'vertical_preview', 1)
call denite#custom#option('default', 'short_source_names', 1)
call denite#custom#option('default', 'empty', 0)

call denite#custom#option('default', 'auto_resize', 1)
call denite#custom#option('default', 'winminheight', 10)

" FILTERS
call denite#custom#filter('matcher_ignore_globs', 'ignore_globs',
			\ [ '.git/', '.ropeproject/', '__pycache__/', 'images/',
			\   '*.min.*', 'bundle.js', 'img/', 'fonts/', 'node_modules/',
			\   '*.pyc'
			\ ])


" ALIASES -- modified commands
" Cd project dir
call denite#custom#alias('source', 'directory_rec/project', 'directory_rec')
call denite#custom#var('directory_rec/project', 'command', ['denite-locate', 'git'])
call denite#custom#source('directory_rec/project', 'matchers',
  \ ['matcher_cpsm'])

" Open system file
call denite#custom#alias('source', 'file_rec/locate', 'file_rec')
call denite#custom#var('file_rec/locate', 'command', ['denite-locate', 'files'])
call denite#custom#source('file_rec/locate', 'matchers',
  \ ['matcher_fuzzy'])
" call denite#custom#source('file_rec/locate', 'converters',
"   \ [''])

" Project specific open buffer
call denite#custom#alias('source', 'file_old/project', 'file_old')
call denite#custom#var('file_old/project', 'matchers',
			\ ['matcher_fuzzy', 'matcher_project_files'])


" SORTERS -- default is 'sorter_rank'
" call denite#custom#source('file_rec,outline,redis_mru,note', 'sorters',
" 			\ ['sorter_rank'])


" MATCHERS -- default is matcher_fuzzy
" call denite#custom#source('file_rec,redis_mru,directory_rec', 'matchers',
" 			\ ['matcher_cpsm'])
" call denite#custom#source('line', 'matchers', ['matcher_regexp'])


" call denite#custom#source('file_rec,redis_mru,directory_rec', 'converters',
" 			\ [''])
" CONVERTERS -- default is none
" call denite#custom#source('buffer,file_mru,file_old', 'converters',
"			\ ['converter_relative_word'])



" FIND and GREP COMMANDS
if executable('rg')
  " call denite#custom#var('file_rec', 'command',
  "       \ ['rg', '--files', '--glob', '!.git'])

  call denite#custom#var('grep', 'command', ['rg'])
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'final_opts', [])
  call denite#custom#var('grep', 'separator', ['--'])
  call denite#custom#var('grep', 'default_opts',
        \ ['--vimgrep', '--no-heading'])

elseif executable('ag')
  call denite#custom#var('file_rec', 'command',
        \ ['ag', '--follow', '--nocolor', '--nogroup', '-g', ''])

	call denite#custom#var('grep', 'command', ['ag'])
	call denite#custom#var('grep', 'recursive_opts', [])
	call denite#custom#var('grep', 'separator', ['--'])
	call denite#custom#var('grep', 'final_opts', [])
	call denite#custom#var('grep', 'default_opts',
		\ [ '--vimgrep', '--smart-case', '--hidden' ])

elseif executable('ack')
	" Ack command
	call denite#custom#var('grep', 'command', ['ack'])
	call denite#custom#var('grep', 'recursive_opts', [])
	call denite#custom#var('grep', 'pattern_opt', ['--match'])
	call denite#custom#var('grep', 'separator', ['--'])
	call denite#custom#var('grep', 'final_opts', [])
	call denite#custom#var('grep', 'default_opts',
			\ ['--ackrc', $HOME.'/.config/ackrc', '-H',
			\ '--nopager', '--nocolor', '--nogroup', '--column'])
endif


" DENITE CONSOLE KEY MAPPINGS
let insert_mode_mappings = [
	\  ['kj', '<denite:enter_mode:normal>', 'noremap'],
	\  ['<M-Return>', '<denite:do_action:tabopen>', 'noremap'],
	\  ['<Esc>', '<denite:quit>', 'noremap'],
	\  ['<C-n>', "<denite:move_to_next_line>", 'noremap'],
	\  ['<C-p>', "<denite:move_to_previous_line>", 'noremap'],
	\  ['<M-p>', '<denite:assign_previous_text>', 'noremap'],
	\  ['<M-n>', '<denite:assign_next_text>', 'noremap'],
	\ ]

let normal_mode_mappings = [
	\  ['<M-Return>', '<denite:do_action:tabopen>', 'noremap'],
	\  ['<C-n>', "<denite:move_to_next_line>", 'noremap'],
	\  ['<C-p>', "<denite:move_to_previous_line>", 'noremap'],
	\  ['<M-n>', '<denite:assign_previous_text>', 'noremap'],
	\  ['<M-p>', '<denite:assign_next_text>', 'noremap'],
	\  ['gg', '<denite:move_to_first_line>', 'noremap'],
	\  ['sv', '<denite:do_action:vsplit>', 'noremap'],
	\  ['ss', '<denite:do_action:split>', 'noremap'],
	\ ]

for m in insert_mode_mappings
	call denite#custom#map('insert', m[0], m[1], m[2])
endfor
for m in normal_mode_mappings
	call denite#custom#map('normal', m[0], m[1], m[2])
endfor

" vim: set ts=2 sw=2 tw=80 noet :
