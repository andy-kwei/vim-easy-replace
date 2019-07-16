" Exit if vi compatible or plugin already loaded
if &cp || exists('g:loaded_easy_replace')
  finish
endif
let g:loaded_easy_replace = 1

" Define custom match highlight group
highlight link EasyReplace Search

" Define delay (ms) for automatically clearing match highlight
let s:clear_delay = 3000

" Change text under cursor
function! EasyReplaceNormal()
  " We don't have to worry about character escaping as `<cword>` behavior
  " is fairly limited
  let @/ = '\<' . expand('<cword>') . '\>'
  " Highlight all matches
  let s:match_id = matchadd('EasyReplace', @/)
  " Exectue cgn
  call feedkeys('cgn', 'n')
endfunction

" Change text in visual selection
function! EasyReplaceVisual()
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

" Clear match highlight and unlet state variables
function! s:clear_match_and_state(...)
  if exists('s:match_id')
    call matchdelete(s:match_id)
    unlet s:match_id
  endif
  if exists('s:clear_timer')
    unlet s:clear_timer
  endif
  if exists('s:replace_text')
    unlet s:replace_text
  endif
endfunction

" Helper function to renew timer for clearing match highlight
function! s:renew_timer()
  if exists('s:clear_timer')
    call timer_stop(s:clear_timer)
  endif
  let s:clear_timer = timer_start(s:clear_delay, function('s:clear_match_and_state'))
endfunction

" Check if match highlight should be cleared by tracking redo-register contents
function! EasyReplaceAutoCheck()
  " Do nothing when there is no match highlight
  if !exists('s:match_id')
    return
  " Keep match highlight if redo-register contents haven't changed
  elseif !exists('s:replace_text') || s:replace_text ==# @.
    let s:replace_text = @.
    call s:renew_timer()
  " Otherwise, clear match highlight and reset state variables
  else
    call s:clear_match_and_state()
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
