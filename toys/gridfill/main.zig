// main.zig

const std = @import("std");
const alloc = std.heap.page_allocator;

const world = @import("src/world.zig");
const game = @import("src/game.zig");


// max 1000x1000 buffer with 24-bit channel
const MBUFSIZE = 640*480*4;

const EntityT = enum(u8) {};
const Entity = struct {};

// init the basic comptime types
const WorldT = world.createWorldT();
const GameT = game.createGameT(WorldT); 

var World = WorldT.init(alloc);
var Game = GameT.init(&World, alloc);


export fn init(wx: u32, wy: u32, seed: u32) u32 {
    var bytes_allocd = Game.world.setResolution(wx, wy);
    if (bytes_allocd == 0) {
        return 0; // error resizing game world
    }
    Game.world.fillBuffer(255);
    _ = seed;
    return bytes_allocd;
}

export fn startAddr() *u8 {
    return &World.vbuf.items[0];
}

export fn getSize() u32 {
    return World.width * World.height * 4;
}

export fn getWidth() u32 {
    return World.width;
}

export fn getHeight() u32 {
    return World.height;
}

export fn atAddr(x: u32) u8 {
    return World.vbuf.items[x];
}

export fn update() void {
}

export fn handle_input(x: u32, y: u32) void {
    // handle mouse input and update the game world
    _ = x;
    _ = y;

}


//
