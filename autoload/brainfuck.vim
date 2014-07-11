"=============================================================================
" FILE: brainfuck.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" A brainfuck interpreter and C-translator for Vim.
" }}}
"=============================================================================
let s:save_cpo = &cpo
set cpo&vim


function! brainfuck#exec_current_buffer()
  let l:source = join(getline('1', '$'), '')
  let l:output = s:execute(l:source)
  split __BFC_RESULT__
  setl nobuflisted bufhidden=unload buftype=nofile
  call setline(1, split(l:output, "\n"))
endfunction


function! brainfuck#translate2C_current_buffer()
  let l:source = join(getline('1', '$'), '')
  let l:output = s:translate2C(l:source, '  ')
  split __BFC_NEWFILE__
  setl nobuflisted bufhidden=unload buftype=nofile
  setfiletype c
  call setline(1, split(l:output, "\n"))
endfunction


function! s:execute(source)
  let l:len  = len(a:source)
  let l:memory = repeat([0], 65536)

  let l:output = ''
  let l:dc = 0
  let l:pc = 0
  while l:pc < l:len
    if a:source[l:pc] ==# '>'
      let l:dc += 1
    elseif a:source[l:pc] ==# '<'
      let l:dc -= 1
    elseif a:source[l:pc] ==# '+'
      let l:memory[l:dc] += 1
    elseif a:source[l:pc] ==# '-'
      let l:memory[l:dc] -= 1
    elseif a:source[l:pc] ==# '.'
      let l:output .= nr2char(l:memory[l:dc])
    elseif a:source[l:pc] ==# ','
      let l:memory[l:dc] = char2nr(getchar())
    elseif a:source[l:pc] ==# '['
      let l:pc += 1
      if l:memory[l:dc] != 0
        continue
      endif
      let l:local_depth = 0
      while l:local_depth > 0 || a:source[l:pc] != ']'
        if a:source[l:pc] == '['
          let l:local_depth += 1
        elseif a:source[l:pc] == ']'
          let l:local_depth -= 1
        endif
        let l:pc += 1
      endwhile
    elseif a:source[l:pc] ==# ']'
      let l:pc -= 1
      let l:local_depth = 0
      while l:local_depth > 0 || a:source[l:pc] != '['
        if a:source[l:pc] == ']'
          let l:local_depth += 1
        elseif a:source[l:pc] == '['
          let l:local_depth -= 1
        endif
        let l:pc -= 1
      endwhile
      let l:pc -= 1
    else
      throw 'Invalid character'
    endif
    let l:pc += 1
  endwhile
  return l:output
endfunction


function! s:translate2C(source, istr)
  let l:output = "#include <stdio.h>\n"
        \ . "#include <stdlib.h>\n\n"
        \ . "#define MEMORY_SIZE 65536\n\n"
        \ . "int main(void)\n"
        \ . "{\n"
        \ . a:istr . "static char memory[MEMORY_SIZE];\n"
        \ . a:istr . "char *ptr = memory;\n\n"

  let l:depth = 1
  let l:pc = 0
  let l:len = strlen(a:source)
  while l:pc < l:len
    if a:source[l:pc] ==# '>'
      let l:cnt = 0
      while a:source[l:pc] ==# '>'
        let l:cnt += 1
        let l:pc += 1
      endwhile
      let l:output .= repeat(a:istr, l:depth) . 'ptr'
            \ . (l:cnt == 1 ? "++;\n" : ' += ' . l:cnt . ";\n")
    elseif a:source[l:pc] ==# '<'
      let l:cnt = 0
      while a:source[l:pc] ==# '<'
        let l:cnt += 1
        let l:pc += 1
      endwhile
      let l:output .= repeat(a:istr, l:depth) . 'ptr'
            \ . (l:cnt == 1 ? "--;\n" : ' -= ' . l:cnt . ";\n")
    elseif a:source[l:pc] ==# '+'
      let l:cnt = 0
      while a:source[l:pc] ==# '+'
        let l:cnt += 1
        let l:pc += 1
      endwhile
      let l:output .= repeat(a:istr, l:depth) . '(*ptr)'
            \ . (l:cnt == 1 ? "++;\n" : ' += ' . l:cnt . ";\n")
    elseif a:source[l:pc] ==# '-'
      let l:cnt = 0
      while a:source[l:pc] ==# '-'
        let l:cnt += 1
        let l:pc += 1
      endwhile
      let l:output .= repeat(a:istr, l:depth) . '(*ptr)'
            \ . (l:cnt == 1 ? "--;\n" : ' -= ' . l:cnt . ";\n")
    elseif a:source[l:pc] ==# '.'
      let l:output .= repeat(a:istr, l:depth) . "putchar(*ptr);\n"
      let l:pc += 1
    elseif a:source[l:pc] ==# ','
      let l:output .= repeat(a:istr, l:depth) . "*ptr = getchar();\n"
      let l:pc += 1
    elseif a:source[l:pc] ==# '['
      let l:output .= repeat(a:istr, l:depth) . "while (*ptr) {\n"
      let l:depth += 1
      let l:pc += 1
    elseif a:source[l:pc] ==# ']'
      let l:depth -= 1
      let l:output .= repeat(a:istr, l:depth) . "}\n"
      let l:pc += 1
    else
      let l:pc += 1
    endif
  endwhile

  let l:output .= "\n" . a:istr . "return EXIT_SUCCESS;\n}\n"
  return l:output
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
