// game.zig - game state and logic applications

const std = @import("std");
const mem = std.mem;

const rng = @import("rng.zig");
const types = @import("types.zig");
const render = @import("render.zig");

const RNG = rng.NewType(u32);
const MAXSTACK: u8 = 255;

const Cord = struct {
    x: u32,
    y: u32,
};

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
        stack: [MAXSTACK]Cord,
        stacksize: u8,

        pub fn init(ren: *R, alloc: mem.Allocator) Self {
            return Self{
                .render = ren,
                .size = 0,
                .boxsize = 0,
                .gridx = 0,
                .gridy = 0,
                .rng = RNG.init(0),
                .grid = types.ColorList.init(alloc),
                .stack = undefined,
                .stacksize = 0,
            };
        }

        pub fn setDimensions(this: *Self, size: u32) u32 {
            if (size > this.size) {
                this.grid.resize(size) catch |err| {
                    switch (err) {
                        else => {
                            return 0;
                        },
                    }
                };
            } else {
                this.grid.shrinkAndFree(size);
            }
            this.size = size;
            return size;
        }

        pub fn getColor(this: *Self, x: u32, y: u32) types.ColorT {
            return this.grid.items[(y * this.gridx) + x];
        }

        pub fn setColor(this: *Self, x: u32, y: u32, c: types.ColorT) void {
            this.grid.items[(y * this.gridx) + x] = c;
            return;
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
                    randcol = .Color6;
                } else if (randnum < 0.7) {
                    randcol = .Color7;
                } else if (randnum < 0.8) {
                    randcol = .Color8;
                } else {
                    randcol = .Color1;
                }
                this.grid.items[index] = randcol;
            }
        }

        pub fn switchColor(this: *Self, color: types.ColorT) void {
            switch (color) {
                .Color1 => {
                    // red
                    this.render.setColor(240, 0, 0, 255);
                },
                .Color2 => {
                    // pink
                    this.render.setColor(250, 0, 247, 255);
                },
                .Color3 => {
                    // purple
                    this.render.setColor(127, 0, 126, 255);
                },
                .Color4 => {
                    // tan
                    this.render.setColor(250, 204, 130, 255);
                },
                .Color5 => {
                    // light blue
                    this.render.setColor(0, 250, 249, 255);
                },
                .Color6 => {
                    // dark blue
                    this.render.setColor(100, 100, 250, 255);
                },
                .Color7 => {
                    // green
                    this.render.setColor(0, 250, 10, 255);
                },
                .Color8 => {
                    // yellow
                    this.render.setColor(250, 249, 0, 255);
                },
                .Wall => {
                    // dark grey
                    this.render.setColor(30, 30, 30, 255);
                },
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

        /// Help locate a point in a range of values by stepping through
        /// and checking if a point is "underneath" a value, counting
        /// the times we add up to keep bumping our range.
        /// (This avoids hard division)
        pub fn locate(this: *Self, v: u32, max: u32) u32 {
            var adder: u32 = this.boxsize; // keeps track of pixels
            var index: u32 = 0; // keeps track of how many times we add
            while (index < max) : (index += 1) {
                if (adder > v) {
                    return index;
                }
                adder += this.boxsize;
            }
            return index;
        }

        pub fn handle_click(this: *Self, x: u32, y: u32) u32 {
            if (this.render.oob(x, y))
                return 0;
            
            var tx = this.locate(x, this.gridx);
            var ty = this.locate(y, this.gridy);
            var col = this.getColor(tx, ty);

            if (col == this.getColor(0, 0))
                return 0; // avoid refilling same color

            var num_painted: u32 = this.floodColor(col);

            this.renderGrid();

            return num_painted;
        }

        /// The floodpainting algorithm is a tricky one, as normal
        /// graph traversal algorithms rely on dynamic backtracking
        /// and state referencing to identify cells already covered.
        ///
        /// The goal is to provide a non-allocating solution and
        /// create a very minimal approach to filling a grid with
        /// colors. Uses a stack-based approach with a small
        /// stack to provide a reasonably fast grid filling system.
        /// May revisit tiles but at most can probably only visit
        /// tiles at max 4 times each, which equates to 400*4=1600
        pub fn floodColor(this: *Self, color: types.ColorT) u32 {
            var px: u32 = 0;
            var py: u32 = 0;
            var cells_painted: u32 = 0;

            // clear the stack out
            this.stacksize = 0;
            var index: usize = 0;
            while (index < MAXSTACK) : (index += 1) {
                this.stack[index] = Cord{ .x = 0, .y = 0 };
            }

            // get our current color (the one to replace)
            const old_color: types.ColorT = this.getColor(px, py);

            // set the stacksize to 1
            // 0th cell is set to (0,0) a few lines ago
            this.stacksize += 1;

            // allot a var to be a cord type
            var currC = this.stack[0];

            // continue to paint until we effectively hit our old destination
            while (this.stacksize > 0) {
                currC = this.stack[this.stacksize];
                px = currC.x;
                py = currC.y;

                // set the current cell's color
                this.setColor(px, py, color);
                this.stacksize -= 1;
                cells_painted += 1;

                // check for friends in the other cardinal directions
                if ((px > 0) and (this.stacksize < MAXSTACK)) {
                    if (this.getColor(px - 1, py) == old_color) {
                        this.stacksize += 1;
                        this.stack[this.stacksize].x = px - 1;
                        this.stack[this.stacksize].y = py;
                    }
                }
                if ((py > 0) and (this.stacksize < MAXSTACK)) {
                    if (this.getColor(px, py - 1) == old_color) {
                        this.stacksize += 1;
                        this.stack[this.stacksize].x = px;
                        this.stack[this.stacksize].y = py - 1;
                    }
                }
                if ((px < this.gridx) and (this.stacksize < MAXSTACK)) {
                    if (this.getColor(px + 1, py) == old_color) {
                        this.stacksize += 1;
                        this.stack[this.stacksize].x = px + 1;
                        this.stack[this.stacksize].y = py;
                    }
                }
                if ((py < this.gridy) and (this.stacksize < MAXSTACK)) {
                    if (this.getColor(px, py + 1) == old_color) {
                        this.stacksize += 1;
                        this.stack[this.stacksize].x = px;
                        this.stack[this.stacksize].y = py + 1;
                    }
                }
            }

            return cells_painted;
        }
    };
}

// end game.zig
