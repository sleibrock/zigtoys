// game.zig - game state and logic applications

const std = @import("std");
const mem = std.mem;

const rng = @import("rng.zig");
const types = @import("types.zig");
const render = @import("render.zig");

const RNG = rng.NewType(u32);


pub fn createGameT(comptime R: type) type {
    return struct {
        const Self = @This();

        render: *R,
        size: u32,
        boxsize: u32,
        rng: rng.NewType(u32),
        grid: types.ColorList,

        pub fn init(ren: *R, alloc: mem.Allocator) Self {
            return Self{
                .render = ren,
                .size = 0,
                .boxsize = 0,
                .rng = RNG.init(0),
                .grid = types.ColorList.init(alloc),
            };
        }

        pub fn setDimensions(this: *Self, size: u32) u32 {
            if (size > this.size) {
                this.grid.resize(size);
            } else {
                this.grid.shrinkAndFree(size);
            }
            this.size = size;
            return size;
        }

        pub fn size1(this: *Self) u32 {
            // 10x10 grid, 100 cells
            const r = this.setDimensions(100);
            this.boxsize = 48;
            return r;
        }

        pub fn size2(this: *Self) u32 {
            // 16x16 grid, 256 cells
            const r = this.setDimensions(256);
            this.boxsize = 30;
            return r;
        }

        pub fn size3(this: *Self) u32 {
            // 20x20 grid, 400 cells
            return this.setDimensions(400);
        }

        pub fn randomizeGrid(this: *Self) void {
            // randomize the grid using the world RNG
            var index: usize = 0;
            var randnum: f32 = 0;
            var randcol: types.ColorT = .Color1;
            while (index < this.size) : (index += 1) {
                randnum = this.rng.random();
                if (randnum < 0.1) {
                    randcol = .Color1;
                } else if (randnum < 0.2) {
                    randcol = .Color2;
                } else if (randnum < 0.3) {
                    randcol = .Color3;
                } else if (randnum < 0.4) {
                    randcol = .Color4;
                } else if (randnum < 0.5) {
                    randcol = .Color5;
                } else if (randnum < 0.6) {
                    randcol = .Color7;
                } else if (randnum < 0.7) {
                    randcol = .Color8;
                } else if (randnum < 0.9) {
                    randcol = .Block;
                }
                this.grid.items[index] = randcol; 
            }
        }

        pub fn handle_click(x: u32, y: u32) void {
            _ = x;
            _ = y;
        }
    };
}
