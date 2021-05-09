" --------------- Main functions ---------------
" Replace word under cursor (from normal mode)
function! easy_replace#normal_begin(is_reverse)
  " Set search register to word under cursor
  let @/ = '\<' . expand('<cword>') . '\>'
  set hlsearch
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
  " Store existing content in unnamed register
  let temp = @"
  " Yank visual selection into unnamed register
  normal! gvy
  " Escape slashes and add `very nomagic` and `no ignorecase` flags
  let @/ = '\V\C' . escape(@", '\/')
  set hlsearch
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
" vanilla `cgn` keystrokes with `.` gets us stuck at the same word, causing
" behavior such as 'apple' -> 'pineapple' -> 'pinepineapple' without
" progressing. To remedy this we define the `smart_cgn` function below that
" moves the cursor forward upon replacement.

" Execute `cgn` smartly
function! easy_replace#smart_cgn()
  " Exit early if there is no active match or there are no more matches
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
