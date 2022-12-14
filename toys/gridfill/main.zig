// main.zig

//const std = @import("std");
const world = @import("src/world.zig");
const rng = @import("src/rng.zig");

const EntityT = enum(u8) {};
const Entity = struct {};

// init the basic comptime types
const RNG = rng.NewType(u32);
const WorldT = world.createWorldT(Entity, 1000 * 1000 * 4);

var GameWorld = WorldT.init();

export fn init(wx: u32, wy: u32, seed: u32) u32 {
    _ = wx;
    _ = wy;
    _ = seed;
    return 0;
}

export fn startAddr() *[1000 * 1000 * 4]u8 {
    return &GameWorld.vbuf;
}

export fn getSize() u32 {
    return GameWorld.width * GameWorld.height * 4;
}

export fn getWidth() u32 {
    return GameWorld.width;
}

export fn getHeight() u32 {
    return GameWorld.height;
}

export fn update() void {
    GameWorld.fillBuffer(255); // clear screen
}

export fn atAddr(x: u32) u8 {
    return GameWorld.vbuf[x];
}

//
