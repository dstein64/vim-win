# vim-win

`vim-win` is a Vim plugin for managing windows. Built-in functionality includes
window selection, window buffer swapping, and window resizing. The plugin is
extensible, allowing additional functionality to be added (see *Configuration*
below).

<img src="https://github.com/dstein64/vim-win/blob/master/screenshot.png?raw=true" width="800"/>

## Requirements

* Full functionality
  - `vim>=8.2` or `nvim>=0.4.0`
* Limited functionality (no window labels)
  - `vim>=8.1.1140`

## Installation

Use one of the following package managers:

* [Vim8 packages][vim8pack]:
  - `git clone https://github.com/dstein64/vim-win ~/.vim/pack/plugins/start/vim-win`
* [Vundle][vundle]:
  - Add `Plugin 'dstein64/vim-win'` to `~/.vimrc`
  - `:PluginInstall` or `$ vim +PluginInstall +qall`
* [Pathogen][pathogen]:
  - `git clone --depth=1 https://github.com/dstein64/vim-win ~/.vim/bundle/vim-win`
* [vim-plug][vimplug]:
  - Add `Plug 'dstein64/vim-win'` to `~/.vimrc`
  - `:PlugInstall` or `$ vim +PlugInstall +qall`
* [dein.vim][dein]:
  - Add `call dein#add('dstein64/vim-win')` to `~/.vimrc`
  - `:call dein#install()`
* [NeoBundle][neobundle]:
  - Add `NeoBundle 'dstein64/vim-win'` to `~/.vimrc`
  - Re-open vim or execute `:source ~/.vimrc`

## Usage

Enter `vim-win` with `<leader>w` or `:Win`. These can be customized (see
*Configuration* below).

* Arrows or `hjkl` keys are used for movement.
* There are various ways to change the active window.
  - Use movement keys to move to neighboring windows.
  - Enter a window number (where applicable, press `<enter>` to submit).
  - Use `w` or `W` to sequentially move to the next or previous window.

* Hold `<shift>` and use movement keys to resize the active window.
  - *Left* movements decrease width and *right* movements increase width.
  - *Down* movements decrease height and *up* movements increase height.
* Press `s` followed by a movement key or window number, to swap buffers.
* Press `?` to show a help message.
* Press `<esc>` to leave `vim-win` or go back (where applicable).

## Configuration

By default, `vim-win` is started with `<leader>w` or `:Win`. These will not be
clobbered in case they are already used. The `:Win` command takes an optional
argument specifying how many `vim-win` commands to run (e.g., `:Win 1` would
exit `vim-win` after the first command). If the optional argument is `0`, which
is the default, `vim-win` runs until exit.

```vim
" The following defaults can be customized in your .vimrc
map <leader>w <plug>WinWin
command Win :call win#Win()
```

The following variables can be used to customize the behavior of `vim-win`.

| Variable                        | Default | Description                              |
|---------------------------------|---------|------------------------------------------|
| `g:win_resize_height`           | `2`     | Number of rows to shift when resizing    |
| `g:win_resize_width`            | `2`     | Number of columns to shift when resizing |
| `g:win_disable_version_warning` | `0`     | Set to 1 to disable the version warning  |
| `g:win_ext_command_map`         | `{}`    | A dictionary for extending `vim-win`     |

The `g:win_ext_command_map` maps `vim-win` command keys to `vim` command
strings. The `'Win#exit'` string can be used as a command string for exiting
`vim-win`.

The variables can be customized in your `.vimrc`, as shown in the following
example.

```vim
let g:win_resize_height = 3
let g:win_resize_width = 4
let g:win_disable_version_warning = 1
let g:win_ext_command_map = {
      \   'c': 'wincmd c',
      \   'C': 'close!',
      \   'q': 'quit',
      \   'Q': 'quit!',
      \   '!': 'qall!',
      \   'V': 'wincmd v',
      \   'S': 'wincmd s',
      \   'n': 'bnext',
      \   'N': 'bnext!',
      \   'p': 'bprevious',
      \   'P': 'bprevious!',
      \   "\<c-n>": 'tabnext',
      \   "\<c-p>": 'tabprevious',
      \   '=': 'wincmd =',
      \   't': 'tabnew',
      \   'x': 'Win#exit'
      \ }
```

The following highlight groups can be configured to change `vim-win`'s colors.

| Name          | Default      | Description                               |
|---------------|--------------|-------------------------------------------|
| `WinActive`   | `DiffAdd`    | Color for the *active window* label       |
| `WinInactive` | `Todo`       | Color for *inactive window* labels        |
| `WinNeighbor` | `Todo`       | Color for *neighbor window* labels        |
| `WinStar`     | `StatusLine` | Color for `*` in `vim-win` command prompt |
| `WinPrompt`   | `ModeMsg`    | Color for the command prompt text         |

The highlight groups can be customized in your `.vimrc`, as shown in the
following example.

```vim
" Link WinActive highlight to Error highlight
highlight link WinActive Error

" Specify custom highlighting for WinInactive 
highlight WinInactive term=bold ctermfg=12 ctermbg=159 guifg=Blue guibg=LightCyan
```

## Demo

<img src="https://github.com/dstein64/vim-win/blob/master/screencast.gif?raw=true" width="800"/>

License
-------

The source code has an [MIT License](https://en.wikipedia.org/wiki/MIT_License).

See [LICENSE](https://github.com/dstein64/vim-win/blob/master/LICENSE).

[dein]: https://github.com/Shougo/dein.vim
[neobundle]: https://github.com/Shougo/neobundle.vim
[pathogen]: https://github.com/tpope/vim-pathogen
[vim8pack]: http://vimhelp.appspot.com/repeat.txt.html#packages
[vimplug]: https://github.com/junegunn/vim-plug
[vundle]: https://github.com/gmarik/vundle
