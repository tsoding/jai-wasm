function find_name_by_prefix(exports, prefix) {
    for (let name in exports) {
        if (name.startsWith(prefix)) {
            return exports[name];
        }
    }
    return null;
}

WebAssembly.instantiateStreaming(fetch('./main_fixed.wasm'), {
    // TODO: is it possible to come up with magical object that acts
    // like a table and for any unknown names returns the function that
    // prints the "NOT IMPLEMENTED" message?
    //
    // Maybe via Proxy: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy
    // 
    // This would be useful in case the set of functions that require such stub
    // changes between the version of the compiler.
    "env": {
        "memset": (...args) => {console.error("NOT IMPLEMENTED: memset", args)},
        "malloc": (...args) => {console.error("NOT IMPLEMENTED: malloc", args)},
        "realloc": (...args) => {console.error("NOT IMPLEMENTED: realloc", args)},
        "free": (...args) => {console.error("NOT IMPLEMENTED: free", args)},
        "memcpy": (...args) => {console.error("NOT IMPLEMENTED: memcpy", args)},
        "stbsp_sprintf": (...args) => {console.error("NOT IMPLEMENTED: stbsp_sprintf", args)},
        "memcmp": (...args) => {console.error("NOT IMPLEMENTED: memcmp", args)},
        "write": (...args) => {console.error("NOT IMPLEMENTED: write", args)},
        "pthread_mutexattr_init": (...args) => {console.error("NOT IMPLEMENTED: pthread_mutexattr_init", args)},
        "pthread_mutexattr_settype": (...args) => {console.error("NOT IMPLEMENTED: pthread_mutexattr_settype", args)},
        "pthread_mutex_init": (...args) => {console.error("NOT IMPLEMENTED: pthread_mutex_init", args)},
        "pthread_mutex_lock": (...args) => {console.error("NOT IMPLEMENTED: pthread_mutex_lock", args)},
        "pthread_mutex_unlock": (...args) => {console.error("NOT IMPLEMENTED: pthread_mutex_unlock", args)},
        "bar": (a, b) => {
            console.log("YEP! Jai just called to JavaScript! It's a JaiScript now! LULW");
            return a + b + 1000000n;
        }
    }
}).then(wasmModule => {
    const sum = find_name_by_prefix(wasmModule.instance.exports, "sum_");
    sum(34n, 35n, 0);
    // NOTE: We are just writing the result of the sum() to address 0.
    // It probably corrupts something in the memory.
    // Everything works completely accidentally.
    // But it works.
    console.log(new Uint32Array(wasmModule.instance.exports.memory.buffer)[0]);
}).catch(console.error);
