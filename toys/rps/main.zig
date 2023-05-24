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


/// Fix-sized number of entities on screen
const NUM_ENTS: usize = 200;


/// The EntityT that describes our players in the game
const EntityT = enum(u8) {
    Rock,
    Paper,
    Scissors,
};


/// The Entity struct that contains all the data about our players
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

    /// determine if a given entity is our prey or not
    fn foundPrey(self: *Entity, other: *Entity) bool {
        return switch (self.t) {
            .Rock => other.t == .Scissors,
            .Paper => other.t == .Rock,
            .Scissors => other.t == .Paper,
        };
    }

    /// determine if a given entity is our hunter or not
    fn foundHunter(self: *Entity, other: *Entity) bool {
        return switch (self.t) {
            .Rock => other.t == .Paper,
            .Paper => other.t == .Scissors,
            .Scissors => other.t == .Rock,
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

    /// Point away is the inverse of pointTowards, useful for running away
    fn pointAway(self: *Entity, other: *Entity) void {
        self.pointTowards(other);
        self.velocity.scale(-1.0);
    }

    /// Calculate an intersection of two rectangles of entities
    fn overlap(self: *Entity, other: *Entity) bool {
        return self.rect.intersects(&other.rect);
    }
};

// init an RNG
const RNG = rng.NewType(u32);

/// Layout of our World type
const State = struct {
    width: u32,
    height: u32,
    boundbox: RectT,
    rng: RNG,
    entities: [NUM_ENTS]Entity,
    buffer: ByteList,
};


/// Our world structure
var World = State{
    .width = 0,
    .height = 0,
    .boundbox = RectT.init(0, 0, 0, 0),
    .rng = undefined,
    .entities = undefined,
    .buffer = undefined,
};


/// Embed our entity images as binary strings
/// These are PPM types with headers stripped out
const scissors_b = @embedFile("assets/new_scissor.ppm");
const rock_b = @embedFile("assets/new_rock.ppm");
const paper_b = @embedFile("assets/new_paper.ppm");


/// Initialize our game world from JavaScript
export fn init(wx: u32, wy: u32, seed: u32) u32 {
    World.rng = RNG.init(seed);
    World.width = wx;
    World.height = wy;
    World.boundbox.width = @intToFloat(BASE_FLOAT, wx);
    World.boundbox.height = @intToFloat(BASE_FLOAT, wy);
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


/// Generic getter functions for JS space
export fn startAddr() *u8 { return &World.buffer.items[0]; }
export fn getSize() u32 { return World.width * World.height * 4; }
export fn getWidth() u32 { return World.width; }
export fn getHeight() u32 { return World.height; }


/// General update function for each frame
export fn update() void {
    clear(); // clear screen

    var tmpd: f32 = 0.0;
    var shortest: f32 = 9999.0;
    var closest_target: ?*Entity = null;

    for (&World.entities, 0..) |*curr_ent, index| {
        curr_ent.move(); // move our unit by it's velocity

        if (!World.boundbox.intersects(&curr_ent.rect)) {
            // logic to push the entity back into the world
            curr_ent.rect.pos.x = World.rng.random() * 640.0;
            curr_ent.rect.pos.y = World.rng.random() * 480.0;
        }

        shortest = 9999.0;
        closest_target = null;
        for (&World.entities, 0..) |*other_ent, subindex| {
            if (index != subindex) {
                // check if the current selected entity is not one of our own
                if (curr_ent.t != other_ent.t) {
                    // do a distance check to see if it's shortest
                    tmpd = curr_ent.distanceTo(other_ent);
                    if (tmpd < shortest) {
                        shortest = tmpd;
                        closest_target = other_ent;
                    }

                    // do we overlap with this enemy yet?
                    if (curr_ent.overlap(other_ent)) {
                        if (curr_ent.foundPrey(other_ent)) {
                            other_ent.t = curr_ent.t;
                        } else if (curr_ent.foundHunter(other_ent)) {
                            curr_ent.t = other_ent.t;
                        }
                    }
                }
            }
        }

        // if we have a nearby target, set velocity towards/away from
        // based on if it's a prey or our hunter
        if (closest_target) |closest| {
            // if it's the prey, point towards it
            if (curr_ent.foundPrey(closest)) {
                curr_ent.pointTowards(closest);
            } else if (curr_ent.foundHunter(closest)) {
                curr_ent.pointAway(closest);
            }
        } else {
            curr_ent.velocity.x = 0;
            curr_ent.velocity.y = 0;
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
    _ = A;
    _ = B;
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
