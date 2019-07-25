Vim-Easy-Replace
--------------------
A lightweight [vim-multiple-cursors](https://github.com/terryma/vim-multiple-cursors) replacement that imrpoves the builtin `cgn` functionality.

## Installation
Using [Vim-Plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'andy-kwei/vim-easy-replace'
```
and install [vim-repeat](https://github.com/tpope/vim-repeat) (recommended):
```vim
Plug 'tpope/vim-repeat'
```

## Example configuration
Add the following mappings to your `.vimrc`:
```vim
" Trigger EasyReplace with word under cursor
nmap <Leader>r <Plug>(EasyReplace)
nmap <Leader>R <Plug>(EasyReplaceReverse)

" Trigger EasyReplace with visual selection
xmap <Leader>r <Plug>(EasyReplace)
xmap <Leader>R <Plug>(EasyReplaceReverse)
```
Note that this plugin does not come with any default mappings.
