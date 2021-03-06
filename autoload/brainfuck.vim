"=============================================================================
" FILE: brainfuck.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" A brainfuck interpreter and C-translator for Vim.
" }}}
"=============================================================================
let s:save_cpo = &cpo
set cpo&vim


let g:brainfuck#use_lua = get(g:, 'brainfuck#use_lua', has('lua'))
let g:brainfuck#verbose = get(g:, 'brainfuck#verbose', 0)


function! brainfuck#exec_current_buffer()
  let l:source = join(getline('1', '$'), '')
  if g:brainfuck#verbose
    let l:start_time = reltime()
  endif
  let l:output = s:run(l:source)
  if g:brainfuck#verbose
    echomsg '[brainfuck] execute time:' reltimestr(reltime(l:start_time))
  endif
  split __BF_RESULT__
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


if g:brainfuck#use_lua
  lua << EOF
  Brainfuck = {
    NEXT   = string.byte('>'),
    PREV   = string.byte('<'),
    ADD    = string.byte('+'),
    SUB    = string.byte('-'),
    OUTPUT = string.byte('.'),
    INPUT  = string.byte(','),
    LOOP_S = string.byte('['),
    LOOP_E = string.byte(']'),
    ASSIGN_ZERO = string.byte('0')
  }

  Brainfuck.execute = function(program, jump_table)
    local len = #program
    local memory = {0}
    local output = ''
    local dc = 1
    local pc = 1
    while pc <= len do
      local c = program[pc]
      if c == Brainfuck.NEXT then
        pc = pc + 1
        dc = dc + program[pc]
        if memory[dc] == nil then
          memory[dc] = 0
        end
      elseif c == Brainfuck.ADD then
        pc = pc + 1
        memory[dc] = memory[dc] + program[pc]
      elseif c == Brainfuck.OUTPUT then
        output = output .. string.char(memory[dc])
      elseif c == Brainfuck.INPUT then
        memory[dc] = vim.eval('getchar()')
      elseif c == Brainfuck.LOOP_S then
        if memory[dc] == 0 then
          pc = jump_table[pc]
        end
      elseif c == Brainfuck.LOOP_E then
        pc = jump_table[pc] - 1
      elseif c == Brainfuck.ASSIGN_ZERO then
        memory[dc] = 0
      end
      pc = pc + 1
    end
    return output
  end


  Brainfuck.compile = function(source)
    local len = string.len(source)
    local program = {}
    local jump_table = {}
    local stack = {}
    local stack_idx = 1
    local pc = 1
    while pc <= len do
      local c = string.byte(source, pc)
      if c == Brainfuck.NEXT then
        pc = pc + 1
        local cnt = 1
        while string.byte(source, pc) == Brainfuck.NEXT do
          cnt = cnt + 1
          pc = pc + 1
        end
        table.insert(program, Brainfuck.NEXT)
        table.insert(program, cnt)
      elseif c == Brainfuck.PREV then
        pc = pc + 1
        local cnt = 1
        while string.byte(source, pc) == Brainfuck.PREV do
          cnt = cnt + 1
          pc = pc + 1
        end
        table.insert(program, Brainfuck.NEXT)
        table.insert(program, -cnt)
      elseif c == Brainfuck.ADD then
        pc = pc + 1
        local cnt = 1
        while string.byte(source, pc) == Brainfuck.ADD do
          cnt = cnt + 1
          pc = pc + 1
        end
        table.insert(program, Brainfuck.ADD)
        table.insert(program, cnt)
      elseif c == Brainfuck.SUB then
        pc = pc + 1
        local cnt = 1
        while string.byte(source, pc) == Brainfuck.SUB do
          cnt = cnt + 1
          pc = pc + 1
        end
        table.insert(program, Brainfuck.ADD)
        table.insert(program, -cnt)
      elseif c == Brainfuck.OUTPUT then
        table.insert(program, Brainfuck.OUTPUT)
        pc = pc + 1
      elseif c == Brainfuck.INPUT then
        table.insert(program, Brainfuck.INPUT)
        pc = pc + 1
      elseif c == Brainfuck.LOOP_S then
        if pc <= len - 2 and
          string.byte(source, pc + 1) == Brainfuck.SUB and
          string.byte(source, pc + 2) == Brainfuck.LOOP_E then
          table.insert(program, Brainfuck.ASSIGN_ZERO)
          pc = pc + 3
        else
          stack[stack_idx] = #program + 1
          stack_idx = stack_idx + 1
          table.insert(program, Brainfuck.LOOP_S)
          pc = pc + 1
        end
      elseif c == Brainfuck.LOOP_E then
        stack_idx = stack_idx - 1
        jump_table[stack[stack_idx]] = #program + 1
        jump_table[#program + 1] = stack[stack_idx]
        table.insert(program, Brainfuck.LOOP_E)
        pc = pc + 1
      else
        pc = pc + 1
      end
    end
    return program, jump_table
  end
EOF
  function! s:run(source)
    return luaeval('Brainfuck.execute(Brainfuck.compile(vim.eval("a:source")))')
  endfunction
else
  let s:NEXT   = 0x00 | lockvar s:NEXT
  let s:ADD    = 0x01 | lockvar s:ADD
  let s:OUTPUT = 0x02 | lockvar s:OUTPUT
  let s:INPUT  = 0x03 | lockvar s:INPUT
  let s:LOOP_S = 0x04 | lockvar s:LOOP_S
  let s:LOOP_E = 0x05 | lockvar s:LOOP_E
  let s:ASSIGN_ZERO = 0x06 | lockvar s:ASSIGN_ZERO
  let s:INST_DICT = {'>': s:NEXT, '<': s:NEXT, '+': s:ADD, '-': s:ADD}
  lockvar s:INST_DICT

  function! s:execute(compiled_source)
    let [l:program, l:jump_table] = a:compiled_source
    let l:len = len(l:program)
    let l:memory = repeat([0], 65536)
    let l:output = ''
    let l:dc = 0
    let l:pc = 0
    while l:pc < l:len
      let l:c = l:program[l:pc]
      if l:c == s:NEXT
        let l:pc += 1
        let l:dc += l:program[l:pc]
      elseif l:c == s:ADD
        let l:pc += 1
        let l:memory[l:dc] += l:program[l:pc]
      elseif l:c == s:OUTPUT
        let l:output .= nr2char(l:memory[l:dc])
      elseif l:c == s:INPUT
        let l:memory[l:dc] = char2nr(getchar())
      elseif l:c == s:LOOP_S
        if l:memory[l:dc] == 0
          let l:pc = l:jump_table[l:pc]
        endif
      elseif l:c == s:LOOP_E
        let l:pc = l:jump_table[l:pc] - 1
      elseif l:c == s:ASSIGN_ZERO
        let l:memory[l:dc] = 0
      endif
      let l:pc += 1
    endwhile
    return l:output
  endfunction


  function! s:compile(source)
    let l:program = []
    let l:jump_table = {}
    let l:stack = repeat([0], 256)
    let l:stack_idx = 0
    let l:pc = 0
    let l:len = strlen(a:source)
    while l:pc < l:len
      let l:c = a:source[l:pc]
      if l:c =~# '[><+-]'
        let l:cnt = 0
        while a:source[l:pc] ==# l:c
          let l:cnt += 1
          let l:pc += 1
        endwhile
        call add(l:program, s:INST_DICT[l:c])
        call add(l:program, l:c =~# '[>+]' ? l:cnt : -l:cnt)
      elseif l:c ==# '.'
        call add(l:program, s:OUTPUT)
        let l:pc += 1
      elseif l:c ==# ','
        call add(l:program, s:INPUT)
        let l:pc += 1
      elseif l:c ==# '['
        if l:pc < len - 2 && a:source[l:pc + 1] == '-' && a:source[l:pc + 2] == ']'
          call add(l:program, s:ASSIGN_ZERO)
          let l:pc += 3
        else
          let l:stack[l:stack_idx] = len(l:program)
          let l:stack_idx += 1
          call add(l:program, s:LOOP_S)
          let l:pc += 1
        endif
      elseif l:c ==# ']'
        let l:stack_idx -= 1
        let jump_table[l:stack[l:stack_idx]] = len(l:program)
        let jump_table[len(l:program)] = l:stack[l:stack_idx]
        call add(l:program, s:LOOP_E)
        let l:pc += 1
      else
        let l:pc += 1
      endif
    endwhile
    return [l:program, l:jump_table]
  endfunction


  function! s:run(source)
    return s:execute(s:compile(a:source))
  endfunction
endif


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
      if a:source[l:pc + 1] == '-' && a:source[l:pc + 2] == ']'
        let l:output .= repeat(a:istr, l:depth) . "*ptr = 0;\n"
        let l:pc += 3
      else
        let l:output .= repeat(a:istr, l:depth) . "while (*ptr) {\n"
        let l:depth += 1
        let l:pc += 1
      endif
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
