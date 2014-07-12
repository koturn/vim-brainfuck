" Vim syntax file
" Language:     Brainfuck
" Maintainer:   koturn <jeak.koutan.apple@gmail.com>
" Version:      1.0
" Last Change:  2014 July 12
" URL:          https://github.com/koturn/vim-brainfuck/

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn match bfOpPointer '[<>]'
syn match bfOpValue   '[+-]'
syn match bfIO        '[.,]'
syn match bfLoop      '[[\]]'
syn match bfError     '[^<>+\-.,[\]]\+'

if version >= 508
  hi def link bfOpValue   Normal
  hi def link bfOpPointer Identifier
  hi def link bfIO        Special
  hi def link bfLoop      Conditional
  hi def link bfError     Error
endif

let b:current_syntax = 'brainfuck'
