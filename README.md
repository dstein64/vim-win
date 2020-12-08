# vim-win

`vim-win` is a Vim plugin for managing windows. Built-in functionality includes
window selection, window buffer swapping, and window resizing. The plugin is
extensible, allowing additional functionality to be added (see *Configuration*
below).

<img src="screenshot.png?raw=true" width="800"/>

## Requirements

* Full functionality
  - `vim>=8.1.2269` or `nvim>=0.4.0`
* Limited functionality (no window labels)
  - `vim>=8.1.1140`

## Installation

A package manager can be used to install `vim-win`.
<details><summary>Examples</summary><br>

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

</details>

## Usage

Enter `vim-win` with `<leader>w` or `:Win`.

* Arrows or `hjkl` keys are used for movement.
* Change windows with movement keys or numbers.
* Hold `<shift>` and use movement keys to resize the active window.
* Press `s` or `S` followed by a movement key or window number, to swap buffers.
* Press `?` to show a help message.
* Press `<esc>` to leave `vim-win`.

See `:help win-usage` for additional details.

## Documentation

```vim
:help vim-win
```

The underlying markup is in [win.txt](doc/win.txt).

## Demo

<img src="screencast.gif?raw=true" width="735"/>

License
-------

The source code has an [MIT License](https://en.wikipedia.org/wiki/MIT_License).

See [LICENSE](LICENSE).

[dein]: https://github.com/Shougo/dein.vim
[neobundle]: https://github.com/Shougo/neobundle.vim
[pathogen]: https://github.com/tpope/vim-pathogen
[vim8pack]: http://vimhelp.appspot.com/repeat.txt.html#packages
[vimplug]: https://github.com/junegunn/vim-plug
[vundle]: https://github.com/gmarik/vundle
