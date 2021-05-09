" vim-easy-replace
" --------------------
" Lightweight search and replace plugin using built-in `cgn` functionality

if &cp || (v:version < 700) || exists('g:loaded_easy_replace')
  finish
endif
let g:loaded_easy_replace = 1

" Expose plugin maps
nnoremap <Plug>(EasyReplace) :<C-u>call easy_replace#normal_begin(0) | set hlsearch<CR>
xnoremap <Plug>(EasyReplace) :<C-u>call easy_replace#visual_begin(0) | set hlsearch<CR>
nnoremap <Plug>(EasyReplaceReverse) :<C-u>call easy_replace#normal_begin(1) | set hlsearch<CR>
xnoremap <Plug>(EasyReplaceReverse) :<C-u>call easy_replace#visual_begin(1) | set hlsearch<CR>

" Create default mappings
if !hasmapto('<Plug>(EasyReplace)')
  " Trigger EasyReplace with word under cursor
  silent! nmap <unique> <Leader>r <Plug>(EasyReplace)
  silent! nmap <unique> <Leader>R <Plug>(EasyReplaceReverse)

  " Trigger EasyReplace with visual selection
  silent! xmap <unique> <Leader>r <Plug>(EasyReplace)
  silent! xmap <unique> <Leader>R <Plug>(EasyReplaceReverse)
endif
