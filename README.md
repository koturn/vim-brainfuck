vim-brainfuck
=============


## Summary

A brainfuck interpreter and C-translator for Vim.


## Features of this interpreter

Following features contribute to the speed of the interpreter.

- Compile phase
- Jump table
- Use ```if_lua```


## Installation

### Manual

Put files in your Vim directory.

- In Windows
  - Vim directory is ```%HOME%/vimfiles/```
- Others
  - Vim directory is ```~/.vim/```


### NeoBundle

Write following settings in your ```.vimrc```, and execute ```NeoBundle Install```.

```vim
NeoBundle 'koturn/vim-brainfuck'
```

If you want to use ```NeoBundleLazy``` anyway, write following settings.

```vim
NeoBundleLazy 'koturn/vim-brainfuck'
if neobundle#tap('vim-brainfuck')
  call neobundle#config({
        \ 'commands' : ['BFExecute', 'BFTranslate2C'],
        \ 'filetypes' : 'brainfuck'
        \})
  " autocmd BufNewFile,BufRead *.b,*.brainfuck  setfiletype brainfuck
  autocmd AN_AU_GROUP BufNewFile,BufRead *.b,*.brainfuck  setfiletype brainfuck
  call neobundle#untap()
endif
```


## Usage

This plugin provides two commands; ```BFExecute``` and ```BFtranslate2C```.

First, open brainfuck source code in a current buffer.
Second, execute ```BFExecute``` or ```BFtranslate2C```.

If you want to know how much it takes to run brainfuck program, please write
following settings in your ```.vimrc```.

```vim
g:brainfuck#verbose = 1
```


## LICENSE

This software is released under the MIT License, see LICENSE.
