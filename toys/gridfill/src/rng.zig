/// rng.zig - rng methods
pub fn NewType(comptime T: type) type {
    return struct {
        const Self = @This();

        state: [16]T,
        index: u8,

        pub fn init(v: T) Self {
            var mut: T = v;
            var ret = Self{
                .state = undefined,
                .index = 0,
            };
            var index: usize = 0;
            while (index < 16) : (index += 1) {
                ret.state[index] = mut;
                mut ^= 0xDEADBEEF;
            }
            return ret;
        }

        pub fn next(self: *Self) T {
            var a: T = self.state[self.index];
            var c: T = self.state[(self.index + 13) & 15];
            var b: T = a ^ c ^ (a << 16) ^ (c << 15);
            c = self.state[(self.index + 9) & 15];
            c ^= (c >> 11);
            a = b ^ c;
            self.state[self.index] = a;
            var d: T = a ^ ((a << 5) & 0xDA442D24);
            self.index = (self.index + 15) & 15;
            a = self.state[self.index];
            self.state[self.index] = a ^ b ^ d ^ (a << 2) ^ (b << 18) ^ (c << 28);
            return self.state[self.index];
        }

        /// Compare the value of the engine based on it's type
        /// and the maximum possible values that can be received
        /// if unsupported, maybe panic the program entirely?
        pub fn random(self: *Self) f32 {
            var v: T = self.next(); // move state forward one
            return comptime switch (T) {
                u32 => {
                    return @intToFloat(f32, v) / 4294967295.0;
                },
                u64 => {
                    return @intToFloat(f64, v) / 18446744073709551615.0;
                },
                else => {
                    return 0.0;
                },
            };
        }
    };
}
