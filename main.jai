// This is the main file that we are compiling to WebAssembly and
// executing in load.js

#import "Basic";
#import "Math";
#import "Compiler";
#import "stb_image";
#import "stb_image_resize";

WIDTH :: 640;
HEIGHT :: 480;
BACKGROUND_COLOR : u32 : 0xFF181818;
LOGO_IMAGE :: #run bake_wasm_logo(128, 128);

display : [HEIGHT*WIDTH]u32;
logo_position := Vector2.{100, 150};
logo_velocity := Vector2.{100, 120};

render :: (pixels: *u32) #foreign wasmstub;

Image :: struct {
    w: int;
    h: int;
    pixels: []u32;
}

bake_wasm_logo :: (w: s32, h: s32) -> Image {
    x, y: s32;
    original_pixels_data := stbi_load(temp_c_string("WebAssembly_Logo.png"), *x, *y, null, 4);
    defer stbi_image_free(original_pixels_data);

    resized_pixels_data := alloc(w*h*4);
    defer free(resized_pixels_data);
    stbir_resize_uint8(original_pixels_data, x, y, x*4,
                       resized_pixels_data, w, h, w*4,
                       num_channels = 4);

    pixels : []u8;
    pixels.data = resized_pixels_data;
    pixels.count = w*h*4;
    pixels = add_global_data(pixels, .READ_ONLY);

    image : Image;
    image.pixels.data = cast(*u32) pixels.data;
    image.pixels.count = w*h;
    image.w = w;
    image.h = h;

    return image;
}

mix_colors :: (c0: u32, c1: u32) -> u32 {
    // ra, rb, alpha
    // alpha = 0..255
    // ra + (rb - ra)*(alpha/0xFF)
    // ra + alpha*(rb - ra)/0xFF

    r0, g0, b0, a0 := unpack_color(c0);
    r1, g1, b1, a1 := unpack_color(c1);
    alpha := a1;

    r := r0 + alpha*(r1 - r0)/0xFF;
    g := g0 + alpha*(g1 - g0)/0xFF;
    b := b0 + alpha*(b1 - b0)/0xFF;
    a := a0 + alpha*(a1 - a0)/0xFF;

    return pack_color(r, g, b, a);
}

copy_image :: (using image: Image, position: Vector2) {
    for dy: 0..h-1 {
        y := cast(int) floor(position.y + dy);
        if !(0 <= y && y < HEIGHT) continue;
        for dx: 0..w-1 {
            x := cast(int) floor(position.x + dx);
            if !(0 <= x && x < WIDTH) continue;
            display[y*WIDTH + x] = mix_colors(display[y*WIDTH + x], pixels[dy*w + dx]);
        }
    }
}

unpack_color :: (c: u32) -> s32, s32, s32, s32 {
    r := cast(s32) ((c >> (0*4))&0xFF);
    g := cast(s32) ((c >> (2*4))&0xFF);
    b := cast(s32) ((c >> (4*4))&0xFF);
    a := cast(s32) ((c >> (6*4))&0xFF);
    return r, g, b, a;
}

pack_color :: (r0: s32, g0: s32, b0: s32, a0: s32) -> u32 {
    r := (cast(u32) r0) << (0*4);
    g := (cast(u32) g0) << (2*4);
    b := (cast(u32) b0) << (4*4);
    a := (cast(u32) a0) << (6*4);
    return r|g|b|a;
}

patch_background :: (x: int, y: int, w: int, h: int) {
    x0 := x;
    x1 := x + w - 1;
    y0 := y;
    y1 := y + h - 1;
    for y: y0..y1 {
        if !(0 <= y && y < HEIGHT) continue;
        for x: x0..x1 {
            if !(0 <= x && x < WIDTH) continue;
            u := x*255/WIDTH;
            v := y*255/HEIGHT;
            display[y*WIDTH + x] = pack_color(cast(u8) u, 0xFF, cast(u8) v, 0xFF);
        }
    }
}

fill_background :: () {
    patch_background(0, 0, WIDTH, HEIGHT);
}

init_game :: () {
    fill_background();
}

update :: (dt: float) {
    display_size :: Vector2.{WIDTH, HEIGHT};
    logo_size := make_vector2(cast(float) LOGO_IMAGE.w, cast(float) LOGO_IMAGE.h);

    patch_background(
        xx logo_position.x - 1, xx logo_position.y - 1,
        xx logo_size.x + 2, xx logo_size.y + 2);

    for i: 0..1 {
        a := logo_position.component[i] + logo_velocity.component[i]*dt;
        if !(0 <= a && a + logo_size.component[i] < display_size.component[i]) {
            logo_velocity.component[i] *= -1;
            continue;
        }
        logo_position.component[i] = a;
    }

    copy_image(LOGO_IMAGE, logo_position);
    render(display.data);
}

wasmstub :: #foreign_library "libwasmstub";

// Entry point that is required by the Jai compiler but completely ignored
// by the WebAssembly environment that loads up and executes this program
main :: () {}
