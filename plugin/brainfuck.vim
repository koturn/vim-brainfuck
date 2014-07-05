"=============================================================================
" FILE: brainfuck.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" A brainfuck interpreter and C-translator for Vim.
" }}}
"=============================================================================
if exists('g:loaded_brainfuck')
  finish
endif
let g:loaded_brainfuck = 1
let s:save_cpo = &cpo
set cpo&vim


command! -bar BFExecute  call brainfuck#exec_current_buffer()
command! -bar BFTranslate2C  call brainfuck#translate2C_current_buffer()


let &cpo = s:save_cpo
unlet s:save_cpo
