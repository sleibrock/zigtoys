// main.zig

const std = @import("std");
const alloc = std.heap.page_allocator;

const rng = @import("src/rng.zig");
const vec2d = @import("src/vec2d.zig");
const rect = @import("src/rect.zig");

// typedef all our used values
const BASE_FLOAT = f32;
const ByteList = std.ArrayList(u8);
const VecT = vec2d.NewVec2D(BASE_FLOAT);
const RectT = rect.NewRect(BASE_FLOAT);

const NUM_ENTS: usize = 200;


const EntityT = enum(u8) {
    Rock,
    Paper,
    Scissors,
};

const Entity = struct {
    rect: RectT,
    velocity: VecT,
    t: EntityT,

    /// initialize an entity
    fn init(x: f32, y: f32, t: EntityT) Entity {
        return Entity{
            .rect = RectT.init(x, y, 16, 16),
            .velocity = VecT.init(0, 0),
            .t = t,
        };
    }

    /// move the entity around
    fn move(self: *Entity) void {
        self.rect.pos.x += self.velocity.x;
        self.rect.pos.y += self.velocity.y;
    }

    /// determine if a given entity is an opponent or not
    fn foundPrey(self: *Entity, other: *Entity) bool {
        return switch (self.t) {
            .Rock => other.t == .Scissors,
            .Paper => other.t == .Rock,
            .Scissors => other.t == .Paper, 
        };
    }

    /// Calculate cartesian distance as a 1/sqrt(x) value
    /// hopefully optimizing away the fast inverse square root issue
    /// 1 / sqrt(dx^2 + dy^)
    fn distanceTo(self: *Entity, other: *Entity) f32 {
        return self.rect.pos.distanceTo(&other.rect.pos);
    }

    /// Point the current entity to the given (enemy?) entity
    /// involves setting velocity to (B-A)/|(B-A)|
    fn pointTowards(self: *Entity, other: *Entity) void {
        self.velocity.x = other.rect.pos.x;
        self.velocity.y = other.rect.pos.y;
        self.velocity.sub(&self.rect.pos); // subtract A (itself)
        self.velocity.normalize(); // normalize / divide by it's magnitude
    }

    fn overlap(self: *Entity, other: *Entity) bool {
        return self.rect.intersects(&other.rect);
    }
};

// init an RNG
const RNG = rng.NewType(u32);

const State = struct {
    width: u32,
    height: u32,
    rng: RNG,
    entities: [NUM_ENTS]Entity,
    buffer: ByteList,
};

var World = State{
    .width = 0,
    .height = 0,
    .rng = undefined,
    .entities = undefined,
    .buffer = undefined,
};

const scissors_b = @embedFile("assets/new_scissor.ppm");
const rock_b = @embedFile("assets/new_rock.ppm");
const paper_b = @embedFile("assets/new_paper.ppm");

export fn init(wx: u32, wy: u32, seed: u32) u32 {
    World.rng = RNG.init(0x12345 | seed);
    World.width = wx;
    World.height = wy;
    World.buffer = ByteList.initCapacity(alloc, wx * wy * 4) catch |err| {
        switch (err) {
           else => {
                return 1;
            },
        }
    };
    var index: usize = 0;
    const maxcap: usize = wx * wy * 4;
    while (index < maxcap) : (index += 1) {
        World.buffer.items[index] = 255;
    }

    // fill the entities array with randomized entities
    for (&World.entities) |*e| {
        var rx = @intToFloat(f32, World.rng.next() % 620);
        var ry = @intToFloat(f32, World.rng.next() % 460);
        var t = EntityT.Scissors;
        var rr = World.rng.random(); // float32
        if (rr > 0.34)
            t = .Rock;
        if (rr > 0.67)
            t = .Paper;
        e.* = Entity.init(rx, ry, t);
    }

    return wx * wy * 4;
}

export fn startAddr() *u8 {
    return &World.buffer.items[0];
}

export fn getSize() u32 {
    return World.width * World.height * 4;
}

export fn getWidth() u32 {
    return World.width;
}

export fn getHeight() u32 {
    return World.height;
}

export fn update() void {
    clear(); // clear screen

    var tmpd: f32 = 0.0;
    var shortest: f32 = 9999.0;
    var closest_target: ?*Entity = null;

    for (&World.entities) |*curr_ent, index| {
        curr_ent.move(); // move our unit by it's velocity

        closest_target = null;
        for (&World.entities) |*other_ent, subindex| {
            if (index != subindex) {
                // determine if oth_e is our enemy
                if (curr_ent.foundPrey(other_ent)) {
                    // do a distance check to see if it's shortest
                    tmpd = curr_ent.distanceTo(other_ent);
                    if (tmpd < shortest) {
                        shortest = tmpd;
                        closest_target = other_ent;
                    }

                    // do we overlap with this enemy yet?
                    if (curr_ent.overlap(other_ent)) {
                        // do some logic here
                        // can occur outside of shortest distance check
                        other_ent.t = curr_ent.t;
                    }
                }
            }
        }

        // change our velocity to move towards our shortest-distance prey
        if (closest_target != null) {
            // set current entity to point to it's closest target
            curr_ent.pointTowards(closest_target.?);
        }

        drawPic(curr_ent.rect.pos.x, curr_ent.rect.pos.y, switch (curr_ent.t) {
            .Scissors => scissors_b,
            .Rock => rock_b,
            .Paper => paper_b,
        });
    }
}


fn calcPos(x: u32, y: u32) usize {
    return ((y * World.width) + x) * 4;
}

export fn setRGBA(x: u32, y: u32, r: u8, g: u8, b: u8, a: u8) void {
    if (x > World.width) return;
    if (y > World.height) return;
    const index = calcPos(x, y);
    World.buffer.items[index] = r;
    World.buffer.items[index + 1] = g;
    World.buffer.items[index + 2] = b;
    World.buffer.items[index + 3] = a;
}

export fn clear() void {
    var x: u32 = 0;
    var y: u32 = 0;
    while (y < World.height) : (y += 1) {
        x = 0;
        while (x < World.width) : (x += 1) {
            setRGBA(x, y, 70, 70, 70, 255);
        }
    }
}

export fn straightLine(x1: u32, y1: u32, x2: u32) void {
    var x: u32 = x1;
    while (x < x2) : (x += 1) {
        setRGBA(x, y1, 0, 0, 0, 0);
    }
}

// take two vectors and draw the length of the line via slow interpolation
fn drawLine(A: VecT, B: VecT) void {
}

// crude PPM picture drawing algorithm
// requires a buffer of *exactly* 16x16x4
fn drawPic(x: f32, y: f32, buf: *const [768:0]u8) void {
    var ox: u32 = @floatToInt(u32, x);
    var oy: u32 = @floatToInt(u32, y);
    var px: usize = 0;
    var py: usize = 0;
    var r: u8 = 0;
    var g: u8 = 0;
    var b: u8 = 0;
    var index: usize = 0;

    while (py < 16) : (py += 1) {
        px = 0;
        while (px < 16) : (px += 1) {
            // grab current color
            r = buf[index];
            g = buf[index + 1];
            b = buf[index + 2];

            // don't paint if image has white
            if ((r != 255) and (g != 255) and (b != 255))
                setRGBA(ox + px, oy + py, r, g, b, 255);

            index += 3; // bump the pointer
        }
    }
}

export fn atAddr(x: u32) u8 {
    return World.buffer.items[x];
}

//
