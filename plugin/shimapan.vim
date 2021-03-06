" Author:  hisakazu <cantabilehisa@gmail.com>
" License: MIT License

let s:save_cpo = &cpo
set cpo&vim


if exists("g:loaded_shimapan")
  finish
endif
let g:loaded_shimapan = 1

if (&t_Co < 256)
  finish
endif

if !exists("g:shimapan_first_color")
  let g:shimapan_first_color  = "ctermfg=255 ctermbg=26"
endif

if !exists("g:shimapan_second_color")
  let g:shimapan_second_color = "cterm=reverse"
endif

if !exists("g:shimapan_first_texticon")
  let g:shimapan_first_texticon = ">"
endif

if !exists("g:shimapan_second_texticon")
  let g:shimapan_second_texticon = "<"
endif

if !exists("g:shimapan_is_signcolumn")
  let g:shimapan_is_signcolumn = 'no'
endif


" NOTE: shi-ma-pan-tsu
let s:shimapan_sign_id = 4082

" buflist has key-value pairs list.
"   keys<String>: buffer number
"   value<Integer>: last line
" When a pair is not stored in the list, new pair is created, and 'value'
" which is mean 'last line' is initialized by '1'.
let s:shimapan_bufline_dict = {}

" buflist has key-value pairs list.
"   keys<String>: buffer number
"   value<Integer>: name of original filetype
let s:shimapan_bufft_dict = {}


let s:shimapan_fname = ''
let s:shimapan_bufnr = 0

" ============================================================================
" function

function! s:ShimapanUpdateAppearance()
  execute "highlight ShimapanFirstColor ".g:shimapan_first_color
  execute "highlight ShimapanSecondColor ".g:shimapan_second_color
  execute "sign define ShimapanFirstSign linehl=ShimapanFirstColor text="
        \ .g:shimapan_first_texticon
  execute "sign define ShimapanSecondSign linehl=ShimapanSecondColor text="
        \ .g:shimapan_second_texticon
endfunction

" This function is invoked at BufReadPost event to prevent that vim tries to
" change from 'shimapan' to original filetype of buffer.
function s:ShimapanAlready()
  let l:bufnr = bufnr('%')
  if has_key(s:shimapan_bufft_dict, l:bufnr)
    setlocal filetype=shimapan
  endif
endfunction

function s:ShimapanGo()
  let l:fname = expand('%:p')
  if l:fname == '' | return | endif
  let l:bufnr = bufnr('%')
  if !has_key(s:shimapan_bufft_dict, l:bufnr)
    if &filetype == ''
      let s:shimapan_bufft_dict[l:bufnr] = 'NONE'
    else
      let s:shimapan_bufft_dict[l:bufnr] = &filetype
    endif
    " call <SID>ShimapanSetVal()
    execute "setlocal signcolumn=".g:shimapan_is_signcolumn
    setlocal filetype=shimapan
    let l:lim = line('$')
    call <SID>ShimapanPlace(l:lim, l:bufnr)
  endif
endfunction

function! s:ShimapanBye()
  if &filetype != 'shimapan' | return | endif
  let l:bufnr = bufnr('%')
  let l:lim = line('$')
  call <SID>ShimapanRemove(l:lim, l:bufnr)
  if s:shimapan_bufft_dict[l:bufnr] == 'NONE'
    let &filetype = ''
  else
    let &filetype = s:shimapan_bufft_dict[l:bufnr]
  endif
  call remove(s:shimapan_bufft_dict, l:bufnr)
  call remove(s:shimapan_bufline_dict, l:bufnr)
  let s:shimapan_bufline_dict[l:bufnr] = l:lim + 1
endfunction

function! s:ShimapanReload()
  if &filetype != 'shimapan' | return | endif
  let l:bufnr = bufnr('%')
  let l:lim = line('$')
  call <SID>ShimapanUpdateAppearance()
  call <SID>ShimapanUnplace(l:lim, l:bufnr)
  call <SID>ShimapanPlace(l:lim, l:bufnr)
endfunction

" NOTE: currently this funtion is not used.
" function! s:ShimapanSetVal()
"   let s:shimapan_bufnr = bufnr('%')
"   " let s:shimapan_fname = expand('%:p')
" endfunction

" NOTE: currently this funtion is not used.
" TODO: This function works correctly in the only case, that add the line from
" lastline of buffer in both insert mode and normal mode. In other case, the
" function does not work so. For examples, when mode is normal, some lines are
" put in where is not lastline. Also, some lines are deleted in that place.
" function! s:ShimapanUpdate()
"   if &filetype != 'shimapan' | return | endif
"   if has_key(s:shimapan_bufline_dict, s:shimapan_bufnr)
"     let l:i = s:shimapan_bufline_dict[s:shimapan_bufnr]
"   else
"     let l:i = 1
"   endif
"   let l:lim = line('$')
"   call <SID>ShimapanPlaceEvenOdd(l:odd, l:lim, "ShimapanFirstSign",
"         \ s:shimapan_bufnr)
"   call <SID>ShimapanPlaceEvenOdd(l:even, l:lim, "ShimapanSecondSign",
"         \ s:shimapan_bufnr)
"   let s:shimapan_bufline_dict[s:shimapan_bufnr] = l:i
" endfunction

function! s:ShimapanUnplace(lim, bufnr)
  let l:i = 1
  while l:i <= a:lim
    execute "sign unplace ".s:shimapan_sign_id." buffer=".a:bufnr
    let l:i += 1
  endwhile
endfunction

function! s:ShimapanPlace(lim, bufnr)
  let l:i = 1
  if l:i%2 == 0
    let l:even = l:i
    let l:odd  = l:i+1
  else
    let l:odd  = l:i
    let l:even = l:i+1
  endif
  let l:lim = line('$')
  call <SID>ShimapanPlaceEvenOdd(l:odd, l:lim, "ShimapanFirstSign", a:bufnr)
  call <SID>ShimapanPlaceEvenOdd(l:even, l:lim, "ShimapanSecondSign", a:bufnr)
endfunction

function! s:ShimapanPlaceEvenOdd(start, end, sign, bufnr)
  let l:i = a:start
  while l:i <= a:end
    execute "sign place ".s:shimapan_sign_id." line=".l:i
          \ ." name=".a:sign." buffer=".a:bufnr
    let l:i += 2
  endwhile
endfunction


" ============================================================================
" autocmd

" To update sign placement
" autocmd WinEnter *        call <SID>ShimapanSetVal()
" autocmd Filetype shimapan call <SID>ShimapanUpdate()
" autocmd TextChanged *     call <SID>ShimapanUpdate()
" autocmd TextChangedI *    call <SID>ShimapanUpdate()

" To prevent that vim set original filetype when the target buffer is re-edit.
autocmd BufReadPost *     call <SID>ShimapanAlready()


" ============================================================================
" command
command! ShimapanGo     call <SID>ShimapanGo()
command! ShimapanBye    call <SID>ShimapanBye()
command! ShimapanReload call <SID>ShimapanReload()

call <SID>ShimapanUpdateAppearance()

let &cpo = s:save_cpo
unlet s:save_cpo
