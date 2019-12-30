" TODO: handle range/count (visual selection)?

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


command! WinResizeBottomUp :call WinResizeBottomUp()
noremap <silent> <up> :WinResizeBottomUp<cr>

command! WinResizeBottomDown :call WinResizeBottomDown()
noremap <silent> <down> :WinResizeBottomDown<cr>

command! WinResizeTopUp :call WinResizeTopUp()
noremap <silent> <up> :WinResizeTopUp<cr>

command! WinResizeTopDown :call WinResizeTopDown()
noremap <silent> <down> :WinResizeTopDown<cr>

command! WinResizeRightLeft :call WinResizeRightLeft()
noremap <silent> <left> :WinResizeRightLeft<cr>

command! WinResizeRightRight :call WinResizeRightRight()
noremap <silent> <right> :WinResizeRightRight<cr>

command! WinResizeLeftLeft :call WinResizeLeftLeft()
noremap <silent> <left> :WinResizeLeftLeft<cr>

command! WinResizeLeftRight :call WinResizeLeftRight()
noremap <silent> <right> :WinResizeLeftRight<cr>

