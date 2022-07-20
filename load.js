const NULL64 = 0n;
// TODO: duplicate resolution definition
// Come up with a better way of communicating resolution between JS and WASM environments

let app = document.getElementById("app");
app.width = 640;
app.height = 480;
let ctx = app.getContext("2d");

let w = null;

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
        "render": (pixels_ptr) => {
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
        }
    })
}).then(w0 => {
    w = w0;
    const update = find_name_by_prefix(w.instance.exports, "update_");
    const init_game = find_name_by_prefix(w.instance.exports, "init_game_");

    init_game(NULL64);

    let prev = null;
    function first(timestamp) {
        prev = timestamp;
        window.requestAnimationFrame(loop);
    }
    function loop(timestamp) {
        const dt = timestamp - prev;
        prev = timestamp;
        update(NULL64, BigInt(Math.floor(dt)));
        window.requestAnimationFrame(loop);
    }
    window.requestAnimationFrame(first);
}).catch(console.error);
