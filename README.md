vim-brainfuck
=============


## Summary

A brainfuck interpreter and C-translator for Vim.


## Features of interpreter

Following features contribute to the speed of the interpreter.

- Compile phase
- Jump table
- Use ```if_lua```


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
