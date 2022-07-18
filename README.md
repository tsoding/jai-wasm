# Simple Jai to WASM Proof-of-Concept

Jai does not officially support WebAssembly compilation target. BUT! It allows you to dump LLVM IR via the `llvm_options.output_llvm_ir` flag. This Proof-of-Concept demonstrates how to exploit this feature to compile Jai program to WebAssembly.

## Quick Start

```console
$ jai -version
Version: beta 0.1.031, built on 11 July 2022.
$ jai first.jai
$ python3 -m http.server 6969
$ iexplore.exe http://localhost:6969/
```
