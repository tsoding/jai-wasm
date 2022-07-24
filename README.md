# Jai WebAssembly Proof-of-Concept

[![thumbnail](./img/thumbnail.png)](https://tsoding.org/jai-wasm/)

*Screenshot from [https://tsoding.org/jai-wasm/](https://tsoding.org/jai-wasm/)*

Jai does not officially support WebAssembly compilation target. BUT! It allows you to dump [LLVM Bitcode](https://llvm.org/docs/BitCodeFormat.html) via the `Llvm_Options.output_bitcode` flag. This Proof-of-Concept demonstrates how to exploit this feature to compile Jai program to WebAssembly.

## Quick Start

The compilation works only on Linux right now, sorry. You also need to have [Clang](https://clang.llvm.org/) installed on your machine.

```console
$ jai -version
Version: beta 0.1.031, built on 11 July 2022.
$ jai first.jai
$ python3 -m http.server 6969
$ iexplore.exe http://localhost:6969/
```

## How Does it Work?

For detailed information on how everything works I recommend to read the [./first.jai](./first.jai). The main idea is to dump the LLVM Bitcode of the compiled program and translate it with Clang to WebAssembly bytecode.

Also check out [./js/load.js](./js/load.js) which loads up the final WebAssembly module and sets up the environment for it.

### `#asm` Blocks

The library that comes with Jai uses quite a few `#asm` blocks. The problem is that they are not translatable to WebAssembly. We wrote a simple meta program in [./first.jai](./first.jai) that simply removes the blocks during the compilation and advises not to call the functions that had the `#asm` blocks. (If you have a better solution, please let me know).

### "invalid data symbol offset: `__type_table`" and 64 bits

If you ever tried to compile Jai to WebAssembly you are probably familiar with that error. It happens when you try to compile the program specifically to wasm32. Jai Compiler only supports 64 bit platform and does all of its data segments computations around 64 bit pointers (at least this is how I think it works). 

So to avoid that error you need to compiler with `--target=wasm64` flag of Clang which generates a binary with [memory64](https://github.com/WebAssembly/memory64) extension. But since this extension is experimental (yes, addressing memory with 64 bits is experimental in 2022...) such binary may not work everywhere. To make the binary more portable we convert it to wasm32 using [wasm64232](https://github.com/tsoding/wabt-wasm64232) utility.

### Calling to JavaScript Functions via the `libwasmstub` Dynamic Library Hack

TBD

### Passing the Context from JavaScript

Each Jai function (except the ones marked with `#no_context`) accepts implicit pointer to Context. If you want to enable the Jai code to use it you need to figure out that pointer in JavaScript and pass it accordingly.

TBD

## Contribution

If you have any questions, suggestions or something is not documented well feel free to file an Issue or a PR.
