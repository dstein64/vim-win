" TODO: Modeling the main loop with a state machine could permit a cleaner and
" more robust implementation.

" On Vim, check for popup_create/popup_close instead of +popupwin, since there
" were versions of Vim (8.1.2269) that had had those functions, but didn't yet
" specify a +popupwin feature.
let s:popupwin = exists('*popup_create') && exists('*popup_close')
let s:floatwin = exists('*nvim_open_win') && exists('*nvim_win_close')

let s:winmove = exists('*win_move_separator') && exists('*win_move_statusline')

let s:code0 = char2nr('0')
let s:code1 = char2nr('1')
let s:code9 = char2nr('9')
let s:code_a = char2nr('a')
let s:code_z = char2nr('z')
let s:esc_chars = ["\<esc>"]
let s:left_chars = ['h', "\<left>"]
let s:down_chars = ['j', "\<down>"]
let s:up_chars = ['k', "\<up>"]
let s:right_chars = ['l', "\<right>"]
let s:shift_left_chars = ['H', "\<s-left>"]
let s:ctrl_left_chars = ["\<c-h>", "\<c-left>"]
let s:shift_down_chars = ['J', "\<s-down>"]
let s:ctrl_down_chars = ["\<c-j>", "\<c-down>"]
let s:shift_up_chars = ['K', "\<s-up>"]
let s:ctrl_up_chars = ["\<c-k>", "\<c-up>"]
let s:shift_right_chars = ['L', "\<s-right>"]
let s:ctrl_right_chars = ["\<c-l>", "\<c-right>"]

let s:resize_chars = s:shift_left_chars + s:ctrl_left_chars
      \ + s:shift_down_chars + s:ctrl_down_chars
      \ + s:shift_up_chars + s:ctrl_up_chars
      \ + s:shift_right_chars + s:ctrl_right_chars

let s:label_winids = []

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
  for l:winnr in range(1, winnr('$'))
    let l:config = nvim_win_get_config(win_getid(l:winnr))
    if !get(l:config, 'external', 0) && get(l:config, 'relative', '') ==# ''
      let l:win_count += 1
    endif
  endfor
  return l:win_count
endfunction

function! s:Contains(list, element)
  return index(a:list, a:element) !=# -1
endfunction

" Swaps the buffer of the active window with the buffer of the specified
" window. Only the buffers are swapped (i.e., local options, mappings,
" abbreviations, etc., are not transferred).
function! s:Swap(winnr)
  let l:winnr1 = winnr()
  let l:winnr2 = a:winnr
  let l:winid1 = win_getid(l:winnr1)
  let l:winid2 = win_getid(l:winnr2)
  let l:bufnr1 = winbufnr(l:winnr1)
  let l:bufnr2 = winbufnr(l:winnr2)
  let l:view1 = winsaveview()
  " The following commands are executed in the context of window 2.
  let l:commands = [
        \   'let l:bufhidden2 = &l:bufhidden',
        \   'setlocal bufhidden=hide',
        \   'let l:view2 = winsaveview()',
        \   'noautocmd silent ' . l:bufnr1 . 'buffer',
        \   'call winrestview(l:view1)'
        \ ]
  " The following handling can't be factored out to e.g., s:WinExecute,
  " since it would not be possible to set l:view2 scoped in *this* function.
  if exists('*win_execute')
    for l:command in l:commands
      call win_execute(l:winid2, l:command)
    endfor
  else
    " vim<8.1.1418 and neovim (as of 0.4.3) do not have the win_execute
    " function.
    let l:eventignore = &eventignore
    try
      let &eventignore = 'all'
      call win_gotoid(l:winid2)
      for l:command in l:commands
        execute l:command
      endfor
      call win_gotoid(l:winid1)
    finally
      let &eventignore = l:eventignore
    endtry
  endif
  execute 'silent ' . l:bufnr2 . 'buffer'
  call winrestview(l:view2)
  let &l:bufhidden = l:bufhidden2
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
  " On Cygwin, pressing <c-c> during getchar() does not raise "Vim:Interrupt",
  " so it would still be <c-c> at this point. Convert to <esc>.
  if l:char ==# "\<c-c>"
    let l:char = "\<esc>"
  endif
  return l:char
endfunction

" Show a popup window and return the window ID (returning 0 if popups are
" unsupported or the popup could not be displayed).
function! s:OpenPopup(text, highlight, row, col)
  let l:winid = 0
  if s:popupwin
    if a:col >=# (&columns - 1) && !has('patch-8.2.0096')
      " A popup cannot start in the last or second-to-last column prior to
      " patch-8.2.0096. It is placed starting in the third-to-last column.
      " Issue #5447 (https://github.com/vim/vim/issues/5447)
      return l:winid
    endif
    let l:options = {
          \   'highlight': a:highlight,
          \   'line': a:row,
          \   'col': a:col,
          \ }
    let l:winid = popup_create(a:text, l:options)
    let l:buf = winbufnr(l:winid)
    call setbufvar(l:buf, '&matchpairs', '')
  elseif s:floatwin
    if has_key(s:, 'floatwin_avail_bufnrs') && !empty(s:floatwin_avail_bufnrs)
      let l:buf = remove(s:floatwin_avail_bufnrs, -1)
    else
      let l:buf = nvim_create_buf(0, 1)
      call nvim_buf_set_option(l:buf, 'matchpairs', '')
    endif
    call nvim_buf_set_lines(l:buf, 0, -1, 1, [a:text])
    let l:options = {
          \   'relative': 'editor',
          \   'focusable': 0,
          \   'style': 'minimal',
          \   'height': 1,
          \   'width': len(a:text),
          \   'row': a:row - 1,
          \   'col': a:col - 1,
          \   'border': 'none',
          \ }
    let l:winid = nvim_open_win(l:buf, 0, l:options)
    let l:winhighlight = 'Normal:' . a:highlight
    call setwinvar(win_id2win(l:winid), '&winhighlight', l:winhighlight)
  endif
  return l:winid
endfunction

function! s:ClosePopup(winid)
  " The popup may no longer exist. #2
  if empty(getwininfo(a:winid))
    return
  endif
  if s:popupwin
    call popup_close(a:winid)
  elseif s:floatwin
    " Keep track of available floatwin buffer numbers, so they can be reused.
    " This prevents the buffer list numbers from getting high from usage of
    " vim-win. This list is used by OpenPopup.
    if !has_key(s:, 'floatwin_avail_bufnrs')
      let s:floatwin_avail_bufnrs = []
    endif
    call add(s:floatwin_avail_bufnrs, winbufnr(a:winid))
    " The buffer is not deleted, which is intended since it's reused by
    " OpenPopup.
    call nvim_win_close(a:winid, 1)
  endif
endfunction

" Convert a number to bijective base-26. This is the same number system that's
" used for the columns in Microsoft Excel.
" https://en.wikipedia.org/wiki/Bijective_numeration#The_bijective_base-26_system
" WARN: There is no error checking for a valid input.
function! s:ToBijective26(num)
  let l:num = a:num
  let l:chars = 'abcdefghijklmnopqrstuvwxyz'
  let l:result = []
  while l:num !=# 0
    call add(l:result, l:chars[(l:num - 1) % 26])
    let l:num = (l:num - 1) / 26
  endwhile
  call reverse(l:result)
  return join(l:result, '')
endfunction

" WARN: There is no error checking for a valid input.
function! s:FromBijective26(str)
  let l:num = 0
  let l:multiplier = 1
  for l:c in split(reverse(copy(a:str)), '\zs')
    let l:x = char2nr(l:c) - s:code_a + 1
    let l:num += l:x * l:multiplier
    let l:multiplier *= 26
  endfor
  return l:num
endfunction

function! s:RemoveWindowLabels()
  for l:label_winid in s:label_winids
    call s:ClosePopup(l:label_winid)
  endfor
  if len(s:label_winids) ># 0 | call remove(s:label_winids, 0, -1) | endif
endfunction

" Label windows with winnr and return winids of the labels. The optional
" argument specifies whether alphabetic labels (bijective base-26) will be
" used.
function! s:LabelWindows(...)
  let l:alpha = get(a:, 1, v:false)
  call s:RemoveWindowLabels()
  let l:win_count = s:WindowCount()
  for l:winnr in range(1, l:win_count)
    if winheight(l:winnr) ==# 0 || winwidth(l:winnr) ==# 0 | continue | endif
    let [l:row, l:col] = win_screenpos(l:winnr)
    let l:is_active = l:winnr ==# winnr()
    let l:label = '['
    let l:label .= l:alpha ? s:ToBijective26(l:winnr) : l:winnr
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
    let l:label_winid = s:OpenPopup(l:label, l:highlight, l:row, l:col)
    if l:label_winid !=# 0 | call add(s:label_winids, l:label_winid) | endif
  endfor
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
    endif
    let l:echo_list = a:echo_list + [['None', join(l:digits, '')]]
    call s:Echo(l:echo_list)
    call add(l:digits, s:GetChar())
  endwhile
  let l:winnr = str2nr(join(l:digits, ''))
  return l:winnr <=# l:win_count ? l:winnr : 0
endfunction

" Scans user input for an alphabetic window string (labeled with bijective
" base 26), and return the corresponding window number. The argument specifies
" the initial output (see the documentation for s:Echo).
function! s:ScanWinAlpha(echo_list)
  let l:letters = []
  let l:win_count = s:WindowCount()
  while 1
    if len(l:letters) ># 0
      if l:letters[-1] ==# "\<cr>"
        call remove(l:letters, -1)
        break
      endif
      let l:code = char2nr(l:letters[-1])
      if l:code <# s:code_a || l:code ># s:code_z | return 0 | endif
      if s:FromBijective26(join(l:letters + ['a'], '')) ># l:win_count
        break
      endif
    endif
    let l:echo_list = a:echo_list + [['None', join(l:letters, '')]]
    call s:Echo(l:echo_list)
    call add(l:letters, tolower(s:GetChar()))
  endwhile
  let l:winnr = s:FromBijective26(join(l:letters, ''))
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
  elseif l:char ==# 'g'
    call s:LabelWindows(v:true)
    let l:winnr = s:ScanWinAlpha(a:echo_list + [['None', l:char]])
  endif
  return l:winnr
endfunction

function! s:ShowHelp()
  let l:help_lines = [
        \   '* Arrows or `hjkl` keys are used for movement.',
        \   '* There are various ways to change the active window.',
        \   '  - Use movement keys to move to neighboring windows.',
        \   '  - Enter a window number (where applicable, press `<enter>` to submit).',
        \   '  - Use `w` or `W` to sequentially move to the next or previous window.',
        \   '  - Use `w` or `W` to sequentially move to the next or previous window.',
        \   '  - Press `g` to start letter mode, followed by entering a window letter.',
        \ ]
  if s:winmove
    call extend(l:help_lines, [
          \   '* Hold `<shift>` and use movement keys to resize the active window.',
          \   '  - Left and right movements shift the right border.',
          \   '  - Down and up movements shift the bottom border.',
          \   '* Hold `<control>` and use movement keys to resize the active window.',
          \   '  - Left and right movements shift the left border.',
          \   '  - Down and up movements shift the top border.',
          \ ])
  else
    call extend(l:help_lines, [
          \   '* Hold `<shift>` and use movement keys to resize the active window.',
          \   '  - Left movements decrease width and right movements increase width.',
          \   '  - Down movements decrease height and up movements increase height.',
          \ ])
  endif
  call extend(l:help_lines, [
        \   '* Press `s` or `S` followed by a movement key or window number, to swap'
        \   . ' buffers.',
        \   '  - The active window changes with `s` and is retained with `S`.',
        \   '  - Rather than using a movement key or window number for swapping, a'
        \   . ' window',
        \   '    letter can be used by entering letter mode with `g`, after pressing'
        \   . ' `s` or `S`.',
        \   '* Press `<esc>` to leave vim-win (or go back, where applicable).',
        \ ])
  let l:echo_list = []
  call add(l:echo_list, ['Title', "vim-win help\n"])
  let l:help_text = join(l:help_lines, "\n")
  " The state is 0 for text outside backticks, and 1 inside backticks.
  let l:state = 0
  let l:highlight_lookup = ['None', 'SpecialKey']
  for l:char in split(l:help_text, '\zs')
    if l:char ==# '`'
      let l:state = !l:state
      continue
    endif
    call add(l:echo_list, [l:highlight_lookup[l:state], l:char])
  endfor
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
  execute "normal! \<esc>"
endfunction

" Check vim/nvim version, show corresponding messages, and return a boolean
" indicating whether check succeeded.
function! s:CheckVersion()
  if !has('patch-8.1.1140') && !has('nvim-0.4.0')
    " Vim 8.1.1140 and nvim-0.4.0 updated the winnr function to take a motion
    " character, functionality utilized by vim-win.
    let l:message_lines = [
          \   'vim-win requires vim>=8.1.1140 or nvim>=0.4.0.',
          \   'Use :version to check the current version.'
          \ ]
    call s:ShowError(join(l:message_lines, "\n"))
    return 0
  endif
  if !g:win_disable_version_warning && !s:popupwin && !s:floatwin
    let l:message_lines = [
          \   'Full vim-win functionality requires vim>=8.1.2269 or nvim>=0.4.0.',
          \   'Use :version to check the current version.',
          \   'Set g:win_disable_version_warning = 1 to disable this warning.'
          \ ]
    call s:ShowWarning(join(l:message_lines, "\n"))
  endif
  return 1
endfunction

" Returns a state that can be used for restoration.
function! s:Init()
  let l:state = {
        \   'winwidth': &winwidth,
        \   'winheight': &winheight,
        \   'cmdheight': &cmdheight,
        \   'laststatus': &laststatus,
        \ }
  if &cmdheight ==# 0
    " Neovim supports cmdheight=0. When used, temporarily change to 1 to work
    " around the vim-win prompt not showing otherwise and avoid 'Press ENTER
    " or type command to continue' after using the plugin.
    set cmdheight=1
  endif
  " Make sure the last window has a status line, to serve as a divider between
  " the info message and the last window.
  if has('nvim') && &laststatus ==# 3
    " Keep the existing value
  else
    set laststatus=2
  endif
  " Minimize winwidth and winheight so that moving around doesn't unexpectedly
  " cause window resizing.
  let &winwidth = max([1, &winminwidth])
  let &winheight = max([1, &winminheight])
  return l:state
endfunction

function! s:Restore(state)
  let &laststatus = a:state['laststatus']
  let &cmdheight = a:state['cmdheight']
  let &winwidth = a:state['winwidth']
  let &winheight = a:state['winheight']
endfunction

" Runs the vim-win command prompt loop. The function takes an optional
" argument specifying how many times to run (runs until exiting by default).
function! win#Win(...)
  if !s:CheckVersion() | return | endif
  let l:prompt = [
        \   ['WinStar', '*'],
        \   ['None', ' '],
        \   ['WinPrompt', 'vim-win'],
        \   ['None', '> ']
        \ ]
  let l:state = s:Init()
  let l:max_reps = str2nr(get(a:, 1, '0'))
  let l:reps = 0
  while l:max_reps <=# 0 || l:reps <# l:max_reps
    let l:reps += 1
    try
      if &buftype ==# 'nofile' && bufname('%') ==# '[Command Line]'
        call s:Beep()
        call s:ShowError('vim-win does not work with the command-line window')
        break
      endif
      call s:LabelWindows()
      call s:Echo(l:prompt)
      let l:char = s:GetChar()
      let l:code = char2nr(l:char)
      let l:ext_command = get(g:win_ext_command_map, l:char, '')
      if s:Contains(s:esc_chars, l:char) || l:ext_command ==# 'Win#exit'
        break
      elseif l:char ==# '?'
        call s:ShowHelp()
      elseif has_key(g:win_ext_command_map, l:char)
        execute l:ext_command
      elseif l:char ==# 'w'
        wincmd w
      elseif l:char ==# 'W'
        wincmd W
      elseif l:char ==# 's' || l:char ==# 'S'
        let l:swap_prompt = l:prompt + [['None', l:char]]
        let l:swap_winnr = s:ScanWinnr(l:swap_prompt)
        if l:swap_winnr !=# winnr()
              \ && l:swap_winnr ># 0
              \ && l:swap_winnr <= s:WindowCount()
          call s:Swap(l:swap_winnr)
          if l:char ==# 's' | execute l:swap_winnr . 'wincmd w' | endif
        endif
      elseif l:char ==# 'g'
        call s:LabelWindows(v:true)
        let l:g_prompt = l:prompt + [['None', l:char]]
        let l:winnr = s:ScanWinAlpha(l:g_prompt)
        if l:winnr !=# 0 | silent! execute l:winnr . 'wincmd w' | endif
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
      elseif s:Contains(s:resize_chars, l:char)
        if s:winmove
          if s:Contains(s:shift_left_chars, l:char)
            call win_move_separator(0, -g:win_resize_width)
          elseif s:Contains(s:ctrl_left_chars, l:char)
            if winnr('h') !=# winnr()
              call win_move_separator(winnr('h'), -g:win_resize_width)
            endif
          elseif s:Contains(s:shift_right_chars, l:char)
            call win_move_separator(0, g:win_resize_width)
          elseif s:Contains(s:ctrl_right_chars, l:char)
            if winnr('h') !=# winnr()
              call win_move_separator(winnr('h'), g:win_resize_width)
            endif
          elseif s:Contains(s:shift_up_chars, l:char)
            " Even though this operates on the current window, make sure there is
            " a window below, to prevent resizing the command line.
            if winnr('j') !=# winnr()
              call win_move_statusline(0, -g:win_resize_width)
            endif
          elseif s:Contains(s:ctrl_up_chars, l:char)
            if winnr('k') !=# winnr()
              call win_move_statusline(winnr('k'), -g:win_resize_width)
            endif
          elseif s:Contains(s:shift_down_chars, l:char)
            call win_move_statusline(0, g:win_resize_width)
          elseif s:Contains(s:ctrl_down_chars, l:char)
            if winnr('k') !=# winnr()
              call win_move_statusline(winnr('k'), g:win_resize_width)
            endif
          endif
        else
          if s:Contains(s:shift_left_chars, l:char)
            execute g:win_resize_width . ' wincmd <'
          elseif s:Contains(s:shift_right_chars, l:char)
            execute g:win_resize_width . ' wincmd >'
          elseif s:Contains(s:shift_up_chars, l:char)
            execute g:win_resize_width . ' wincmd +'
          elseif s:Contains(s:shift_down_chars, l:char)
            execute g:win_resize_width . ' wincmd -'
          endif
        endif
      endif
    catch
      call s:Beep()
      let l:message = v:throwpoint . "\n" . v:exception
      call s:ShowError(l:message)
      break
    endtry
  endwhile
  call s:RemoveWindowLabels()
  redraw | echo ''
  call s:Restore(l:state)
endfunction
