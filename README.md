# Simple Jai to WASM Proof-of-Concept

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
