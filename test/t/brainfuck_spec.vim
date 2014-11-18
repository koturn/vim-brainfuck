let s:ROOT_DIR = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
lockvar s:ROOT_DIR
execute 'set' 'rtp +=./' . s:ROOT_DIR
runtime! plugin/brainfuck.vim

describe 'vim-brainfuck'
  before
    new
  end

  after
    close!
    close!
  end

  it 'Hello, world!'
    edit ./bfSamples/hello.b
    BFExecute
    Expect getline(1) ==# 'Hello, world!'
  end

  it 'FizzBuzz'
    edit ./bfSamples/fizzbuzz.b
    BFExecute
    Expect getline(1)   ==# '1'
    Expect getline(3)   ==# 'Fizz'
    Expect getline(5)   ==# 'Buzz'
    Expect getline(15)  ==# 'FizzBuzz'
    Expect getline(98)  ==# '98'
    Expect getline(99)  ==# 'Fizz'
    Expect getline(100) ==# 'Buzz'
  end
end
