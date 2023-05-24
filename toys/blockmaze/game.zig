// game.zig - a sample game

const WIDTH: u32 = 10;
const HEIGHT: u32 = 10;
const W_SIZE: u32 = WIDTH * HEIGHT;

const Levels = @import("levels.zig");

/// The entity enumeration class
/// All cells in the game world live here as variants
/// Info critical to cells should also live here
/// Color is coded into 3 functions currently to best support
/// coloring in JS to hide the color implementation of the entities
const Entity = enum(u8) {
    Empty,
    Player,
    Wall,
    Block,
    Goal,
    // new switch system
    InactiveSwitch,
    ActiveSwitch,
    SwitchDoor,
    InactiveSwitchDoor,
    SwitchDoorWPlayer,
    SwitchDoorWBlock,
    // new key system
    PurpleKey,
    PurpleDoor,
    Null,

    fn red(self: Entity) u8 {
        return switch (self) {
            .Player => 255,
            .SwitchDoorWPlayer => 255,
            .Empty => 255,
            .Wall => 127,
            .InactiveSwitch => 85,
            .ActiveSwitch => 238,
            .SwitchDoor => 85,
            .InactiveSwitchDoor => 180,
            .PurpleKey => 255,
            .PurpleDoor => 180,
            else => 0,
        };
    }

    fn green(self: Entity) u8 {
        return switch (self) {
            .Goal => 255,
            .Empty => 255,
            .Wall => 127,
            .InactiveSwitch => 53,
            .ActiveSwitch => 71,
            .SwitchDoor => 53,
            .InactiveSwitchDoor => 135,
            else => 0,
        };
    }

    fn blue(self: Entity) u8 {
        return switch (self) {
            .Block => 255,
            .Empty => 255,
            .Wall => 127,
            .InactiveSwitch => 10,
            .ActiveSwitch => 100,
            .SwitchDoor => 10,
            .InactiveSwitchDoor => 76,
            .PurpleKey => 255,
            .PurpleDoor => 180,
            else => 0,
        };
    }
};

const Direction = enum(u8) {
    Up = 0,
    Down = 1,
    Left = 2,
    Right = 3,
    Null = 4,
};

const State = struct {
    playerx: u8,
    playery: u8,
    level: u8,
    remaining: u8,
    victory: bool,
    cells: [W_SIZE]Entity,
};

/// Accessing the color information for entities publicly
export fn red(v: Entity) u8 {
    return v.red();
}

export fn green(v: Entity) u8 {
    return v.green();
}

export fn blue(v: Entity) u8 {
    return v.blue();
}

/// Initial state of the world
var WORLD = State{
    .playerx = 0,
    .playery = 0,
    .level = 0,
    .remaining = 0,
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
            .Empty => {
                WORLD.cells[index] = .Empty;
            },
            .Player => {
                WORLD.playerx = x;
                WORLD.playery = y;
                WORLD.cells[index] = .Player;
            },
            .Wall => {
                WORLD.cells[index] = .Wall;
            },
            .Block => {
                WORLD.cells[index] = .Block;
            },
            .Goal => {
                WORLD.cells[index] = .Goal;
            },
            .InactiveSwitch => {
                WORLD.cells[index] = .InactiveSwitch;
            },
            .ActiveSwitch => {
                WORLD.cells[index] = .ActiveSwitch;
            },
            .SwitchDoor => {
                WORLD.cells[index] = .SwitchDoor;
            },
            .InactiveSwitchDoor => {
                WORLD.cells[index] = .InactiveSwitchDoor;
            },
            .SwitchDoorWPlayer => {
                WORLD.playerx = x;
                WORLD.playery = y;
                WORLD.cells[index] = .SwitchDoorWPlayer;
            },
            else => {
                return false;
            },
        }
        return true;
    }
    return false;
}

fn update_level() void {
    const level_ptr = switch (WORLD.level) {
        0 => &Levels.Level0,
        1 => &Levels.Level1,
        2 => &Levels.Level2,
        3 => &Levels.Level3,
        4 => &Levels.Level4,
        5 => &Levels.Level5,
        else => unreachable,
    };
    var index: usize = 0;
    while (index < W_SIZE) : (index += 1) {
        WORLD.cells[index] = switch (level_ptr.cells[index]) {
            0 => .Empty,
            1 => .Player,
            2 => .Wall,
            3 => .Block,
            4 => .Goal,
            5 => .InactiveSwitch,
            6 => .ActiveSwitch,
            7 => .SwitchDoor,
            8 => .InactiveSwitchDoor,
            9 => .PurpleKey,
            10 => .PurpleDoor,
            else => unreachable,
        };
    }
    // copy over remaining info from levels
    WORLD.playerx = level_ptr.startx;
    WORLD.playery = level_ptr.starty;
    WORLD.remaining = level_ptr.blocks;
    return;
}

/// Set up the world state, create a plus sign in the middle
export fn init() void {
    var index: usize = 0;
    while (index < W_SIZE) : (index += 1) {
        WORLD.cells[index] = .Empty;
    }
    WORLD.level = 0;
    WORLD.victory = false;
    update_level();
    return;
}

export fn reset() void {}

fn replace_cells(e1: Entity, e2: Entity) void {
    var index: usize = 0;
    while (index < W_SIZE) : (index += 1) {
        if (WORLD.cells[index] == e1) {
            WORLD.cells[index] = e2;
        }
    }
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

    var curpos = calc_pos(WORLD.playerx, WORLD.playery);
    var goalpos = calc_pos(goalx, goaly);
    if (goalpos == curpos)
        return;

    var curr_e = WORLD.cells[curpos];
    var dest_ent = WORLD.cells[goalpos];
    switch (dest_ent) {
        .Empty => {
            _ = set_pos(WORLD.playerx, WORLD.playery, switch (curr_e) {
                .SwitchDoorWPlayer => .InactiveSwitchDoor,
                else => .Empty,
            });
            _ = set_pos(goalx, goaly, switch (curr_e) {
                .SwitchDoorWPlayer => .Player,
                else => .Player,
            });
        },
        .InactiveSwitch => {
            _ = set_pos(goalx, goaly, .ActiveSwitch);
            replace_cells(.SwitchDoor, .InactiveSwitchDoor);
        },
        .ActiveSwitch => {
            _ = set_pos(goalx, goaly, .InactiveSwitch);
            replace_cells(.InactiveSwitchDoor, .SwitchDoor);
        },
        .PurpleKey => {
            _ = set_pos(WORLD.playerx, WORLD.playery, .Empty);
            _ = set_pos(goalx, goaly, .Player);
            replace_cells(.PurpleDoor, .Empty);
        },

        // figure out doors
        .InactiveSwitchDoor => {
            _ = set_pos(WORLD.playerx, WORLD.playery, switch (curr_e) {
                .SwitchDoorWPlayer => .InactiveSwitchDoor,
                else => .Empty,
            });
            _ = set_pos(goalx, goaly, .SwitchDoorWPlayer);
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
                    WORLD.remaining -= 1;
                    if (WORLD.level == 5) {
                        WORLD.victory = true; // you win!
                        return;
                    }
                    if (WORLD.remaining == 0) {
                        WORLD.level += 1;
                        update_level();
                    }
                },
                else => {},
            }
        },
        else => {},
    }
    return;
}

// end game.zig

