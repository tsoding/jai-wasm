function find_name_by_prefix(exports, prefix) {
    for (let name in exports) {
        if (name.startsWith(prefix)) {
            return exports[name];
        }
    }
    return null;
}

function make_environment(env) {
    return new Proxy(env, {
        get(target, prop, receiver) {
            if (!env.hasOwnProperty(prop)) {
                return (...args) => {console.error("NOT IMPLEMENTED: "+prop, args)}
            }
            return env[prop];
        }
    });
}

WebAssembly.instantiateStreaming(fetch('./main32.wasm'), {
    "env": make_environment({
        "JavaScript_function_called_by_JAI": (a, b) => {
            console.log("YEP! Jai just called to JavaScript! It's a JaiScript now! KEKW");
            return a + b + 1000000n;
        }
    })
}).then(wasmModule => {
    const JAI_function_called_by_JavaScript = find_name_by_prefix(wasmModule.instance.exports, "JAI_function_called_by_JavaScript_");
    JAI_function_called_by_JavaScript(34n, 35n, 0n);
    // NOTE: We are just writing the result of the JAI_function_called_by_JavaScript() to address 0.
    // It probably corrupts something in the memory.
    // Everything works completely accidentally.
    // But it works.
    console.log(new Uint32Array(wasmModule.instance.exports.memory.buffer)[0]);
}).catch(console.error);
