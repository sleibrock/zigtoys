const std = @import("std");
const io = std.io;

// extern functions refer to the exterior JS namespace
// when importing wasm code, the `print` func must be provided
extern fn print(i32) void;

const MAX_ITER: u8 = 255;
const WIDTH: f32 = 640.0;
const HEIGHT: f32 = 480.0;

export fn get_pixel_color(px: i32, py: i32) u8 {
    var iterations: u8 = 0;

    var x0 = @intToFloat(f32, px);
    var y0 = @intToFloat(f32, py);
    x0 = ((x0 / WIDTH) * 2.51) - 1.67;
    y0 = ((y0 / HEIGHT) * 2.24) - 1.12;
    var x: f32 = 0;
    var y: f32 = 0;
    var tmp: f32 = 0;
    var xsquare: f32 = 0;
    var ysquare: f32 = 0;

    while ((xsquare + ysquare < 4.0) and (iterations < MAX_ITER)) : (iterations += 1) {
        tmp = xsquare - ysquare + x0;
        y = 2 * x * y + y0;
        x = tmp;
        xsquare = x * x;
        ysquare = y * y;
    }
    return iterations;
}
