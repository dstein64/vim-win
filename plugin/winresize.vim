" TODO: handle range/count (visual selection)?

let g:winresize_toggle_key = '<leader>r'

let g:winresize_height = 2
let g:winresize_width = 2

" Set 'winwidth' and 'winheight' and return existing values in List.
function! s:SetWinWidthWinHeight(winwidth, winheight)
  let existing = [&winwidth, &winheight]
  let &winwidth = a:winwidth
  let &winheight = a:winheight
  return existing
endfunction

" Moves the bottom border of the active window up (unless on the bottom row).
function! WinResizeBottomUp()
  let l:win_id = win_getid()
  let l:height = winheight(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>j"
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'resize -' . g:winresize_height
    if winheight(l:win_id) ==# l:height
      execute "normal \<c-w>k"
      if l:win_id !=# win_getid()
        call WinResizeBottomUp()
        call win_gotoid(l:win_id)
        execute 'resize -' . g:winresize_height
      endif
    endif
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the bottom border of the active window down (unless on the bottom row).
function! WinResizeBottomDown()
  let l:win_id = win_getid()
  let l:row = win_screenpos(l:win_id)[0]
  let l:restore = winrestcmd()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>j"
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'resize +' . g:winresize_height
  endif
  if win_screenpos(l:win_id)[0] <# l:row | execute l:restore | endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the top border of the active window up (unless on the top row).
function! WinResizeTopUp()
  let l:win_id = win_getid()
  let l:height = winheight(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>k"
  if l:win_id !=# win_getid()
    execute 'resize -' . g:winresize_height
    if winheight(l:win_id) ==# l:height
      call WinResizeTopUp()
      execute 'resize -' . g:winresize_height
    endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the top border of the active window down (unless on the top row).
function! WinResizeTopDown()
  let l:win_id = win_getid()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>k"
  if l:win_id !=# win_getid()
    let l:win_id2 = win_getid()
    let l:row = win_screenpos(l:win_id2)[0]
    let l:restore = winrestcmd()
    execute 'resize +' . g:winresize_height
    if win_screenpos(l:win_id2)[0] <# l:row | execute l:restore | endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the right border of the active window to the left (unless on the rightmost column).
function! WinResizeRightLeft()
  let l:win_id = win_getid()
  let l:width = winwidth(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>l"
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'vertical resize -' . g:winresize_width
    if winwidth(l:win_id) ==# l:width
      execute "normal \<c-w>h"
      if l:win_id !=# win_getid()
        call WinResizeRightLeft()
        call win_gotoid(l:win_id)
        execute 'vertical resize -' . g:winresize_width
      endif
    endif
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the right border of the active window to the left (unless on the rightmost column).
function! WinResizeRightRight()
  let l:win_id = win_getid()
  let l:col = win_screenpos(l:win_id)[1]
  let l:restore = winrestcmd()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>l"
  if l:win_id !=# win_getid()
    call win_gotoid(l:win_id)
    execute 'vertical resize +' . g:winresize_width
  endif
  if win_screenpos(l:win_id)[1] <# l:col | execute l:restore | endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the left border of the active window to the left (unless on the leftmost column).
function! WinResizeLeftLeft()
  let l:win_id = win_getid()
  let l:width = winwidth(l:win_id)
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>h"
  if l:win_id !=# win_getid()
    execute 'vertical resize -' . g:winresize_width
    if winwidth(l:win_id) ==# l:width
      call WinResizeLeftLeft()
      execute 'vertical resize -' . g:winresize_width
    endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
endfunction

" Moves the left border of the active window to the right (unless on the leftmost column).
function! WinResizeLeftRight()
  let l:win_id = win_getid()
  let [l:winwidth, l:winheight] = s:SetWinWidthWinHeight(1, 1)
  execute "normal \<c-w>h"
  if l:win_id !=# win_getid()
    let l:win_id2 = win_getid()
    let l:col = win_screenpos(l:win_id2)[1]
    let l:restore = winrestcmd()
    execute 'vertical resize +' . g:winresize_width
    if win_screenpos(l:win_id2)[1] <# l:col | execute l:restore | endif
    call win_gotoid(l:win_id)
  endif
  call s:SetWinWidthWinHeight(l:winwidth, l:winheight)
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
  let l:winnr = 1
  let l:status_lines = {}
  while l:winnr <= l:num_wins
    execute l:winnr . 'wincmd w'
    :let l:status_lines[l:winnr] = &l:statusline
    " TODO: better status line
    execute 'setlocal statusline=' . l:winnr
    let l:winnr += 1
  endwhile
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
let s:window_selection_chars = [char2nr('w'), char2nr('W'), char2nr("\<c-w>")]
let s:digit_chars = []
for s:digit in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  call add(s:digit_chars, char2nr(s:digit))
endfor
let s:help_lines = [
      \   '[winresize] (help)',
      \   '',
      \   'Use the hjkl movement keys to resize windows.',
      \   'Holding <shift> modifies which border shifts.',
      \   'Press w to enter window selection mode.',
      \   'Press <esc> to return or go back (where applicable).',
      \   '',
      \   '[Press any key to continue]',
      \ ]
" TODO: Add window selection mode help documentation
" TODO: Or possibly get rid of window selection mode by integrating its
" functionaliity into the main mode.
" TODO: Change defaults so that hjkl (without <shift>) move the bottom and
" right borders.

function! WinResize()
  while 1
    redraw | echo '[winresize]'
    let l:char = s:GetChar()
    if index(s:esc_chars, l:char) !=# -1
      break
    elseif l:char ==# char2nr('?')
      redraw | echo join(s:help_lines, "\n")
      call s:GetChar()
    elseif index(s:window_selection_chars, l:char) !=# -1
      let status_lines = s:LabelWindows()
      redraw | echo '[winresize] (window selection mode)'
      let l:char2 = s:GetChar()
      if index(s:digit_chars, l:char2) != -1
        " TODO: support windows higher than 9 (failiing on 0 or numbers out of
        " range.
        if str2nr(nr2char(l:char2)) ># 0
          silent! execute nr2char(l:char2) . 'wincmd w'
        endif
      elseif index(s:left_chars + s:shift_left_chars, l:char2) !=# -1
        execute "normal \<c-w>h"
      elseif index(s:down_chars + s:shift_down_chars, l:char2) !=# -1
        execute "normal \<c-w>j"
      elseif index(s:up_chars + s:shift_up_chars, l:char2) !=# -1
        execute "normal \<c-w>k"
      elseif index(s:right_chars + s:shift_right_chars, l:char2) !=# -1
        execute "normal \<c-w>l"
      endif
      call s:RevertLabelWindows(l:status_lines)
    elseif index(s:left_chars, l:char) !=# -1
      call WinResizeLeftLeft()
    elseif index(s:down_chars, l:char) !=# -1
      call WinResizeTopDown()
    elseif index(s:up_chars, l:char) !=# -1
      call WinResizeTopUp()
    elseif index(s:right_chars, l:char) !=# -1
      call WinResizeLeftRight()
    elseif index(s:shift_left_chars, l:char) !=# -1
      call WinResizeRightLeft()
    elseif index(s:shift_down_chars, l:char) !=# -1
      call WinResizeBottomDown()
    elseif index(s:shift_up_chars, l:char) !=# -1
      call WinResizeBottomUp()
    elseif index(s:shift_right_chars, l:char) !=# -1
      call WinResizeRightRight()
    endif
  endwhile
  redraw | echo ''
endfunction
command! WinResize :call WinResize()

noremap <silent> <leader>r :WinResize<cr>
