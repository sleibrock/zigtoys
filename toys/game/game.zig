// game.zig - a sample game

const WIDTH: u32 = 10;
const HEIGHT: u32 = 10;
const W_SIZE: u32 = WIDTH * HEIGHT;

const Entity = enum{
    Empty,
    Player,
    Wall,
};

const State = struct{
    cells: [W_SIZE]Entity,
};

var WORLD = State{
    .cells = [_]Entity{ .Empty } * W_SIZE,
};

fn calc_pos(x: u32, y: u32) usize {
    _ = y;
    _ = x;
    return 0;
}

fn get_pos(x: u32, y: u32) Entity {
    _ = y;
    _ = x;
    return .Empty;
}

fn set_pos(x: u32, y: u32, v: Entity) void {
    _ = v;
    _ = y;
    _ = x;
    return;
}


export fn update(direction: u32) void {
    _ = direction;

    return;
}

