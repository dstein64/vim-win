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
noremap <SID>Win :<c-u>call <SID>Win()<cr>

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

" ************************************************************
" * Core
" ************************************************************

let s:popupwin = has('popupwin')
let s:floatwin = exists('*nvim_open_win') && exists('*nvim_win_close')

let s:code0 = char2nr('0')
let s:code1 = char2nr('1')
let s:code9 = char2nr('9')
let s:esc_chars = ["\<esc>"]
let s:left_chars = ['h', "\<left>"]
let s:down_chars = ['j', "\<down>"]
let s:up_chars = ['k', "\<up>"]
let s:right_chars = ['l', "\<right>"]
let s:shift_left_chars = ['H', "\<s-left>"]
let s:shift_down_chars = ['J', "\<s-down>"]
let s:shift_up_chars = ['K', "\<s-up>"]
let s:shift_right_chars = ['L', "\<s-right>"]
let s:control_left_chars = ["\<c-h>", "\<c-left>"]
let s:control_down_chars = ["\<c-j>", "\<c-down>"]
let s:control_up_chars = ["\<c-k>", "\<c-up>"]
let s:control_right_chars = ["\<c-l>", "\<c-right>"]

" Returns window count, with special handling to exclude floating and external
" windows in neovim. The windows with numbers less than or equal to the value
" returned are assumed non-floating and non-external windows. The
" documentation for ":h CTRL-W_w" says "windows are numbered from top-left to
" bottom-right", which does not ensure this, but checks revealed that floating
" windows are numbered higher than ordinary windows, regardless of position.
function! s:WindowCount()
  if !has('nvim') || !exists('*nvim_win_get_config')
    return winnr('$')
  endif
  let l:win_count = 0
  for l:winid in range(1, winnr('$'))
    let l:config = nvim_win_get_config(win_getid(l:winid))
    if !get(l:config, 'external', 0) && get(l:config, 'relative', '') ==# ''
      let l:win_count += 1
    endif
  endfor
  return l:win_count
endfunction

function! s:Contains(list, element)
  return index(a:list, a:element) !=# -1
endfunction

" The following few functions are for resizing windows. The current approach
" resizes windows by using a function that expands a window. Various other
" approaches were attempted (including other approaches for window expansion),
" but they were found to not handle some specific use-case (e.g., see below).
"
" Difficult use case 1
" Resizing window 5 by moving its top border up
"
"   1|3
"   -|-
"   2|4
"   ---
"    5
"   ---
"    6
"
" Difficult use case 2
" Resizing window 3 by moving its left border left
" Resizing window 4 by moving its left border left
"
"  1 | | | 6
" ---|4|5|---
" 2|3| | |7|8

" Returns a dictionary with boundaries for the specified window.
" Dictionary keys correspond to directions hjkl.
function! s:GetBoundaries(winnr)
    let [l:k, l:h] = win_screenpos(a:winnr)
    let l:j = l:k + winheight(a:winnr) - 1
    let l:l = l:h + winwidth(a:winnr) - 1
    let l:boundaries = {'h': l:h, 'j': l:j, 'k': l:k, 'l': l:l}
    return l:boundaries
endfunction

" TODO: take arg specifying which direction to expand and how much
" TODO: add documentation
" TODO: prefix with s:
" TODO: this doesn't currently work.
function! s:Expand(winnr, dir)
  " TODO: check dir is hjkl and throw error otherwise
  let l:hl = a:dir ==# 'h' || a:dir ==# 'l'
  let l:hk = a:dir ==# 'h' || a:dir ==# 'k'
  let l:resize_prefix = l:hl ? 'vertical ' : ''
  let l:winmin = l:hl ? &winminwidth : &winminheight
  let l:win_count = s:WindowCount()
  let l:boundaries = [{}]
  for l:winnr in range(1, l:win_count)
    let l:boundary = s:GetBoundaries(l:winnr)
    call add(l:boundaries, l:boundary)
  endfor
  let l:sorted_windows = range(1, l:win_count)
  "TODO (perhaps this should be 'h' in this case for 'l' above (actually
  "probably not since that might then try to shrink full width windows).
  let l:Compare = {x, y -> l:boundaries[x][a:dir] - l:boundaries[y][a:dir]}
  call sort(l:sorted_windows, l:Compare)
  if l:hk | call reverse(l:sorted_windows) | endif
  for l:winnr in l:sorted_windows
    let l:boundary = l:boundaries[l:winnr]
    " TODO: this can probably be constrained further to windows with
    " overlapping rows or columns, but may not matter.
    " TODO does following need inequality? (will have to switch direction
    " conditionally)
    if l:boundary[a:dir] ==# l:boundaries[a:winnr][a:dir] | break | endif
    execute l:resize_prefix . l:winnr . 'resize ' . l:winmin
  endfor
  let l:size = l:hl ? winwidth(a:winnr) : winheight(a:winnr)
  let l:diff = l:hl ? g:win_resize_width : g:win_resize_height
  " Can't currently use relative resizing for the non-active window.
  " Issue #5443 (https://github.com/vim/vim/issues/5443)
  execute l:resize_prefix . a:winnr . 'resize ' . (l:size + l:diff)
  for l:winnr in l:sorted_windows
    let l:boundary = l:boundaries[l:winnr]
    " TODO: see TODOs in loop above
    " TODO does following need inequality? (will have to switch direction
    " conditionally)
    if l:boundary[a:dir] ==# l:boundaries[a:winnr][a:dir] | break | endif
    let l:upper = l:boundaries[l:winnr][l:hl ? 'l' : 'j']
    let l:lower = l:boundaries[l:winnr][l:hl ? 'h' : 'k']
    execute l:resize_prefix . l:winnr . 'resize ' . (l:upper - l:lower + 1)
  endfor
endfunction

" Resizes the specified border in the specified direction. hjkl are used to
" specify both border and direction.
function! s:Resize(border, direction)
  let l:horizontal = ['h', 'l']
  let l:vertical = ['j', 'k']
  if s:Contains(l:horizontal, a:border)
        \ && !s:Contains(l:horizontal, a:direction) | return | endif
  if s:Contains(l:vertical, a:border)
        \ && !s:Contains(l:vertical, a:direction) | return | endif
  let l:winnr = winnr()
  if a:border ==# a:direction
    call s:Expand(l:winnr, a:direction)
  elseif winnr(a:border) !=# l:winnr
    call s:Expand(winnr(a:border), a:direction)
  endif
endfunction

" Swaps the content of the active window with the specified window.
" The specified window becomes the active window after swapping.
function! s:Swap(winnr)
  let l:winnr1 = winnr()
  let l:winnr2 = a:winnr
  let l:bufnr1 = winbufnr(l:winnr1)
  let l:bufnr2 = winbufnr(l:winnr2)
  let l:view1 = winsaveview()
  execute l:winnr2 . 'wincmd w'
  let l:view2 = winsaveview()
  execute 'silent hide ' . l:bufnr1 . 'buffer'
  call winrestview(l:view1)
  execute l:winnr1 . 'wincmd w'
  execute 'silent hide ' . l:bufnr2 . 'buffer'
  call winrestview(l:view2)
  execute l:winnr2 . 'wincmd w'
endfunction

function! s:GetChar()
  try
    while 1
      let l:char = getchar()
      if v:mouse_win ># 0 | continue | endif
      if l:char ==# "\<CursorHold>" | continue | endif
      break
    endwhile
  catch
    " E.g., <c-c>
    let l:char = char2nr("\<esc>")
  endtry
  if type(l:char) ==# v:t_number
    let l:char = nr2char(l:char)
  endif
  return l:char
endfunction

" Show a popup window and return the window ID (returning 0 if popups are
" unsupported or the popup could not be displayed).
function! s:OpenPopup(text, highlight, row, col)
  let l:winid = 0
  if s:popupwin
    " A popup cannot start in the last or second to last column. It is placed
    " starting in the third to last column.
    if a:col >=# &columns - 1 | return l:winid | endif
    let l:options = {
          \   'highlight': a:highlight,
          \   'line': a:row,
          \   'col': a:col,
          \ }
    let l:winid = popup_create(a:text, l:options)
  elseif s:floatwin
    if has_key(s:, 'floatwin_avail_bufnrs') && len(s:floatwin_avail_bufnrs) > 0
      let l:buf = s:floatwin_avail_bufnrs[-1]
      call remove(s:floatwin_avail_bufnrs, -1)
    else
      let l:buf = nvim_create_buf(0, 1)
    endif
    call nvim_buf_set_lines(l:buf, 0, -1, 1, [a:text])
    let l:options = {
          \   'relative': 'editor',
          \   'focusable': 0,
          \   'style': 'minimal',
          \   'height': 1,
          \   'width': len(a:text),
          \   'row': a:row - 1,
          \   'col': a:col - 1
          \ }
    let l:winid = nvim_open_win(l:buf, 0, l:options)
    let l:winhighlight = 'Normal:' . a:highlight
    call setwinvar(win_id2win(l:winid), '&winhighlight', l:winhighlight)
  endif
  return l:winid
endfunction

function! s:ClosePopup(winid)
  if s:popupwin
    call popup_close(a:winid)
  elseif s:floatwin
    " Keep track of available floatwin buffer numbers, so they can be reused.
    " This prevents the buffer list numbers from getting high from usage of
    " vim-win. This is list is used by OpenPopup.
    if !has_key(s:, 'floatwin_avail_bufnrs')
      let s:floatwin_avail_bufnrs = []
    endif
    call add(s:floatwin_avail_bufnrs, winbufnr(a:winid))
    " The buffer is not deleted, which is intended since it's reused by
    " OpenPopup.
    call nvim_win_close(a:winid, 1)
  endif
endfunction

" Label windows with winnr and return winids of the labels.
function! s:AddWindowLabels()
  let l:label_winids = []
  let l:win_count = s:WindowCount()
  for l:winnr in range(1, l:win_count)
    if winheight(l:winnr) ==# 0 || winwidth(l:winnr) ==# 0 | continue | endif
    let [l:row, l:col] = win_screenpos(l:winnr)
    let l:is_active = l:winnr ==# winnr()
    let l:label = '[' . l:winnr
    if l:winnr ==# winnr()
      let l:label .= '*'
    endif
    let l:label .= ']'
    let l:label = l:label[:winwidth(l:winnr) - 1]
    let l:highlight = 'WinInactive'
    for l:motion in ['h', 'j', 'k', 'l']
      if l:winnr ==# winnr(l:motion)
        let l:highlight = 'WinNeighbor'
      endif
    endfor
    if l:winnr ==# winnr()
      let l:highlight = 'WinActive'
    endif
    call add(l:label_winids, s:OpenPopup(l:label, l:highlight, l:row, l:col))
  endfor
  return l:label_winids
endfunction

" Remove the specified windows, and empty the list.
function! s:RemoveWindowLabels(label_winids)
  for l:label_winid in a:label_winids
    call s:ClosePopup(l:label_winid)
  endfor
  if len(a:label_winids) ># 0 | call remove(a:label_winids, 0, -1) | endif
endfunction

" Takes a list of lists. Each sublist is comprised of a highlight group name
" and a corresponding string to echo.
function! s:Echo(echo_list)
  redraw
  for [l:hlgroup, l:string] in a:echo_list
    execute 'echohl ' .  l:hlgroup | echon l:string
  endfor
  echohl None
endfunction

" Scans user input for a window number. The first argument specifies the
" initial output (see the documentation for s:Echo), and the optional second
" argument specifies digits that have already been accumulated.
function! s:ScanWinnrDigits(echo_list, ...)
  let l:digits = get(a:, 1, [])[:]
  for l:digit in l:digits
    let l:code = char2nr(l:digit)
    if l:code <# s:code0 || l:code ># s:code9 | return 0 | endif
  endfor
  let l:win_count = s:WindowCount()
  while 1
    if len(l:digits) ># 0
      if l:digits[0] ==# '0' | return 0 | endif
      if l:digits[-1] ==# "\<cr>"
        call remove(l:digits, -1)
        break
      endif
      let l:code = char2nr(l:digits[-1])
      if l:code <# s:code0 || l:code ># s:code9 | return 0 | endif
      if str2nr(join(l:digits + ['0'], '')) ># l:win_count
        break
      endif
      if len(l:digits) ==# len(string(l:win_count))
        return 0
      endif
    endif
    let l:echo_list = a:echo_list + [['None', join(l:digits, '')]]
    call s:Echo(l:echo_list)
    call add(l:digits, s:GetChar())
  endwhile
  let l:winnr = str2nr(join(l:digits, ''))
  return l:winnr <=# l:win_count ? l:winnr : 0
endfunction

" Scans user input for a window number or movement, returning the target. The
" argument specifies the initial output (see the documentation for s:Echo).
function! s:ScanWinnr(echo_list)
  let l:winnr = 0
  call s:Echo(a:echo_list)
  let l:char = s:GetChar()
  let l:code = char2nr(l:char)
  if l:code >=# s:code1 && l:code <=# s:code9
    let l:winnr = s:ScanWinnrDigits(a:echo_list, [l:char])
  elseif s:Contains(s:left_chars, l:char)
    let l:winnr = winnr('h')
  elseif s:Contains(s:down_chars, l:char)
    let l:winnr = winnr('j')
  elseif s:Contains(s:up_chars, l:char)
    let l:winnr = winnr('k')
  elseif s:Contains(s:right_chars, l:char)
    let l:winnr = winnr('l')
  endif
  return l:winnr
endfunction

function! s:ShowHelp()
  let l:help_lines = [
        \   '* Use the hjkl movement keys to change the active window.',
        \   '* Hold <shift> and use the hjkl movement keys to resize the active window.',
        \   '  This shifts the window''s right and bottom borders.',
        \   '* Hold <control> and use the hjkl movement keys to resize the active window.',
        \   '  This shifts the window''s left and top borders.',
        \   '* Enter a window number to change the active window.',
        \   '  Where applicable, press <enter> to submit.',
        \   '* Press s followed by an hjkl movement key or window number, to swap windows.',
        \   '* Press <esc> to leave vim-win or go back (where applicable).',
        \ ]
  let l:echo_list = []
  call add(l:echo_list, ['Title', "vim-win help\n"])
  call add(l:echo_list, ['None', join(l:help_lines, "\n")])
  call add(l:echo_list, ['Question', "\n[Press any key to continue]"])
  call s:Echo(l:echo_list)
  call s:GetChar()
  redraw | echo ''
endfunction

function! s:ShowError(message)
  let l:echo_list = []
  call add(l:echo_list, ['Title', "vim-win error\n"])
  call add(l:echo_list, ['Error', a:message])
  call add(l:echo_list, ['Question', "\n[Press any key to return]"])
  call s:Echo(l:echo_list)
  call s:GetChar()
  redraw | echo ''
endfunction

function! s:ShowWarning(message)
  let l:echo_list = []
  call add(l:echo_list, ['Title', "vim-win warning\n"])
  call add(l:echo_list, ['Error', a:message])
  call add(l:echo_list, ['Question', "\n[Press any key to return]"])
  call s:Echo(l:echo_list)
  call s:GetChar()
  redraw | echo ''
endfunction

function! s:Beep()
  execute "normal \<esc>"
endfunction

" Check vim/nvim version, show corresponding messages, and return a boolean
" indicating whether check succeeded.
function! s:CheckVersion()
  if !has('patch-8.1.1140') && !has('nvim-0.4.0')
    " Vim 8.1.1140 and nvim-0.4.0 updated the winnr function to take a motion
    " character, functionality utilized by vim-win.
    let l:message_lines = [
          \   'vim-win requires vim>=8.1.1140 or nvim>=0.4.0.',
          \   'Use :verbose to check the current version.'
          \ ]
    call s:ShowError(join(l:message_lines, "\n"))
    return 0
  endif
  if !g:win_disable_version_warning && !s:popupwin && !s:floatwin
    let l:message_lines = [
          \   'Full vim-win functionality requires vim>=8.2 or nvim>=0.4.0.',
          \   'Use :verbose to check the current version.',
          \   'Set g:win_disable_version_warning = 1 to disable this warning.'
          \ ]
    call s:ShowWarning(join(l:message_lines, "\n"))
  endif
  return 1
endfunction

function! s:Win()
  if !s:CheckVersion() | return | endif
  let l:label_winids = []
  let l:prompt = [
        \   ['WinStar', '*'],
        \   ['None', ' '],
        \   ['WinPrompt', 'vim-win'],
        \   ['None', '> ']
        \ ]
  while 1
    try
      if &buftype ==# 'nofile' && bufname('%') ==# '[Command Line]'
        call s:Beep()
        call s:ShowError('vim-win does not work with the command-line window')
        break
      endif
      call s:RemoveWindowLabels(l:label_winids)
      let l:label_winids = s:AddWindowLabels()
      call s:Echo(l:prompt)
      let l:char = s:GetChar()
      let l:code = char2nr(l:char)
      if s:Contains(s:esc_chars, l:char)
        break
      elseif l:char ==# '?'
        call s:ShowHelp()
      elseif has_key(g:win_ext_command_map, l:char)
        execute g:win_ext_command_map[l:char]
      elseif l:char ==# 'w'
        wincmd w
      elseif l:char ==# 's'
        let l:swap_prompt = l:prompt + [['None', 's']]
        let l:swap_winnr = s:ScanWinnr(l:swap_prompt)
        if l:swap_winnr !=# 0 | call s:Swap(l:swap_winnr) | endif
      elseif l:code >=# s:code1 && l:code <=# s:code9
        let l:winnr = s:ScanWinnrDigits(l:prompt, [l:char])
        if l:winnr !=# 0 | silent! execute l:winnr . 'wincmd w' | endif
      elseif s:Contains(s:left_chars, l:char)
        wincmd h
      elseif s:Contains(s:down_chars, l:char)
        wincmd j
      elseif s:Contains(s:up_chars, l:char)
        wincmd k
      elseif s:Contains(s:right_chars, l:char)
        wincmd l
      elseif s:Contains(s:shift_left_chars, l:char)
        call s:Resize('l', 'h')
      elseif s:Contains(s:shift_down_chars, l:char)
        call s:Resize('j', 'j')
      elseif s:Contains(s:shift_up_chars, l:char)
        call s:Resize('j', 'k')
      elseif s:Contains(s:shift_right_chars, l:char)
        call s:Resize('l', 'l')
      elseif s:Contains(s:control_left_chars, l:char)
        call s:Resize('h', 'h')
      elseif s:Contains(s:control_down_chars, l:char)
        call s:Resize('k', 'j')
      elseif s:Contains(s:control_up_chars, l:char)
        call s:Resize('k', 'k')
      elseif s:Contains(s:control_right_chars, l:char)
        call s:Resize('h', 'l')
      endif
    catch
      call s:Beep()
      let l:message = v:throwpoint . "\n" . v:exception
      call s:ShowError(l:message)
      break
    endtry
  endwhile
  call s:RemoveWindowLabels(l:label_winids)
  redraw | echo ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
