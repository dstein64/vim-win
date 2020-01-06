" TODO: handle range/count (visual selection)?
" TODO: alternative approach for resizing windows (current doesn't always
" work properly)..

" Set g:force_load_win = 1 to force load.
if !get(g:, 'force_load_win', 0) && exists('g:loaded_win')
  finish
endif
let g:loaded_win = 1

let s:save_cpo = &cpo
set cpo&vim

if !hasmapto('<Plug>WinWin')
  map <leader>w <Plug>WinWin
endif
noremap <silent> <script> <Plug>WinWin <SID>Win
noremap <SID>Win :<c-u>call win#Win()<cr>

if !exists(':Win')
  command Win :call s:Win()
endif

" ************************************************************
" * Configuration
" ************************************************************

let g:win_resize_height = 2
let g:win_resize_width = 2
let g:win_disable_version_warning = get(g:, 'win_disable_version_warning', 0)
" g:win_ext_command_map allows additional commands to be added to win.vim. It
" maps command keys to command strings. These will override the built-in
" vim-win commands that use the same keys, except for 1) <esc>, which is used
" for exiting, and 2) ?, which is used for help.
" E.g.,
" :let g:win_ext_command_map = {
"        \   'c': 'wincmd c',
"        \   'C': 'close!',
"        \   'q': 'quit',
"        \   'Q': 'quit!',
"        \   '!': 'qall!',
"        \   'V': 'wincmd v',
"        \   'S': 'wincmd s',
"        \   'n': 'bnext',
"        \   'N': 'bnext!',
"        \   'p': 'bprevious',
"        \   'P': 'bprevious!',
"        \   "\<c-n>": 'tabnext',
"        \   "\<c-p>": 'tabprevious',
"        \   '=': 'wincmd =',
"        \   't': 'tabnew',
"        \ }
let g:win_ext_command_map = get(g:, 'win_ext_command_map', {})

" The default highlight groups (for colors) are specified below.
" Change these default colors by defining or linking the corresponding
" highlight group.
" E.g., the following will use the Error highlight for the active window.
" :highlight link WinActive Error
" E.g., the following will use custom highlight colors for the inactive windows.
" :highlight WinInactive term=bold ctermfg=12 ctermbg=159 guifg=Blue guibg=LightCyan
highlight default link WinActive DiffAdd
highlight default link WinInactive Todo
highlight default link WinNeighbor Todo
highlight default link WinStar StatusLine
highlight default link WinPrompt ModeMsg

let &cpo = s:save_cpo
unlet s:save_cpo
