// falling sand
// sandbox game where you drop sand and other things

const sand = @import("src/sand.zig");
const rng = @import("src/rng.zig");

const W_WIDTH: u32 = 640;
const W_HEIGHT: u32 = 480;
const NUM_CHAN: u32 = 4;
const W_SIZE: u32 = W_WIDTH * W_HEIGHT * NUM_CHAN;

const Entity = struct {
    current: sand.SandT,
    next: sand.SandT,

    pub fn update(self: *Entity, ents: *[W_SIZE]Entity, index: usize) void {
        _ = self;
        _ = ents;
        _ = index;
    }

    pub fn mutate(self: *Entity) void {
        _ = self;
    }
};

const State = struct {
    entities: [W_SIZE]Entity,
    buffer: [W_SIZE]u8,
};

var World = State{
    .entities = undefined,
    .buffer = undefined,
};

const RNG = rng.NewType(u32);

var WorldRNG = RNG.init(0x5A2DEB01);

// public facing functions
export fn init() void {
    _ = WorldRNG.next();
    var index: usize = 0;
    while (index < W_SIZE) : (index += 1) {
        World.buffer[index] = 0;
        World.entities[index] = Entity{ .current = .Air, .next = .Air };
    }
}

export fn update() void {
    var index: usize = 0;

    while (index < W_SIZE) : (index += 1) {
        World.entities[index].update(&World.entities, index);
    }

    index = 0;
    while (index < W_SIZE) : (index += 1) {
        World.entities[index].mutate();
    }
}

export fn rand() u32 {
    return WorldRNG.next();
}

export fn startAddr() *[W_SIZE]u8 {
    return &World.buffer;
}

export fn getSize() u32 {
    return W_SIZE;
}

export fn getWidth() u32 {
    return W_WIDTH;
}

export fn getHeight() u32 {
    return W_HEIGHT;
}
// end main.zig
