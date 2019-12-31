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

function! WinResize()
  let l:esc_chars = [char2nr("\<esc>"), char2nr('q'), char2nr('Q')]
  let l:left_chars = [char2nr('h'), "\<left>", "\<bs>"]
  let l:down_chars = [char2nr('j'), "\<down>"]
  let l:up_chars = [char2nr('k'), "\<up>"]
  let l:right_chars = [char2nr('l'), "\<right>", char2nr(' ')]
  let l:shift_left_chars = [char2nr('H'), "\<s-left>", "\<s-bs>"]
  let l:shift_down_chars = [char2nr('J'), "\<s-down>"]
  let l:shift_up_chars = [char2nr('K'), "\<s-up>"]
  let l:shift_right_chars = [char2nr('L'), "\<s-right>", "\<s-space>"]
  while 1
    redraw | echo '<winresize>'
    let l:char = s:GetChar()
    if index(l:esc_chars, l:char) !=# -1
      break
    elseif l:char ==# char2nr('?')
      " TODO: real help
      echo 'HELP'
    elseif l:char ==# char2nr('w') || l:char ==# char2nr('W')
      redraw | echo '<winresize> (change active window)'
      let l:char2 = s:GetChar()
      if index(l:left_chars + l:shift_left_chars, l:char2) !=# -1
        execute "normal \<c-w>h"
      elseif index(l:down_chars + l:shift_down_chars, l:char2) !=# -1
        execute "normal \<c-w>j"
      elseif index(l:up_chars + l:shift_up_chars, l:char2) !=# -1
        execute "normal \<c-w>k"
      elseif index(l:right_chars + l:shift_right_chars, l:char2) !=# -1
        execute "normal \<c-w>l"
      endif
    elseif index(l:left_chars, l:char) !=# -1
      call WinResizeLeftLeft()
    elseif index(l:down_chars, l:char) !=# -1
      call WinResizeTopDown()
    elseif index(l:up_chars, l:char) !=# -1
      call WinResizeTopUp()
    elseif index(l:right_chars, l:char) !=# -1
      call WinResizeLeftRight()
    elseif index(l:shift_left_chars, l:char) !=# -1
      call WinResizeRightLeft()
    elseif index(l:shift_down_chars, l:char) !=# -1
      call WinResizeBottomDown()
    elseif index(l:shift_up_chars, l:char) !=# -1
      call WinResizeBottomUp()
    elseif index(l:shift_right_chars, l:char) !=# -1
      call WinResizeRightRight()
    endif
  endwhile
  redraw | echo ''
endfunction
command! WinResize :call WinResize()

noremap <silent> <leader>r :WinResize<cr>
