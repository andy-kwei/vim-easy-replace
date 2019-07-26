" --------------- Main functions ---------------
" Replace word under cursor (from normal mode)
function! easy_replace#normal_begin(is_reverse)
  " Reset existing state and matches
  call s:clear_replace_pattern()
  " Get word under cursor
  let @/ = '\<' . expand('<cword>') . '\>'
  " Highlight matches
  call s:highlight_replace_pattern(@/)
  " Record state
  let s:match_pattern = @/
  let s:is_reverse = a:is_reverse
  " Trigger `cgn` keystrokes
  if a:is_reverse
    call feedkeys('cgN', 'n')
  else
    call feedkeys('cgn', 'n')
  endif
endfunction

" Replace visual selection
function! easy_replace#visual_begin(is_reverse)
  " Reset existing state and matches
  call s:clear_replace_pattern()
  " Store existing content in unnamed register
  let temp = @"
  " Yank visual selection into unnamed register
  normal! gvy
  " Escape slashes and add `very nomagic` and `no ignorecase` options
  let @/ = '\V\C' . escape(@", '\/')
  " Highlight all matches
  call s:highlight_replace_pattern(@/)
  " Restore content to unnamed register
  let @" = temp
  " Record state
  let s:match_pattern = @/
  let s:is_reverse = a:is_reverse
  " Trigger `cgn` keystrokes
  if a:is_reverse
    call feedkeys('cgN', 'n')
  else
    call feedkeys('cgn', 'n')
  endif
endfunction

" --------------- Smart cgn ---------------
" Handling visual mode behavior correctly:
" When the original word happens to be a suffix of its replacement, using
"   vanilla `cgn` keystrokes with `.` gets us stuck at the same word, causing
"   behavior such as 'apple' -> 'pineapple' -> 'pinepineapple'. To remedy this
"   shortcoming, we define the `smart_cgn` function below.

" Side note: This is only an issue in the visual mode function, since we put
"   `\<` and `\>` (beginning/end of word) guards around the current pattern in
"   the normal mode version (similar to the behavior of `*` search).

" Execute `cgn` smartly
function! easy_replace#smart_cgn()
  " Exit early if the plugin is inactive or if there are no more matches
  if !exists('s:match_pattern') || search(s:match_pattern, 'nw') == 0
    return
  endif
  " Move cursor forward if its position hasn't changed since the last replace
  if exists('s:last_replace_pos') && s:last_replace_pos == s:get_current_pos()
    normal! w
  endif
  " Execute next replacement
  if s:is_reverse
    execute "normal! cgN\<C-r>."
  else
    execute "normal! cgn\<C-r>."
  endif
  " Update state
  let s:last_replace_pos = s:get_current_pos()
endfunction

" Helper function to get line number and offset from end of line
function! s:get_current_pos()
  let pos = getcurpos()
  let curr_lnum = pos[1]
  let curr_line = getline(curr_lnum)
  let offset_from_eol = len(curr_line) - pos[2]
  return [curr_lnum, offset_from_eol]
endfunction

" Helper function to set custom repeat command (using `tpope/vim-repeat`)
function! s:set_repeat()
  silent! call repeat#set(":call easy_replace#smart_cgn()\<CR>")
endfunction

" --------------- Match Highlighting ---------------
" Highlight pattern to replace and start callback timer for cleanup
function! s:highlight_replace_pattern(pattern)
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
  call s:highlight_replace_pattern(a:pattern)
endfunction

" --------------- State logic ---------------
" State updates and checks attached to `InsertLeave` autocmd event
function! easy_replace#update_state()
  " Do nothing if no pattern is being replaced
  if !exists('s:match_pattern')
    return
  " Initial replacement
  elseif !exists('s:replace_text')
    " Record redo-register contents
    let s:replace_text = @.
    " Record position of last replace action
    let s:last_replace_pos = s:get_current_pos()
    " Set new `vim-repeat` keystrokes
    call s:set_repeat()
  " Subsequent replacements
  elseif s:replace_text ==# @.
    " Extend (or restart) match highlight duration
    call s:refresh_highlight(s:match_pattern)
    " We need to set repeat again
    call s:set_repeat()
  " Reset state after the user has inserted a new pattern
  else
    unlet! s:match_pattern
    unlet! s:last_replace_pos
    unlet! s:is_reverse
    unlet! s:replace_text
  endif
endfunction
