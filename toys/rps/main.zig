// main.zig

const std = @import("std");
//var buffer: [640 * 480 * 4 * 2]u8 = undefined;
const alloc = std.heap.page_allocator;

const ppm = @import("src/ppm.zig");
const rng = @import("src/rng.zig");

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

    fn init(x: f32, y: f32, t: EntityT) Entity {
        return Entity{
            .px = x,
            .py = y,
            .vx = 0,
            .vy = 0,
            .t = t,
        };
    }
};

// init an RNG
const RNG = rng.NewType(u32);

const State = struct {
    width: u32,
    height: u32,
    rng: RNG,
    entities: [100]Entity,
    buffer: std.ArrayList(u8),
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
    World.buffer = std.ArrayList(u8).initCapacity(alloc, wx * wy * 4) catch |err| {
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

export fn startAddr() *[]u8 {
    return &World.buffer.items;
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
    clear();
    var index: usize = 0;
    while (index < 100) : (index += 1) {
        drawPic(@floatToInt(u32, World.entities[index].px), @floatToInt(u32, World.entities[index].py), switch (World.entities[index].t) {
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

fn drawPic(x: u32, y: u32, buf: *const [768:0]u8) void {
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
                setRGBA(x + px, y + py, r, g, b, 255);

            index += 3; // bump the pointer
        }
    }
}

export fn atAddr(x: u32) u8 {
    return World.buffer.items[x];
}

//
