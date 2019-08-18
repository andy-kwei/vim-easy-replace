Vim-Easy-Replace
--------------------
A lightweight
[vim-multiple-cursors](https://github.com/terryma/vim-multiple-cursors)
replacement that improves upon the builtin `cgn` functionality.

## Installation
Using [Vim-Plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'andy-kwei/vim-easy-replace'
```
and install [vim-repeat](https://github.com/tpope/vim-repeat) (recommended):
```vim
Plug 'tpope/vim-repeat'
```

## Mappings
The plugin comes with the following default mappings:
```vim
" Trigger EasyReplace with word under cursor
nmap <Leader>r <Plug>(EasyReplace)
nmap <Leader>R <Plug>(EasyReplaceReverse)

" Trigger EasyReplace with visual selection
xmap <Leader>r <Plug>(EasyReplace)
xmap <Leader>R <Plug>(EasyReplaceReverse)
```
You can also define your own custom mappings in your `.vimrc` (or `init.vim`
for Neovim). The plugin will check for any existing mappings to
`<Plug>(EasyReplace)` before creating the default maps.
