const NULL64 = 0n;

let app = document.getElementById("app");
let ctx = app.getContext("2d");

let w = null;
let context = null;

function find_name_by_regexp(exports, prefix) {
    const re = new RegExp('^'+prefix+'_[0-9a-z]+$');
    for (let name in exports) {
        if (re.test(name)) {
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

WebAssembly.instantiateStreaming(fetch('wasm/main32.wasm'), {
    "env": make_environment({
        "render": (pixels_ptr, width, height) => {
            app.width = width;
            app.height = height;
            const pixels = new Uint8ClampedArray(w.instance.exports.memory.buffer, Number(pixels_ptr), app.width*app.height*4);
            ctx.putImageData(new ImageData(pixels, app.width, app.height), 0, 0);
        },
        "write": (fd, buf, count) => {
            const buffer = w.instance.exports.memory.buffer;
            const bytes = new Uint8Array(buffer, Number(buf), Number(count));
            console.log(new TextDecoder().decode(bytes));
            return count;
        },
        "memset": (s, c, n) => {
            const buffer = w.instance.exports.memory.buffer;
            const bytes = new Uint8Array(buffer, Number(s), Number(n));
            bytes.fill(c);
            return s;
        },
        "set_context": (c) => context = c,
    })
}).then(w0 => {
    w = w0;
    const update = find_name_by_regexp(w.instance.exports, "update");

    w.instance.exports.main(0, NULL64);

    let prev = null;
    function first(timestamp) {
        prev = timestamp;
        window.requestAnimationFrame(loop);
    }
    function loop(timestamp) {
        const dt = timestamp - prev;
        prev = timestamp;
        update(context, BigInt(Math.floor(dt)));
        window.requestAnimationFrame(loop);
    }
    window.requestAnimationFrame(first);
}).catch(console.error);
