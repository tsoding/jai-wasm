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

WebAssembly.instantiateStreaming(fetch('./main_fixed.wasm'), {
    "env": make_environment({
        "bar": (a, b) => {
            console.log("YEP! Jai just called to JavaScript! It's a JaiScript now! LULW");
            return a + b + 1000000n;
        }
    })
}).then(wasmModule => {
    const sum = find_name_by_prefix(wasmModule.instance.exports, "sum_");
    sum(34n, 35n, 0);
    // NOTE: We are just writing the result of the sum() to address 0.
    // It probably corrupts something in the memory.
    // Everything works completely accidentally.
    // But it works.
    console.log(new Uint32Array(wasmModule.instance.exports.memory.buffer)[0]);
}).catch(console.error);
