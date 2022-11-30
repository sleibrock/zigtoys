// game.zig - a sample game

const WIDTH: u32 = 10;
const HEIGHT: u32 = 10;
const W_SIZE: u32 = WIDTH * HEIGHT;

const Entity = enum(u8) {
    Empty,
    Player,
    Wall,
    Block,
    Goal,
    Null,
};

const State = struct{
    cells: [W_SIZE]Entity,
};

var WORLD = State{
    .cells = undefined, 
};

fn calc_pos(x: u32, y: u32) usize {
    return x + (y * HEIGHT);
}

export fn get_pos(x: u32, y: u32) Entity {
    var index = calc_pos(x, y);
    if (index < W_SIZE)
        return WORLD.cells[index];
    return .Empty;
}

export fn set_pos(x: u32, y: u32, v: Entity) bool {
    var index = calc_pos(x, y);
    if (index < W_SIZE) {
        switch (v) {
            .Empty => { WORLD.cells[index] = .Empty; },
            .Player => { WORLD.cells[index] = .Player; },
            .Wall => { WORLD.cells[index] = .Wall; },
            .Goal => { WORLD.cells[index] = .Goal; },
            .Block => { WORLD.cells[index] = .Block; },
            else => { return false; },
        }
        return true;
    }
    return false;
}


/// Set up the world state, create a plus sign in the middle
export fn init() void {
    _ = set_pos(4, 4, Entity.Wall);
    _ = set_pos(4, 3, Entity.Wall);
    _ = set_pos(4, 5, Entity.Wall);
    _ = set_pos(3, 4, Entity.Wall);
    _ = set_pos(5, 4, Entity.Wall);
    return;
}


export fn update(direction: u32) void {
    _ = direction;
    return;
}

