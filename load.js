// const fs = require('fs');

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
    }
}).then(wasmModule => {
    wasmModule.instance.exports.sum_800002316(34, 35, 0);
    console.log(new Uint32Array(wasmModule.instance.exports.memory.buffer)[0]);
}).catch(console.error);
