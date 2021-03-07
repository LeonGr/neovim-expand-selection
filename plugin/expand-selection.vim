if exists('g:loaded_expsel') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset coptions to default

" command to run our plugin
command! -range ExpSel lua require'expand-selection'.expsel()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_expsel = 1
