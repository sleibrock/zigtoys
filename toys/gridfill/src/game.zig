// game.zig - game state and logic applications

const std = @import("std");
const mem = std.mem;

const types = @import("types.zig");


pub fn createGameT(comptime W: type) type {
    return struct {
        const Self = @This();

        world: *W,
        grid: types.ByteList,

        pub fn init(world: *W, alloc: mem.Allocator) Self {
            return Self{
                .world = world,
                .grid = types.ByteList.init(alloc),
            };
        }

        pub fn handle_click(x: u32, y: u32) void {
            _ = x;
            _ = y;
        }
    };
}
