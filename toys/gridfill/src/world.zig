// world.zig - a generic-ish worldly container of sorts

pub fn createWorldT(comptime T: type, comptime max_size: u32) type {
    _ = T;
    return struct {
        width: u32,
        height: u32,
        current_size: u32,
        max_size: u32,
        vbuf: [max_size]u8,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .width = 0,
                .height = 0,
                .current_size = 0,
                .max_size = max_size,
                .vbuf = undefined,
            };
        }

        pub fn setDimensions(this: *Self, w: u32, h: u32) bool {
            var new_size: u32 = w * h;
            if (new_size > this.max_size)
                return false;
            this.width = w;
            this.height = h;
            this.current_size = new_size;
            return true;
        }

        pub fn calcPos(this: *Self, x: u32, y: u32) u32 {
            var res: u32 = (y * this.height) + x;
            if (res > this.current_size) {
                return 0;
            }
            return ((y * this.height) + x);
        }

        pub fn fillBuffer(this: *Self, v: u8) void {
            var index: usize = 0;
            while (index < this.current_size) : (index += 1) {
                this.vbuf[index] = v;
            }
            return;
        }

        pub fn setRGB(this: *Self, x: u32, y: u32, r: u8, g: u8, b: u8) void {
            const pos = this.calcPos(x, y);
            this.vbuf[pos] = r;
            this.vbuf[pos + 1] = g;
            this.vbuf[pos + 2] = b;
            return;
        }

        pub fn setRGBA(this: *Self, x: u32, y: u32, r: u8, g: u8, b: u8, a: u8) void {
            const pos = this.calcPos(x, y);
            this.vbuf[pos] = r;
            this.vbuf[pos + 1] = g;
            this.vbuf[pos + 2] = b;
            this.vbuf[pos + 3] = a;
            return;
        }
    };
}
