// This is the main file that we are compiling to WebAssembly and
// executing in load.js

// This function is called by load.js
sum :: (a: int, b: int) -> int #no_context {
    return bar(a, b);
}

// This function is implemented in load.js and calls back into JavaScript code
bar :: (a: int, b: int) -> int #foreign wasmstub;

// This is a foreign dynamic library that is implemented in wasmstub.c.
// The point of this library is to trick the Jai compiler into thinking
// that bar() is an external function so the final WebAssembly blobs
// declares it as an external as well.
//
// The actual bar() implementation is provided by load.js
wasmstub :: #foreign_library "libwasmstub";

// Entry point that is required by the Jai compiler but completely ignored
// by the WebAssembly environment that loads up and executes this program
main :: () {}
