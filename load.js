// const fs = require('fs');

function find_name_by_prefix(exports, prefix) {
    for (let name in exports) {
        if (name.startsWith(prefix)) {
            return exports[name];
        }
    }
    return null;
}

WebAssembly.instantiateStreaming(fetch('./main_fixed.wasm'), {
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
    console.log(sum);
    sum(34n, 35n, 0);
    console.log(new Uint32Array(wasmModule.instance.exports.memory.buffer)[0]);
}).catch(console.error);
