const NULL64 = 0n;
const EBADF = 9;

let app = document.getElementById("app");
let ctx = app.getContext("2d");

let w = null;
let context = null;
let output_buffer = "";

function find_name_by_regexp(exports, prefix) {
    const re = new RegExp('^'+prefix+'_[0-9a-z]+$');
    for (let name in exports) {
        if (re.test(name)) {
            return exports[name];
        }
    }
    return null;
}

function make_environment(...envs) {
    return new Proxy(envs, {
        get(target, prop, receiver) {
            for (let env of envs) {
                if (env.hasOwnProperty(prop)) {
                    return env[prop];
                }
            }
            return (...args) => {console.error("NOT IMPLEMENTED: "+prop, args)}
        }
    });
}

// Standard runtime
// TODO: The Standard Runtime is actually Linux specific!!!
// What I just realized is that if you try to compile this example on Windows, this
// entire runtime becomes invalid because it's a Linux runtime! So this specific runtime has
// to be different depending on the platform you are compiling it on! Cheesus...
const std = {
    "write": (fd, buf, count) => {
        let log = undefined;
        switch (fd) {
            case 1: log = console.log;   break;
            case 2: log = console.error; break;
            default: {
                console.error("write: Unsupported file descriptor "+fd);
                return -EBADF;
            }
        }
        const buffer = w.instance.exports.memory.buffer;
        const bytes = new Uint8Array(buffer, Number(buf), Number(count));
        let text = new TextDecoder().decode(bytes);
        let index = text.indexOf('\n');
        while (index >= 0) {
            output_buffer += text.slice(0, index);
            text = text.slice(index + 1);
            log(output_buffer);
            output = "";
            index = text.indexOf('\n');
        }
        if (text.length > 0) output_buffer += text;
        return count;
    },
    "memset": (s, c, n) => {
        const buffer = w.instance.exports.memory.buffer;
        const bytes = new Uint8Array(buffer, Number(s), Number(n));
        bytes.fill(c);
        return s;
    },
    "fabs": Math.abs,
    "powf": Math.pow,
    "set_context": (c) => context = c,
};

// Demo runtime
const demo = {
    "render": (pixels_ptr, width, height) => {
        const buffer = w.instance.exports.memory.buffer;
        app.width = width;
        app.height = height;
        const pixels = new Uint8ClampedArray(buffer, Number(pixels_ptr), app.width*app.height*4);
        ctx.putImageData(new ImageData(pixels, app.width, app.height), 0, 0);
    },
};

WebAssembly.instantiateStreaming(fetch('wasm/main32.wasm'), {
    "env": make_environment(std, demo)
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
