" vim-easy-replace
" --------------------
" Lightweight search and replace plugin using built-in `cgn` functionality

" if &cp || (v:version < 700) || exists('g:loaded_easy_replace')
"   finish
" endif
let g:loaded_easy_replace = 1

" Define custom match highlighting group
highlight link EasyReplace Search

" Define delay (ms) for automatically clearing match highlighting
if !exists('g:easy_replace_hl_duration')
  let g:easy_replace_highlight_duration = 1500
endif

" Replace word under cursor in normal mode
function! s:easy_replace_normal(is_reverse)
  " Reset existing state and matches
  call s:clear_replace_pattern()
  " Get word under cursor
  let @/ = '\<' . expand('<cword>') . '\>'
  " Highlight matches
  call s:add_replace_pattern(@/)
  " Store reverse state
  let s:is_reverse = a:is_reverse
  " Trigger `cgn` keystrokes
  if s:is_reverse
    call feedkeys('cgN', 'n')
  else
    call feedkeys('cgn', 'n')
  endif
endfunction

" Replace text in visual selection
function! s:easy_replace_visual(is_reverse)
  " Reset existing state and matches
  call s:clear_replace_pattern()
  " Store existing content in unnamed register
  let temp = @"
  " Yank visual selection into unnamed register
  normal! gvy
  " Escape slashes and add `very nomagic` and `no ignorecase` options
  let @/ = '\V\C' . escape(@", '\/')
  " Highlight all matches
  call s:add_replace_pattern(@/)
  " Restore content to unnamed register
  let @" = temp
  " Store reverse state
  let s:is_reverse = a:is_reverse
  " Trigger `cgn` keystrokes
  if s:is_reverse
    call feedkeys('cgN', 'n')
  else
    call feedkeys('cgn', 'n')
  endif
endfunction

" Handle visual mode prepends correctly with `vim-repeat`
" Note that we add the `e` keystroke to exit the current word first. Otherwise,
" if the original word is a suffix of the replacement, we will be stuck at the
" same place when we press `.`, e.g. 'apple' -> 'pineapple' -> 'pinepineapple'.
" This is only an issue in visual mode, since the normal mode mapping puts
" `\<` and `\>` (beginning/end of word) guards around the searched word.
function! s:set_repeat()
  if s:is_reverse
    silent! call repeat#set(":normal! wcgN\<C-R>.\<CR>")
  else
    silent! call repeat#set(":normal! wcgn\<C-R>.\<CR>")
  endif
endfunction

" Highlight pattern to replace and start callback timer for cleanup
function! s:add_replace_pattern(pattern)
  let s:match_pattern = a:pattern
  let s:match_id = matchadd('EasyReplace', a:pattern)
  let s:timer = timer_start(g:easy_replace_highlight_duration,
        \ function('s:clear_replace_pattern'))
endfunction

" Clear match highlighting and unset state variables
function! s:clear_replace_pattern(...)
  if exists('s:match_id')
    call matchdelete(s:match_id)
  endif
  if exists('s:timer')
    call timer_stop(s:timer)
  endif
  unlet! s:match_id
  unlet! s:timer
endfunction

" Refresh callback timer
function! s:refresh_highlight(pattern)
  call s:clear_replace_pattern()
  call s:add_replace_pattern(a:pattern)
endfunction

" Clear match highlighting smartly (via `InsertLeave` autocmd)
function! s:easy_replace_update_state()
  " Do nothing if no pattern is being replaced
  if !exists('s:match_pattern')
    return
  " Upon initial replacement
  elseif !exists('s:replace_text')
    " Record redo-register contents
    let s:replace_text = @.
    " Set new `vim-repeat` keystrokes
    call s:set_repeat()
  " Upon subsequent replacements
  elseif s:replace_text ==# @.
    " Extend (or restart) match highlight duration
    call s:refresh_highlight(s:match_pattern)
    " We need to set repeat again
    call s:set_repeat()
  " Reset state if the user inserted a new pattern
  else
    unlet! s:match_pattern
    unlet! s:replace_text
  endif
endfunction

" Note that insertions from `.` command still trigger `InsertLeave` events
autocmd InsertLeave * call <SID>easy_replace_update_state()

" Expose plugin mappings
nnoremap <Plug>(EasyReplace) :<C-u>call <SID>easy_replace_normal(0)<CR>
xnoremap <Plug>(EasyReplace) :<C-u>call <SID>easy_replace_visual(0)<CR>

nnoremap <Plug>(EasyReplaceReverse) :<C-u>call <SID>easy_replace_normal(1)<CR>
xnoremap <Plug>(EasyReplaceReverse) :<C-u>call <SID>easy_replace_visual(1)<CR>
