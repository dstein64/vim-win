" TODO: handle range/count (visual selection)?
" TODO: autoload
" TODO: alternative approach for resizing windows (current doesn't always
" work properly)..
" TODO: highlight status line? (change color when error?)

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

let s:popupwin = has('popupwin')
let s:floatwin = exists('*nvim_open_win') && exists('*nvim_win_close')

" Set 'winwidth' and 'winheight' and return existing values in List.
function! s:SetWinWidthWinHeight(winwidth, winheight)
  let existing = [&winwidth, &winheight]
  let &winwidth = a:winwidth
  let &winheight = a:winheight
  return existing
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
    let l:char = getchar()
  catch
    let l:char = char2nr("\<esc>")
  endtry
  if type(l:char) ==# v:t_number
    let l:char = nr2char(l:char)
  endif
  return l:char
endfunction

" Label windows with winnr and return winids of the labels.
function! s:AddWindowLabels()
  let l:label_winids = []
  let l:num_wins = winnr('$')
  for l:winnr in range(1, l:num_wins)
    if winheight(l:winnr) ==# 0 || winwidth(l:winnr) ==# 0 | continue | endif
    let [l:row, l:col] = win_screenpos(l:winnr)
    let l:is_active = l:winnr ==# winnr()
    let l:label = '[' . l:winnr
    if l:winnr ==# winnr()
      let l:label .= '*'
    endif
    let l:label .= ']'
    let l:label = l:label[:winwidth(l:winnr) - 1]
    let l:highlight = l:winnr ==# winnr() ? 'DiffAdd' : 'Todo'
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
      " the buffer list numbers from getting high from usage of win.vim.
      if !has_key(s:, 'floatwin_bufnrs')
        let s:floatwin_bufnrs = []
      endif
      if l:winnr > len(s:floatwin_bufnrs)
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
      let l:winhighlight = 'Normal:' . l:highlight
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
      " The buffer is not deleted, which is desired since it's reused above in
      " s:AddWindowLabels.
      call nvim_win_close(l:label_winid, 1)
    endif
  endfor
  if len(a:label_winids) > 0 | call remove(a:label_winids, 0, -1) | endif
endfunction

let s:esc_chars = ["\<esc>", 'q']
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
let s:digit_chars = split('0123456789', '\zs')
let s:help_lines = [
      \   '* Use the hjkl movement keys to change the active window.',
      \   '* Hold <shift> and use the hjkl movement keys to resize the active window.',
      \   '  This shifts the right and bottom borders.',
      \   '* Hold <control> and use the hjkl movement keys to resize the active window.',
      \   '  This shifts the left and top borders.',
      \   '* Enter a window number to change the active window.',
      \   '  Where applicable, use leading zero(es) or press <enter> to submit.',
      \   '* Press s followed by an hjkl movement key or window number, to swap windows.',
      \   '* Press <esc> to return or go back (where applicable).',
      \ ]

function s:GetWindowNr()
  " TODO: support windows higher than 9 (failing on 0 or numbers out of
  " range).
  " TODO: update the echo message accordingly to show characters.
  let l:winnr = winnr()
  let l:char = s:GetChar()
  if l:char !=# '0' && index(s:digit_chars, l:char) != -1
    let l:winnr = str2nr(l:char)
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

" TODO: update docs
" Takes a list of lists. Each sublist is comprised of a highlight group name
" and a corresponding string. Returns a command for echoing.
function! s:Echo(echo_list)
  redraw
  for [l:hlgroup, l:string] in a:echo_list
    execute 'echohl ' .  l:hlgroup | echon l:string
  endfor
  echohl None
endfunction

function! s:Win()
  let l:label_winids = []
  while 1
    call s:RemoveWindowLabels(l:label_winids)
    let l:label_winids = s:AddWindowLabels()
    let l:prompt_echo_list = [['ModeMsg', 'win.vim'], ['None', '> ']]
    call s:Echo(l:prompt_echo_list)
    let l:char = s:GetChar()
    if index(s:esc_chars, l:char) !=# -1
      break
    elseif l:char ==# '?'
      let l:help_echo_list = []
      call add(l:help_echo_list, ['Title', "win.vim help\n"])
      call add(l:help_echo_list, ['None', join(s:help_lines, "\n")])
      call add(l:help_echo_list, ['Question', "\n[Press any key to continue]"])
      call s:Echo(l:help_echo_list)
      call s:GetChar()
    elseif l:char ==# 'w'
      wincmd w
    elseif l:char ==# 's'
      call add(l:prompt_echo_list, ['None', 's'])
      call s:Echo(l:prompt_echo_list)
      let l:swap_winnr = s:GetWindowNr()
      call s:Swap(l:swap_winnr)
    elseif l:char != '0' && index(s:digit_chars, l:char) !=# -1
      continue
      while 1
        call add(l:prompt_echo_list, ['None', nr2char(l:char)])
        call s:Echo(l:prompt_echo_list)
      endwhile
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
  endwhile
  call s:RemoveWindowLabels(l:label_winids)
  redraw | echo ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
