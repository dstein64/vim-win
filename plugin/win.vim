" TODO: handle range/count (visual selection)?
" TODO: autoload
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

let g:win_resize_height = 2
let g:win_resize_width = 2

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

" Set 'winwidth' and 'winheight' and return existing values in List.
function! s:SetWinWidthWinHeight(winwidth, winheight)
  let l:existing = [&winwidth, &winheight]
  let &winwidth = a:winwidth
  let &winheight = a:winheight
  return l:existing
endfunction

" Moves the bottom border of the active window up (unless on the bottom row).
function! s:ResizeBottomUp()
  let l:win_id = win_getid()
  let l:height = winheight(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd j
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'resize -' . g:win_resize_height
    if winheight(l:win_id) ==# l:height
      wincmd k
      if l:win_id !=# win_getid()
        call s:ResizeBottomUp()
        call win_gotoid(l:win_id)
        execute 'resize -' . g:win_resize_height
      endif
    endif
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the bottom border of the active window down (unless on the bottom row).
function! s:ResizeBottomDown()
  let l:win_id = win_getid()
  let l:row = win_screenpos(l:win_id)[0]
  let l:restore = winrestcmd()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd j
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'resize +' . g:win_resize_height
  endif
  if win_screenpos(l:win_id)[0] <# l:row | execute l:restore | endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the top border of the active window up (unless on the top row).
function! s:ResizeTopUp()
  let l:win_id = win_getid()
  let l:height = winheight(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd k
  if l:win_id !=# win_getid()
    execute 'resize -' . g:win_resize_height
    if winheight(l:win_id) ==# l:height
      call s:ResizeTopUp()
      execute 'resize -' . g:win_resize_height
    endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the top border of the active window down (unless on the top row).
function! s:ResizeTopDown()
  let l:win_id = win_getid()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd k
  if l:win_id !=# win_getid()
    let l:win_id2 = win_getid()
    let l:row = win_screenpos(l:win_id2)[0]
    let l:restore = winrestcmd()
    execute 'resize +' . g:win_resize_height
    if win_screenpos(l:win_id2)[0] <# l:row | execute l:restore | endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the right border of the active window to the left (unless on the rightmost column).
function! s:ResizeRightLeft()
  let l:win_id = win_getid()
  let l:width = winwidth(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd l
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'vertical resize -' . g:win_resize_width
    if winwidth(l:win_id) ==# l:width
      wincmd h
      if l:win_id !=# win_getid()
        call s:ResizeRightLeft()
        call win_gotoid(l:win_id)
        execute 'vertical resize -' . g:win_resize_width
      endif
    endif
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the right border of the active window to the left (unless on the rightmost column).
function! s:ResizeRightRight()
  let l:win_id = win_getid()
  let l:col = win_screenpos(l:win_id)[1]
  let l:restore = winrestcmd()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd l
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'vertical resize +' . g:win_resize_width
  endif
  if win_screenpos(l:win_id)[1] <# l:col | execute l:restore | endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the left border of the active window to the left (unless on the leftmost column).
function! s:ResizeLeftLeft()
  let l:win_id = win_getid()
  let l:width = winwidth(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd h
  if l:win_id !=# win_getid()
    execute 'vertical resize -' . g:win_resize_width
    if winwidth(l:win_id) ==# l:width
      call s:ResizeLeftLeft()
      execute 'vertical resize -' . g:win_resize_width
    endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the left border of the active window to the right (unless on the leftmost column).
function! s:ResizeLeftRight()
  let l:win_id = win_getid()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  wincmd h
  if l:win_id !=# win_getid()
    let l:win_id2 = win_getid()
    let l:col = win_screenpos(l:win_id2)[1]
    let l:restore = winrestcmd()
    execute 'vertical resize +' . g:win_resize_width
    if win_screenpos(l:win_id2)[1] <# l:col | execute l:restore | endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
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
    " Vim 8.1.1140 updated the winnr function to take a motion character. Use
    " a try block since this is not supported in older versions of Vim.
    try
      for l:motion in ['h', 'j', 'k', 'l']
        if l:winnr ==# winnr(l:motion)
          let l:highlight = 'WinNeighbor'
        endif
      endfor
    catch
    endtry
    if l:winnr ==# winnr()
      let l:highlight = 'WinActive'
    endif
    if s:popupwin
      " When there are 2 or less columns in a rightmost window, popup text
      " overlaps the vertical separator line.
      if l:col >=# &columns - 1 | continue | endif
      let l:options = {
            \   'highlight': l:highlight,
            \   'line': l:row,
            \   'col': l:col,
            \ }
      let l:label_winid = popup_create(l:label, l:options)
      call add(l:label_winids, l:label_winid)
    elseif s:floatwin
      " Keep track of floatwin buffer numbers, so they can be reused. This prevents
      " the buffer list numbers from getting high from usage of vim-win.
      if !has_key(s:, 'floatwin_bufnrs')
        let s:floatwin_bufnrs = []
      endif
      if l:winnr ># len(s:floatwin_bufnrs)
        call add(s:floatwin_bufnrs, nvim_create_buf(0, 1))
      endif
      let l:buf = s:floatwin_bufnrs[l:winnr - 1]
      call nvim_buf_set_lines(l:buf, 0, -1, 1, [l:label])
      let l:options = {
            \   'relative': 'win',
            \   'style': 'minimal',
            \   'win': win_getid(l:winnr),
            \   'height': 1,
            \   'width': len(l:label),
            \   'row': 0,
            \   'col': 0
            \ }
      let l:label_winid = nvim_open_win(l:buf, 0, l:options)
      let l:winhighlight = 'NormalFloat:' . l:highlight
      call setwinvar(win_id2win(l:label_winid), '&winhighlight', l:winhighlight)
      call add(l:label_winids, l:label_winid)
    endif
  endfor
  return l:label_winids
endfunction

" Remove the specified windows, and empty the list.
function! s:RemoveWindowLabels(label_winids)
  for l:label_winid in a:label_winids
    if s:popupwin
      call popup_close(l:label_winid)
    elseif s:floatwin
      " The buffer is not deleted, which is intended since it's reused above in
      " s:AddWindowLabels.
      call nvim_win_close(l:label_winid, 1)
    endif
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
  elseif index(s:left_chars, l:char) !=# -1
    let l:winnr = winnr('h')
  elseif index(s:down_chars, l:char) !=# -1
    let l:winnr = winnr('j')
  elseif index(s:up_chars, l:char) !=# -1
    let l:winnr = winnr('k')
  elseif index(s:right_chars, l:char) !=# -1
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
  call add(l:echo_list, ['Question', "\n[Press any key to return]"])
  call s:Echo(l:echo_list)
  call s:GetChar()
endfunction

function! s:ShowError(message)
  let l:echo_list = []
  call add(l:echo_list, ['Title', "vim-win error\n"])
  call add(l:echo_list, ['Error', a:message])
  call add(l:echo_list, ['Question', "\n[Press any key to return]"])
  call s:Echo(l:echo_list)
  call s:GetChar()
endfunction

function! s:Win()
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
        call s:ShowError('vim-win does not work with the command-line window')
        break
      endif
      call s:RemoveWindowLabels(l:label_winids)
      let l:label_winids = s:AddWindowLabels()
      call s:Echo(l:prompt)
      let l:char = s:GetChar()
      let l:code = char2nr(l:char)
      if index(s:esc_chars, l:char) !=# -1
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
      elseif index(s:left_chars, l:char) !=# -1
        wincmd h
      elseif index(s:down_chars, l:char) !=# -1
        wincmd j
      elseif index(s:up_chars, l:char) !=# -1
        wincmd k
      elseif index(s:right_chars, l:char) !=# -1
        wincmd l
      elseif index(s:shift_left_chars, l:char) !=# -1
        call s:ResizeRightLeft()
      elseif index(s:shift_down_chars, l:char) !=# -1
        call s:ResizeBottomDown()
      elseif index(s:shift_up_chars, l:char) !=# -1
        call s:ResizeBottomUp()
      elseif index(s:shift_right_chars, l:char) !=# -1
        call s:ResizeRightRight()
      elseif index(s:control_left_chars, l:char) !=# -1
        call s:ResizeLeftLeft()
      elseif index(s:control_down_chars, l:char) !=# -1
        call s:ResizeTopDown()
      elseif index(s:control_up_chars, l:char) !=# -1
        call s:ResizeTopUp()
      elseif index(s:control_right_chars, l:char) !=# -1
        call s:ResizeLeftRight()
      endif
    catch
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
