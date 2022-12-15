// world.zig - a generic-ish worldly container of sorts

const std = @import("std");
const mem = std.mem;

const types = @import("types.zig");
const rng = @import("rng.zig");

pub fn createWorldT() type {

    const RNG = rng.NewType(u32);
    return struct {
        width: u32,
        height: u32,
        size: u32,
        rng: RNG, 
        vbuf: types.ByteList,

        const Self = @This();

        pub fn init(alloc: mem.Allocator) Self {
            return Self{
                .width = 0,
                .height = 0,
                .size = 0,
                .rng = RNG.init(0),
                .vbuf = types.ByteList.init(alloc),
            };
        }

        pub fn setResolution(this: *Self, w: u32, h: u32) u32 {
            var new_size: u32 = w * h * 4;
            if (new_size > this.size) {
                // resize operation
                this.vbuf.resize(new_size) catch |err| {
                    switch (err) {
                        else => { return 0; }
                    }
                };
            } else {
                // shrink operation, must free data
                this.vbuf.shrinkAndFree(new_size);
            }
            this.width = w;
            this.height = h;
            this.size = new_size;
            return new_size;
        }

        pub fn calcPos(this: *Self, x: u32, y: u32) u32 {
            var res: u32 = (y * this.height) + x;
            if (res > this.size) {
                return 0;
            }
            return ((y * this.height) + x);
        }

        pub fn fillBuffer(this: *Self, v: u8) void {
            var index: usize = 0;
            while (index < this.size) : (index += 1) {
                this.vbuf.items[index] = v;
            }
            return;
        }

        pub fn setRGB(this: *Self, x: u32, y: u32, r: u8, g: u8, b: u8) void {
            const pos = this.calcPos(x, y);
            this.vbuf.items[pos] = r;
            this.vbuf.items[pos + 1] = g;
            this.vbuf.items[pos + 2] = b;
            return;
        }

        pub fn setRGBA(this: *Self, x: u32, y: u32, r: u8, g: u8, b: u8, a: u8) void {
            const pos = this.calcPos(x, y);
            this.vbuf.items[pos] = r;
            this.vbuf.items[pos + 1] = g;
            this.vbuf.items[pos + 2] = b;
            this.vbuf.items[pos + 3] = a;
            return;
        }
    };
}
