// vec2d.zig
// a basic 2d vector implementation as a comptime asset for multiple types

const std = @import("std");
const math = std.math; // needs sqrt possibly


pub fn NewVec2D(comptime T: type) type {
    return struct{
        const Self = @This();

        x: T,
        y: T,

        pub fn init(x: T, y: T) Self {
            return .{ .x = x, .y = y };
        }

        pub fn add(S: *Self, oth: *Self) void {
            S.x += oth.x;
            S.y += oth.y;
            return;
        }

        pub fn sub(S: *Self, oth: *Self) void {
            S.x -= oth.x;
            S.y -= oth.y;
            return;
        }

        pub fn scale(S: *Self, val: T) void {
            S.x *= val;
            S.y *= val;
            return;
        }

        pub fn magnitude(S: *Self) T {
            // sqrt(a^2 + b^2 + ...)
            // computes pythagorean length of a triangle
            return math.sqrt(S.x*S.x + S.y*S.y);
        }

        pub fn distanceTo(from: *Self, to: *Self) T {
            // compute the magnitude of a vector ->AB or (B-A)
            // simplifies need for having an in-place resultant
            // difference vector
            const a: T = to.x - from.x;
            const b: T = to.y - from.y;
            return math.sqrt(a*a + b*b);
        }

        /// Normalize a vector by it's magnitude to reduce it to
        /// a "normal" vector (values between -1.0 and 1.0)
        /// whereby it's more useful for arithmetic like scaling
        pub fn normalize(S: *Self) void {
            const m = S.magnitude();
            // avoid div by zero (nan)
            if (m == 0.0) {
                return; 
            }
            S.x /= m;
            S.y /= m;
            return;
        }
    };
}

// end vec2d.zig
