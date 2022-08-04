/// life.zig
const std = @import("std");

// change these three for your game grid
const WIDTH: u32 = 32;
const HEIGHT: u32 = 32;
const NUM_CELLS: u32 = HEIGHT * WIDTH;

// these are calculated, don't touch
const WIDTHm1: u32 = WIDTH - 1;
const WIDTHp1: u32 = WIDTH + 1;
const HEIGHTm1: u32 = HEIGHT - 1;
const HEIGHTp1: u32 = HEIGHT + 1;

// Create a Cell-type value
// force it to a one-byte value for performance
const Cell = enum(u8) {
    Dead,
    Alive,
};

// Create a struct which has a constant world size
const World = struct {
    cells: [NUM_CELLS]Cell = undefined,
};

// this is our invisible data structure for manipulation
var WORLD = World{
    .cells = undefined,
};

// Get neighbors in an area
export fn get_neighbors(index: u32) u8 {
    var num_neighbors: u8 = 0;

    if ((index < 0) or (index > NUM_CELLS))
        return 0;

    if ((index >= HEIGHTp1) and (WORLD.cells[index - HEIGHTp1] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index > HEIGHT) and (WORLD.cells[index - HEIGHT] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index > HEIGHTm1) and (WORLD.cells[index - HEIGHTm1] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index >= 1) and (WORLD.cells[index - 1] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - 1)) and (WORLD.cells[index + 1] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - HEIGHTm1)) and (WORLD.cells[index + HEIGHTm1] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - HEIGHT)) and (WORLD.cells[index + HEIGHT] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - HEIGHTp1)) and (WORLD.cells[index + HEIGHTp1] == .Alive)) {
        num_neighbors += 1;
    }
    return num_neighbors;
}

// Advance the world by strong mutation
export fn advance() u32 {
    var cell_buf: [NUM_CELLS]Cell = undefined;
    var num_neighbors: u8 = 0;
    var i: u32 = 0;
    var num_changed: u32 = 0;
    while (i < NUM_CELLS) : (i += 1) {
        num_neighbors = get_neighbors(i);
        switch (WORLD.cells[i]) {
            .Dead => {
                if (num_neighbors == 3) {
                    cell_buf[i] = Cell.Alive;
                    num_changed += 1;
                }
            },
            .Alive => {
                if ((num_neighbors < 2) or (num_neighbors > 3)) {
                    cell_buf[i] = Cell.Dead;
                    num_changed += 1;
                }
            },
        }
    }
    WORLD.cells = cell_buf;
    return num_changed;
}

export fn set_cell(index: u32) void {
    if (index >= NUM_CELLS)
        return;

    WORLD.cells[index] = .Alive;
}

export fn get_char(index: u32) u32 {
    if (index >= NUM_CELLS)
        return '◻';

    return switch (WORLD.cells[index]) {
        .Dead => {
            return '◻';
        },
        .Alive => {
            return '◼';
        },
    };
}

test "why the hell get_neighbors(65+) breaks" {
    var some_val = get_neighbors(65);
    try std.testing.expect(some_val == 0);
}

test "why the hell can't we advance" {
    var how_many = advance();
    try std.testing.expect(how_many == 0);
}

test "why the hell can't i get a char" {
    var some_v = get_char(0);
    try std.testing.expect(some_v == '◻');

    some_v = get_char(3);
    try std.testing.expect(some_v == '◻');

    some_v = get_char(1024);
    try std.testing.expect(some_v == '◻');
}

// end life.zig
