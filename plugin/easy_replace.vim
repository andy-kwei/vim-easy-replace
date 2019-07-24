" vim-easy-replace
" --------------------
" Lightweight search and replace plugin using built-in `cgn` functionality

if &cp || (v:version < 700) || exists('g:loaded_easy_replace')
  finish
endif
let g:loaded_easy_replace = 1

" Define custom match highlighting group
highlight link EasyReplace Search

" Define delay (ms) for automatically clearing match highlighting
if !exists('g:easy_replace_hl_duration')
  let g:easy_replace_highlight_duration = 1500
endif

" Replace word under cursor in normal mode
function! EasyReplaceNormal(reverse)
  " Reset existing state and matches
  call s:clear_replace_pattern()
  " Get word under cursor
  let @/ = '\<' . expand('<cword>') . '\>'
  " Highlight matches
  call s:add_replace_pattern(@/)
  " Trigger `cgn` keystrokes
  if !a:reverse
    call feedkeys('cgn', 'n')
  else
    call feedkeys('cgN', 'n')
  endif
endfunction

" Replace text in visual selection
function! EasyReplaceVisual(reverse)
  " Reset existing state and matches
  call s:clear_replace_pattern()
  " Store existing content in unnamed register
  let temp = @"
  " Yank visual selection into unnamed register
  normal! gvy
  " Escape slashes and search with `very nomagic` and `no ignorecase` options
  let @/ = '\V\C' . escape(@", '\/')
  " Highlight all matches
  call s:add_replace_pattern(@/)
  " Restore content to unnamed register
  let @" = temp
  " Trigger `cgn` keystrokes
  if !a:reverse
    call feedkeys('cgn', 'n')
  else
    call feedkeys('cgN', 'n')
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
  unlet! s:redo_text
endfunction

" Refresh callback timer
function! s:refresh_highlight(pattern)
  call s:clear_replace_pattern()
  call s:add_replace_pattern(a:pattern)
endfunction

" Clear match highlighting smartly (via `InsertLeave` autocmd)
function! EasyReplaceUpdateState()
  " Do nothing if no pattern is being replaced
  if !exists('s:match_pattern')
    return
  " Record redo-register contents after first replacement
  elseif !exists('s:redo_text')
    let s:redo_text = @.
  " Refresh highlight duration if redo-register contents did not change yet
  elseif s:redo_text ==# @.
    call s:refresh_highlight(s:match_pattern)
  " Reset match state if the user inserted a new pattern
  else
    unlet! s:match_pattern
  endif
endfunction

" Note that insertions from `.` command still trigger `InsertLeave` events
autocmd InsertLeave * call EasyReplaceUpdateState()

" Expose plugin mappings
nnoremap <Plug>(EasyReplace) :<C-u>call EasyReplaceNormal(0)<CR>
xnoremap <Plug>(EasyReplace) :<C-u>call EasyReplaceVisual(0)<CR>

nnoremap <Plug>(EasyReplaceReverse) :<C-u>call EasyReplaceNormal(1)<CR>
xnoremap <Plug>(EasyReplaceReverse) :<C-u>call EasyReplaceVisual(1)<CR>
