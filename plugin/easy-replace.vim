" Exit if vi compatible or plugin already loaded
if &cp || exists('g:loaded_easy_replace')
  finish
endif
let g:loaded_easy_replace = 1

" Define custom match highlight group
highlight link EasyReplace Search

" Define delay (ms) for automatically clearing match highlight
let s:cleanup_delay = 3000

" Change text under cursor
function! EasyReplaceNormal()
  " Clean up any existing state
  call s:cleanup()
  " No need to worry about character escaping as `<cword>` is fairly limited
  let @/ = '\<' . expand('<cword>') . '\>'
  " Highlight all matches
  let s:match_id = matchadd('EasyReplace', @/)
  " Exectue cgn
  call feedkeys('cgn', 'n')
endfunction

" Change text in visual selection
function! EasyReplaceVisual()
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
  " Execute cgn
  call feedkeys('cgn', 'n')
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

" Helper functions to start and renew timer for cleanup
function! s:start_cleanup_timer()
  let s:timer = timer_start(s:cleanup_delay, function('s:cleanup'))
endfunction

function! s:renew_cleanup_timer()
  if exists('s:timer')
    call timer_stop(s:timer)
    call s:start_cleanup_timer()
  endif
endfunction

" Clear match highlight smartly (paired with `InsertLeave` autocmd)
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

" Note that insertions via `.` command triggers `InsertLeave` event
autocmd InsertLeave * call EasyReplaceAutoCheck()

" Expose plugin maps as `<Plug>(EasyReplace)`
nnoremap <Plug>(EasyReplace) :<C-u>call EasyReplaceNormal()<CR>
xnoremap <Plug>(EasyReplace) :<C-u>call EasyReplaceVisual()<CR>

" Set default mapping to `<Leader>r` safely
if !hasmapto('<Plug>(EasyReplace)', 'n') || mapcheck('<Leader>r', 'n') == ''
  nmap <Leader>r <Plug>(EasyReplace)
endif

if !hasmapto('<Plug>(EasyReplace)', 'x') || mapcheck('<Leader>r', 'x') == ''
  xmap <Leader>r <Plug>(EasyReplace)
endif
