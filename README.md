# Simple Jai to WASM example

## Quick Start

First, apply [jai-no-asm.patch](./jai-no-asm.patch) to your Jai distribution (make sure that you are using beta 0.1.027). It tries to get rid of `#asm` blocks because they are not compilable to WASM.

```console
$ jai -version
Version: beta 0.1.027, built on 5 June 2022.
$ jai first.jai
$ ./build-wasm.sh
$ python3 -m http.server 6969
$ iexplore.exe http://localhost:6969/
```
