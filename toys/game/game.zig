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

const Direction = enum(u8) {
    Up = 0,
    Down = 1,
    Left = 2,
    Right = 3,
    Null = 4,
};

const State = struct{
    playerx: u8,
    playery: u8,
    victory: bool,
    cells: [W_SIZE]Entity,
};

var WORLD = State{
    .playerx = 0,
    .playery = 0,
    .victory = false,
    .cells = undefined, 
};

export fn is_won() bool {
    return WORLD.victory;
}


fn calc_pos(x: u8, y: u8) usize {
    return x + (y * HEIGHT);
}

export fn get_pos(x: u8, y: u8) Entity {
    var index = calc_pos(x, y);
    if (index < W_SIZE)
        return WORLD.cells[index];
    return .Empty;
}

fn set_pos(x: u8, y: u8, v: Entity) bool {
    var index = calc_pos(x, y);
    if (index < W_SIZE) {
        switch (v) {
            .Empty => { WORLD.cells[index] = .Empty; },
            .Player => {
                var old_pos = calc_pos(WORLD.playerx, WORLD.playery);
                WORLD.playerx = x;
                WORLD.playery = y;
                WORLD.cells[old_pos] = .Empty;
                WORLD.cells[index] = .Player;
            },
            .Wall => { WORLD.cells[index] = .Wall; },
            .Block => { WORLD.cells[index] = .Block; },
            .Goal => { WORLD.cells[index] = .Goal; },
            else => { return false; },
        }
        return true;
    }
    return false;
}


/// Set up the world state, create a plus sign in the middle
export fn init() void {
    WORLD.cells = undefined; // reset
    WORLD.victory = false;
    _ = set_pos(4, 4, Entity.Wall);
    _ = set_pos(4, 3, Entity.Wall);
    _ = set_pos(4, 5, Entity.Wall);
    _ = set_pos(3, 4, Entity.Wall);
    _ = set_pos(5, 4, Entity.Wall);

    // set the player and the goal
    _ = set_pos(0, 0, Entity.Player);
    _ = set_pos(5, 5, Entity.Goal);

    // set a block to push
    _ = set_pos(3, 1, Entity.Block);
    return;
}

/// Update our world by attempting to move the player somewhere
export fn update(dir: Direction) void {
    var goalx = WORLD.playerx;
    var goaly = WORLD.playery;
    if ((dir == .Up) and (goaly > 0))
        goaly -= 1;
    if ((dir == .Down) and (goaly < HEIGHT - 1))
        goaly += 1;
    if ((dir == .Left) and (goalx > 0))
        goalx -= 1;
    if ((dir == .Right) and (goalx < WIDTH - 1))
        goalx += 1;

    var goalpos = calc_pos(goalx, goaly);
    if (goalpos == calc_pos(WORLD.playerx, WORLD.playery))
        return;

    var dest_ent = WORLD.cells[goalpos];
    switch (dest_ent) {
        .Empty => {
            _ = set_pos(WORLD.playerx, WORLD.playery, .Empty);
            _ = set_pos(goalx, goaly, .Player);
        },
        .Block => {
            // move this block somewhere
            var newblockx = goalx;
            var newblocky = goaly;
            if ((dir == .Up) and (newblocky > 0))
                newblocky -= 1;
            if ((dir == .Down) and (newblocky < HEIGHT - 1))
                newblocky += 1;
            if ((dir == .Left) and (newblockx > 0))
                newblockx -= 1;
            if ((dir == .Right) and (newblockx < WIDTH - 1))
                newblockx += 1;

            var block_dest = calc_pos(newblockx, newblocky);
            if (block_dest == goalpos)
                return;
            var block_dest_ent = WORLD.cells[block_dest];
            switch (block_dest_ent) {
                .Empty => {
                    _ = set_pos(WORLD.playerx, WORLD.playery, .Empty);
                    _ = set_pos(goalx, goaly, .Player);
                    _ = set_pos(newblockx, newblocky, .Block);
                },
                .Goal => {
                    _ = set_pos(WORLD.playerx, WORLD.playery, .Empty);
                    _ = set_pos(goalx, goaly, .Player);
                    WORLD.victory = true; // you win!
                },
                else => {},
            }
        },
        else => {},
    }
    return;
}

// end game.zig

