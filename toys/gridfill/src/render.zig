// render.zig - an interface for rendering visuals

const std = @import("std");
const mem = std.mem;

const types = @import("types.zig");
const rng = @import("rng.zig");

pub const RenderSettings = struct {
    use_alpha: bool,
};

// Employ a generic settings
pub const DefaultSettings = RenderSettings{
    .use_alpha = true,
};

pub fn createRenderT(comptime Settings: RenderSettings) type {
    return struct {
        width: u32,
        height: u32,
        size: u32,
        use_alpha: bool,
        current_color: types.RGBA,
        vbuf: types.ByteList,

        const Self = @This();

        pub fn init(alloc: mem.Allocator) Self {
            return Self{
                .width = 0,
                .height = 0,
                .size = 0,
                .use_alpha = false,
                .current_color = undefined,
                .vbuf = types.ByteList.init(alloc),
            };
        }

        pub fn setColor(this: *Self, r: u8, g: u8, b: u8, a: u8) void {
            this.current_color.r = r;
            this.current_color.g = g;
            this.current_color.b = b;
            this.current_color.a = a;
        }

        /// Use this to determine if pixel (x,y) is out-of-bounds
        /// More valid to use this than calcPos() as calcPos() returns min-zero
        pub fn oob(this: *Self, x: u32, y: u32) bool {
            return ((x < 0) or (y < 0) or (x >= this.width) or (y >= this.height));
        }

        /// Attempt to set a new resolution of the renderer
        /// Yields zero as a "failure"
        pub fn setResolution(this: *Self, w: u32, h: u32) u32 {
            var new_size: u32 = w * h * 4;
            if (new_size > this.size) {
                // resize operation
                this.vbuf.resize(new_size) catch |err| {
                    switch (err) {
                        else => {
                            return 0;
                        },
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

        /// Calc the position of a given (x,y) in the buffer
        /// Not a valid way of determining oob
        pub fn calcPos(this: *Self, x: u32, y: u32) u32 {
            var res: u32 = ((y * this.width) + x) * 4;
            if (res > this.size) {
                return 0;
            }
            return res;
        }

        /// fill all elements of the buffer with a given u8
        pub fn fillBuffer(this: *Self, v: u8) void {
            var index: usize = 0;
            while (index < this.size) : (index += 1) {
                this.vbuf.items[index] = v;
            }
            return;
        }

        ///
        pub fn setPixel(this: *Self, x: u32, y: u32) void {
            if (this.oob(x, y))
                return;
            const pos = this.calcPos(x, y);
            this.vbuf.items[pos] = this.current_color.r;
            this.vbuf.items[pos + 1] = this.current_color.g;
            this.vbuf.items[pos + 2] = this.current_color.b;
            comptime {
                if (Settings.use_alpha) {
                    this.vbuf.items[pos + 3] = this.current_color.a;
                }
            }
            return;
        }

        pub fn fillRect(this: *Self, x: u32, y: u32, w: u32, h: u32) void {
            var px: u32 = x;
            var py: u32 = y;
            var tx: u32 = x + w;
            var ty: u32 = y + h;

            while (py < ty) : (py += 1) {
                px = x;
                while (px < tx) : (px += 1) {
                    this.setPixel(px, py);
                }
            }
            return;
        }
    };
}
