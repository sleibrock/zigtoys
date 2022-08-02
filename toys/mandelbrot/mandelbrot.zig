const std = @import("std");
const io = std.io;

// extern functions refer to the exterior JS namespace
// when importing wasm code, the `print` func must be provided
extern fn print(i32) void;

export fn add(a: i32, b: i32) void {
    print(a + b);
}
