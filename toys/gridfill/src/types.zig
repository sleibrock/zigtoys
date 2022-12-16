// types.zig
const std = @import("std");

pub const ByteList = std.ArrayList(u8);

pub const ColorT = enum(u8) {
    Color1,
    Color2,
    Color3,
    Color4,
    Color5,
    Color6,
    Color7,
    Color8,
    Wall,
};

pub const ColorList = std.ArrayList(ColorT);

pub const RGBA = packed struct {
    r: u8, g: u8, b: u8, a: u8,
};

// end types.zig
