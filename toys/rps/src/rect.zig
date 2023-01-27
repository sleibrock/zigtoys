// rect.zig
// a basic rectangle math implementation for collison

const vec2d = @import("vec2d.zig");

pub fn NewRect(comptime T: type) type {
    const VecT = vec2d.NewVec2D(T);
    
    return struct {
        const Self = @This();

        pos: VecT,
        width: T,
        height: T,

        pub fn init(x: T, y: T, w: T, h: T) Self {
            return .{
                .pos = VecT.init(x, y),
                .width = w,
                .height = h,
            };
        }

        pub fn intersects(S: *Self, oth: *Self) bool {
            // determine if two rects overlap via basic math
            var a_xw = S.pos.x + S.width;
            var a_yh = S.pos.y + S.height;
            var b_xw = oth.pos.x + oth.width;
            var b_yh = oth.pos.y + oth.height;
            return (S.pos.x < b_xw)
                and (a_xw > oth.pos.x)
                and (S.pos.y < b_yh)
                and (a_yh > oth.pos.y);
        }
    };
}

// end rect.zig
