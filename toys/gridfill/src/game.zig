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
        gridx: u32,
        gridy: u32,
        rng: rng.NewType(u32),
        grid: types.ColorList,

        pub fn init(ren: *R, alloc: mem.Allocator) Self {
            return Self{
                .render = ren,
                .size = 0,
                .boxsize = 0,
                .gridx = 0,
                .gridy = 0,
                .rng = RNG.init(0),
                .grid = types.ColorList.init(alloc),
            };
        }

        pub fn setDimensions(this: *Self, size: u32) u32 {
            if (size > this.size) {
                this.grid.resize(size) catch |err| {
                    switch (err) {
                        else => { return 0; },
                    }
                };
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
            this.gridx = 10;
            this.gridy = 10;
            return r;
        }

        pub fn size2(this: *Self) u32 {
            // 16x16 grid, 256 cells
            const r = this.setDimensions(256);
            this.boxsize = 30;
            this.gridx = 16;
            this.gridy = 16;
            return r;
        }

        pub fn size3(this: *Self) u32 {
            // 20x20 grid, 400 cells
            this.gridx = 20;
            this.gridy = 20;
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
                    randcol = .Wall;
                }
                this.grid.items[index] = randcol; 
            }
        }


        pub fn switchColor(this: *Self, color: types.ColorT) void {
            switch (color) {
                .Color1 => { this.render.setColor(255, 0, 0, 255); },
                .Color2 => { this.render.setColor(0, 255, 0, 255); },
                .Color3 => { this.render.setColor(0, 0, 255, 255); },
                .Color4 => { this.render.setColor(255, 255, 0, 255); },
                .Color5 => { this.render.setColor(255, 0, 255, 255); },
                .Color6 => { this.render.setColor(0, 255, 255, 255); },
                .Color7 => { this.render.setColor(127, 127, 0, 255); },
                .Color8 => { this.render.setColor(0, 127, 127, 255); },
                .Wall => { this.render.setColor(30, 30, 30, 255); },
            }
        }

        pub fn renderSquare(this: *Self, index: usize, x: u32, y: u32) void {
            if (index > this.size)
                return;
            this.switchColor(this.grid.items[index]);
            this.render.fillRect(x, y, this.boxsize, this.boxsize);
            return;
        }


        pub fn renderGrid(this: *Self) void {
            var index: usize = 0;
            var currX: u32 = 0;
            var currY: u32 = 0;
            var px: u32 = 0;
            var py: u32 = 0;

            while (currY < this.gridy) : (currY += 1) {
                currX = 0;
                px = 0;
                while (currX < this.gridx) : (currX += 1) {
                    this.renderSquare(index, px, py);
                    px += this.boxsize;
                    index += 1;
                }
                py += this.boxsize;
            }
            return;
        }

        pub fn handle_click(x: u32, y: u32) void {
            _ = x;
            _ = y;
        }
    };
}
