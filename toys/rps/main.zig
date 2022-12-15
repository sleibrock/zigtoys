// main.zig

const std = @import("std");
const alloc = std.heap.page_allocator;

const rng = @import("src/rng.zig");

// rename the array list
const ByteList = std.ArrayList(u8);

const EntityT = enum(u8) {
    Rock,
    Paper,
    Scissors,
};

const Entity = struct {
    px: f32,
    py: f32,
    vx: f32,
    vy: f32,
    t: EntityT,
    next: EntityT,

    /// initialize an entity
    fn init(x: f32, y: f32, t: EntityT) Entity {
        return Entity{
            .px = x,
            .py = y,
            .vx = 0,
            .vy = 0,
            .t = t,
            .next = t,
        };
    }

    /// move the entity around
    fn move(self: *Entity) void {
        self.px += self.vx;
        self.py += self.vy;
    }

    /// determine if a given entity is an opponent or not
    fn foundPrey(self: *Entity, other: *Entity) bool {
        switch (self.t) {
            .Rock => {
                return other.t == .Paper;
            },
            .Paper => {
                return other.t == .Rock;
            },
            else => {
                return other.t == .Scissors;
            },
        }
    }

    /// Calculate cartesian distance as a 1/sqrt(x) value
    /// hopefully optimizing away the fast inverse square root issue
    /// 1 / sqrt(dx^2 + dy^)
    fn distanceTo(self: *Entity, other: *Entity) f32 {
        const dx = self.px - other.px;
        const dy = self.py - other.py;
        return @divExact(1.0, @sqrt((dx * dx) + (dy - dy)));
    }

    /// Point the current entity to the given (enemy?) entity
    fn pointTowards(self: *Entity, other: *Entity, mag: f32) void {
        // calculate a new trajectory vector (v2 - v1)
        var dx = other.px - self.px;
        var dy = other.py - self.py;
        self.vx = dx * mag;
        self.vy = dy * mag;
    }

    fn overlap(self: *Entity, other: *Entity) bool {
        _ = self;
        _ = other;
        return false;
    }
};

// init an RNG
const RNG = rng.NewType(u32);

const State = struct {
    width: u32,
    height: u32,
    rng: RNG,
    entities: [100]Entity,
    buffer: ByteList,
};

var World = State{
    .width = 0,
    .height = 0,
    .rng = undefined,
    .entities = undefined,
    .buffer = undefined,
};

const scissors_b = @embedFile("new_scissor.ppm");
const rock_b = @embedFile("new_rock.ppm");
const paper_b = @embedFile("new_paper.ppm");

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

    // fill the entities array with scissors!
    index = 0;
    while (index < 100) : (index += 1) {
        var rx = @intToFloat(f32, World.rng.next() % 640);
        var ry = @intToFloat(f32, World.rng.next() % 480);
        var t = EntityT.Scissors;
        var rr = World.rng.random(); // float32
        if (rr > 0.34)
            t = .Rock;
        if (rr > 0.67)
            t = .Paper;
        World.entities[index] = Entity.init(rx, ry, t);
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

    var index: usize = 0;
    var subindex: usize = 0;
    var cur_e: ?*Entity = null;
    var oth_e: ?*Entity = null;
    var tmpd: f32 = 0.0;
    var shortest: f32 = 9999.0;
    var shortest_index: usize = 0;

    while (index < 100) : (index += 1) {
        // update the velocity to find enemies
        cur_e = &World.entities[index];
        cur_e.?.move(); // move the unit

        subindex = 0;
        while (subindex < 100) : (subindex += 1) {
            if (index != subindex) {
                oth_e = &World.entities[subindex];

                // determine if oth_e is our enemy
                if (cur_e.?.foundPrey(oth_e.?)) {
                    // do a distance check to see if it's shortest
                    tmpd = cur_e.?.distanceTo(oth_e.?);
                    if (tmpd < shortest) {
                        shortest = tmpd;
                        shortest_index = subindex;
                    }

                    // do we overlap with this enemy yet?
                    if (cur_e.?.overlap(oth_e.?)) {
                        // do some logic here
                    }
                }
            }
            // find a collison?
            // if (World.entities[index].collides)
        }

        drawPic(cur_e.?.px, cur_e.?.py, switch (cur_e.?.t) {
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
