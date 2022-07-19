// This is the main file that we are compiling to WebAssembly and
// executing in load.js

#import "Basic";
#import "Math";
#import "Compiler";
#import "stb_image";

WIDTH :: 640;
HEIGHT :: 480;
BACKGROUND_COLOR : u32 : 0xFF181818;
LOGO_IMAGE :: #run bake_wasm_logo();

display : [HEIGHT*WIDTH]u32;
logo_position := Vector2.{100, 150};
logo_velocity := Vector2.{100, 120};

render :: (pixels: *u32) #foreign wasmstub;

Image :: struct {
    w: int;
    h: int;
    pixels: []u32;
}

bake_wasm_logo :: () -> Image {
    x, y: s32;
    pixels_data := stbi_load(temp_c_string("WebAssembly_Logo.png"), *x, *y, null, 4);
    defer stbi_image_free(pixels_data);

    pixels : []u8;
    pixels.data = pixels_data;
    pixels.count = x*y*4;
    pixels = add_global_data(pixels, .READ_ONLY);

    image : Image;
    image.pixels.data = cast(*u32) pixels.data;
    image.pixels.count = x*y;
    image.w = x;
    image.h = y;

    return image;
}

fill_rect :: (position: Vector2, size: Vector2, color: u32) {
    x0 := cast(int) floor(position.x);
    x1 := cast(int) floor(position.x + size.x);
    y0 := cast(int) floor(position.y);
    y1 := cast(int) floor(position.y + size.y);
    for y: y0..y1 {
        if !(0 <= y && y < HEIGHT) continue;
        for x: x0..x1 {
            if !(0 <= x && x < WIDTH) continue;
            display[y*WIDTH + x] = color;
        }
    }
}

color_as_vector :: (color: u32) -> Vector4 {
    r := ((color&0x000000FF)>>(4*0)) / 255.0;
    g := ((color&0x0000FF00)>>(4*2)) / 255.0;
    b := ((color&0x00FF0000)>>(4*4)) / 255.0;
    a := ((color&0xFF000000)>>(4*6)) / 255.0;
    return make_vector4(r, g, b, a);
}

color_as_u32 :: (using color: Vector4) -> u32 {
    r := (cast(u32) floor(x*255))<<(4*0);
    g := (cast(u32) floor(y*255))<<(4*2);
    b := (cast(u32) floor(z*255))<<(4*4);
    a := (cast(u32) floor(w*255))<<(4*6);
    return r|g|b|a;
}

mix_colors :: (a: Vector4, b: Vector4) -> Vector4 {
    return lerp(a, b, b.w);
}

mix_colors :: (a: u32, b: u32) -> u32 {
    return color_as_u32(mix_colors(color_as_vector(a), color_as_vector(b)));
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

fill_background :: () {
    for *display {
        <<it = BACKGROUND_COLOR;
    }
}

update :: (dt: float) {
    display_size :: Vector2.{WIDTH, HEIGHT};
    logo_size := make_vector2(cast(float) LOGO_IMAGE.w, cast(float) LOGO_IMAGE.h);

    for i: 0..1 {
        a := logo_position.component[i] + logo_velocity.component[i]*dt;
        if !(0 <= a && a + logo_size.component[i] < display_size.component[i]) {
            logo_velocity.component[i] *= -1;
            continue;
        }
        logo_position.component[i] = a;
    }

    fill_background();
    copy_image(LOGO_IMAGE, logo_position);
    render(display.data);
}

wasmstub :: #foreign_library "libwasmstub";

// Entry point that is required by the Jai compiler but completely ignored
// by the WebAssembly environment that loads up and executes this program
main :: () {}
