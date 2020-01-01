" TODO: handle range/count (visual selection)?
" TODO: autoload

" Set g:force_reload_win = 1 to force load.
if !get(g:, 'force_load_win', 0) && exists('g:loaded_win')
  finish
endif
let g:loaded_win = 1

let s:save_cpo = &cpo
set cpo&vim

if !hasmapto('<Plug>WinWin')
  map <leader>w <Plug>WinWin
endif
noremap <script> <Plug>WinWin <SID>Win 
noremap <SID>Win :<c-u>call <SID>Win()<cr>

if !exists(':Win')
  command Win :call s:Win()
endif

let g:win_resize_height = 2
let g:win_resize_width = 2

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
  execute 'hide ' . l:bufnr1 . 'buffer'
  call winrestview(l:view1)
  execute l:winnr1 . 'wincmd w'
  execute 'hide ' . l:bufnr2 . 'buffer'
  call winrestview(l:view2)
  execute l:winnr2 . 'wincmd w'
endfunction

function! s:GetChar()
  try
    let l:char = getchar()
  catch
    let l:char = char2nr("\<esc>")
  endtry
  return l:char
endfunction

" Label windows with winnr and return existing status lines.
function! s:LabelWindows()
  let l:win_id = win_getid()
  let l:num_wins = winnr('$')
  let l:status_lines = {}
  for l:winnr in range(1, l:num_wins)
    execute l:winnr . 'wincmd w'
    let l:status_lines[l:winnr] = &l:statusline
    " TODO: zero padded numbers on status line
    let l:status_line = '[win]\ ' . l:winnr
    execute 'setlocal statusline=' . l:status_line
  endfor
  call win_gotoid(l:win_id)
  return l:status_lines
endfunction

" Revert s:LabelWindows, using existing status lines.
function! s:RevertLabelWindows(status_lines)
  let l:win_id = win_getid()
  for l:winnr in keys(a:status_lines)
    execute l:winnr . 'wincmd w'
    let &l:statusline = a:status_lines[l:winnr]
  endfor
  call win_gotoid(l:win_id)
endfunction

let s:esc_chars = [
      \    char2nr("\<esc>"),
      \    char2nr('q'),
      \    char2nr('Q'),
      \    char2nr("\<c-d>"),
      \ ]
let s:left_chars = [char2nr('h'), "\<left>", "\<bs>"]
let s:down_chars = [char2nr('j'), "\<down>"]
let s:up_chars = [char2nr('k'), "\<up>"]
let s:right_chars = [char2nr('l'), "\<right>", char2nr(' ')]
let s:shift_left_chars = [char2nr('H'), "\<s-left>", "\<s-bs>"]
let s:shift_down_chars = [char2nr('J'), "\<s-down>"]
let s:shift_up_chars = [char2nr('K'), "\<s-up>"]
let s:shift_right_chars = [char2nr('L'), "\<s-right>", "\<s-space>"]
" Don't support <c-c> for closing, since <c-c> is intended for canceling.
" Closing functionality is not currently implemented. It would require
" keeping track of window IDs instead of window numbers (since closing windows
" changes window numbers).
let s:window_close_chars = [char2nr('c'), char2nr('C')]
let s:window_swap_chars = [char2nr('s'), char2nr('S'), char2nr("\<c-s>")]
let s:window_selection_chars = [char2nr('w'), char2nr('W'), char2nr("\<c-w>")]
let s:digit_chars = []
for s:digit in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  call add(s:digit_chars, char2nr(s:digit))
endfor
let s:help_lines = [
      \   '[win] ?',
      \   '',
      \   '* Use the hjkl movement keys to resize the active window.',
      \   '  Holding <shift> modifies which border shifts.',
      \   '* Enter a window number to change the active window.',
      \   '  Window numbers are temporarily shown in status lines.',
      \   '  Where applicable, use leading zero(es) or press <enter> to submit.',
      \   '* Press w followed by an hjkl movement key to change the active window.',
      \   '* Press <esc> to return or go back (where applicable).',
      \   '',
      \   '[Press any key to continue]',
      \ ]
" TODO: Get rid of window selection mode by integrating its functionaliity
" into the main mode.

function s:GetWindowNr()
  " TODO: support windows higher than 9 (failing on 0 or numbers out of
  " range).
  " TODO: update the echo message accordingly to show characters.
  " TODO: support keys like hjkl.
  " TODO: support getting more characters...
  let l:win_id = win_getid()
  let l:char = s:GetChar()
  if index(s:digit_chars, l:char) != -1
    if str2nr(nr2char(l:char)) ># 0
      silent! execute nr2char(l:char) . 'wincmd w'
    endif
  elseif index(s:left_chars + s:shift_left_chars, l:char) !=# -1
    wincmd h
  elseif index(s:down_chars + s:shift_down_chars, l:char) !=# -1
    wincmd j
  elseif index(s:up_chars + s:shift_up_chars, l:char) !=# -1
    wincmd k
  elseif index(s:right_chars + s:shift_right_chars, l:char) !=# -1
    wincmd l
  endif
  let l:winnr = winnr()
  call win_gotoid(l:win_id)
  return l:winnr
endfunction

function! s:Win()
  let l:prompt = '[win] '
  let status_lines = s:LabelWindows()
  while 1
    redraw | echo l:prompt
    let l:char = s:GetChar()
    let l:prompt = '[win] '
    if index(s:esc_chars, l:char) !=# -1
      break
    elseif l:char ==# char2nr('?')
      redraw | echo join(s:help_lines, "\n")
      call s:GetChar()
    elseif index(s:window_swap_chars, l:char) !=# -1
      let l:swap_win = s:GetWindowNr()
      call s:RevertLabelWindows(l:status_lines)
      "execute l:swap_win . 'wincmd x'
      call s:Swap(l:swap_win)
      let status_lines = s:LabelWindows()
    elseif index(s:window_selection_chars, l:char) !=# -1
      redraw | echo '[win] (window selection mode)'
      let l:target = s:GetWindowNr()
      execute l:target . 'wincmd w'
    elseif index(s:left_chars, l:char) !=# -1
      call s:ResizeRightLeft()
    elseif index(s:down_chars, l:char) !=# -1
      call s:ResizeBottomDown()
    elseif index(s:up_chars, l:char) !=# -1
      call s:ResizeBottomUp()
    elseif index(s:right_chars, l:char) !=# -1
      call s:ResizeRightRight()
    elseif index(s:shift_left_chars, l:char) !=# -1
      call s:ResizeLeftLeft()
    elseif index(s:shift_down_chars, l:char) !=# -1
      call s:ResizeTopDown()
    elseif index(s:shift_up_chars, l:char) !=# -1
      call s:ResizeTopUp()
    elseif index(s:shift_right_chars, l:char) !=# -1
      call s:ResizeLeftRight()
    else
      let l:prompt = '[win] (press ? for help) '
    endif
  endwhile
  call s:RevertLabelWindows(l:status_lines)
  redraw | echo ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
