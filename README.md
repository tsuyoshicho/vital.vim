# vital.vim

A comprehensive Vim utility functions for Vim plugins.

This is like a plugin which has both aspects of [Bundler](http://gembundler.com/) and [jQuery](http://jquery.com/) at the same time.

## Targets

If you are a Vim user who don't make Vim plugins, please ignore this page.

If you are a Vim plugin author, please check this out.

## What vital.vim provides

* `system()`
    * If user has `vimproc`, this uses `vimproc#system()`, otherwise just the Vim builtin `system()`.
* ... (all public functions in [unite](https://github.com/Shougo/unite.vim)/util.

## How to use

Assuming your Vim plugin name is `ujihisa`. You can define your utility function set `ujihisa#util` just by

    let V = vital#of('ujihisa')
    function! ujihisa#util#system(...)
      return call(V.system, a:000)
    endfunction

and then you can call functions by `ujihisa#util#system()`, without taking care of `vital.vim` itself. It's all hidden.

Vital has module system.

    let O = vital#of('ujihisa').import('data.ordered_set')
    O.new

We recommend you to use a capital letter for a the Vital module dictionary to assign.

## Reference

* [Delegation in Vim script](http://ujihisa.blogspot.com/2011/02/delegation-in-vim-script.html)

## Author

Tatsuhiro Ujihisa