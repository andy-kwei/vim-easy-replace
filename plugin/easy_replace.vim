" vim-easy-replace
" --------------------
" Lightweight search and replace plugin using built-in `cgn` functionality

if &cp || (v:version < 700) || exists('g:loaded_easy_replace')
  finish
endif
let g:loaded_easy_replace = 1

" Define custom match highlight group
highlight link EasyReplace Search

" Define delay (ms) for automatically clearing match highlight
let s:cleanup_delay = 3000

" Replace word under cursor in normal mode
function! EasyReplaceNormal(reverse)
  " Clean up any existing state
  call s:cleanup()
  " No need to worry about character escaping as `<cword>` is fairly limited
  let @/ = '\<' . expand('<cword>') . '\>'
  " Highlight all matches
  let s:match_id = matchadd('EasyReplace', @/)
  " Trigger `cgn` keystrokes
  if !a:reverse
    call feedkeys('cgn', 'n')
  else
    call feedkeys('cgN', 'n')
  endif
endfunction

" Replace text in visual selection
function! EasyReplaceVisual(reverse)
  " Clean up any existing state
  call s:cleanup()
  " Store existing content in unnamed register
  let temp = @"
  " Yank visual selection into unnamed register
  normal! gvy
  " Highlight all matches
  let s:match_id = matchadd('EasyReplace', @")
  " Escape backslash and seach with `very nomagic` and `no ignorecase` options
  let @/ = '\V\C' . escape(@", '\')
  " Restore content to unnamed register
  let @" = temp
  " Trigger `cgn` keystrokes
  if !a:reverse
    call feedkeys('cgn', 'n')
  else
    call feedkeys('cgN', 'n')
  endif
endfunction

" Clear highlight and unset state variables
function! s:cleanup(...)
  if exists('s:match_id')
    " Clear match highlight
    call matchdelete(s:match_id)
    unlet s:match_id
  endif
  if exists('s:timer')
    " `timer_stop` does nothing if timer id is invalid
    call timer_stop(s:timer)
    unlet s:timer
  endif
  if exists('s:replace_text')
    " Reset undo-register history
    unlet s:replace_text
  endif
endfunction

" Helper function to start clean up timer
function! s:start_cleanup_timer()
  let s:timer = timer_start(s:cleanup_delay, function('s:cleanup'))
endfunction

" Helper function to renew clean up timer
function! s:renew_cleanup_timer()
  if exists('s:timer')
    call timer_stop(s:timer)
    call s:start_cleanup_timer()
  endif
endfunction

" Clear match highlight smartly (via `InsertLeave` autocmd)
function! EasyReplaceAutoCheck()
  " Do nothing when there is no match highlight
  if !exists('s:match_id')
    return
  " Record redo-register contents and start cleanup timer upon first insertion
  elseif !exists('s:replace_text')
    let s:replace_text = @.
    call s:start_cleanup_timer()
  " Renew timer if redo-register contents have not changed
  elseif s:replace_text ==# @.
    call s:renew_cleanup_timer()
  " Clean up earlier if user has moved on to new insertions
  elseif exists('s:timer')
    call s:cleanup()
  endif
endfunction

" Note that insertions from `.` command still trigger `InsertLeave` events
autocmd InsertLeave * call EasyReplaceAutoCheck()

" Expose plugin mappings
nnoremap <Plug>(EasyReplace) :<C-u>call EasyReplaceNormal(0)<CR>
xnoremap <Plug>(EasyReplace) :<C-u>call EasyReplaceVisual(0)<CR>

nnoremap <Plug>(EasyReplaceReverse) :<C-u>call EasyReplaceNormal(1)<CR>
xnoremap <Plug>(EasyReplaceReverse) :<C-u>call EasyReplaceVisual(1)<CR>

" Set default mappings to `<Leader>r` and `<Leader>R`
if !hasmapto('<Plug>(EasyReplace)', 'n') || mapcheck('<Leader>r', 'n') == ''
  nmap <Leader>r <Plug>(EasyReplace)
endif

if !hasmapto('<Plug>(EasyReplace)', 'x') || mapcheck('<Leader>r', 'x') == ''
  xmap <Leader>r <Plug>(EasyReplace)
endif

if !hasmapto('<Plug>(EasyReplaceReverse)', 'n') || mapcheck('<Leader>R', 'n') == ''
  nmap <Leader>R <Plug>(EasyReplaceReverse)
endif

if !hasmapto('<Plug>(EasyReplaceReverse)', 'x') || mapcheck('<Leader>R', 'x') == ''
  xmap <Leader>R <Plug>(EasyReplaceReverse)
endif
