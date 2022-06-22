wasmstub :: #foreign_library "libwasmstub";

bar :: (a: int, b: int) -> int #foreign wasmstub;

sum :: (a: int, b: int) -> int #no_context {
    return bar(a, b);
}

main :: () {
    // Entry point that is required by the Jai compiler but completely ignored
    // by the WebAssembly environment that loads up and executes this program
}
