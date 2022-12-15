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

// end types.zig
