/// life.zig
const NUM_CELLS: u8 = 64;

// Create a Cell-type value
// force it to a one-byte value for performance
const Cell = enum(u8) {
    Dead,
    Alive,
};

const DATA = [_]u8{ 100, 200, 254, 0, 0, 0 };

// Create a struct which has a constant world size
const World = struct {
    width: u8 = 8,
    height: u8 = 8,
    cells: [NUM_CELLS]Cell = undefined,
};

export fn get_neighbors(world: *World, index: u8) u8 {
    var num_neighbors: u8 = 0;

    if ((index > 9) and (world.cells[index - 9] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index > 8) and (world.cells[index - 8] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index > 7) and (world.cells[index - 7] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index > 0) and (world.cells[index - 1] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - 1)) and (world.cells[index + 8] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - 7)) and (world.cells[index + 7] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - 8)) and (world.cells[index + 8] == .Alive)) {
        num_neighbors += 1;
    }

    if ((index < (NUM_CELLS - 9)) and (world.cells[index + 9] == .Alive)) {
        num_neighbors += 1;
    }
    return num_neighbors;
}

export fn advance(world: *World) void {
    var cell_buf: [64]Cell = undefined;
    var num_neighbors: u8 = 0;
    var i: u8 = 0;
    while (i < NUM_CELLS) : (i += 1) {
        num_neighbors = get_neighbors(world, i);
        switch (world.cells[i]) {
            .Dead => {
                if (num_neighbors == 3)
                    cell_buf[i] = Cell.Alive;
            },
            .Alive => {
                if ((num_neighbors < 2) or (num_neighbors > 3))
                    cell_buf[i] = Cell.Dead;
            },
        }
    }
    world.cells = cell_buf;
}

// end life.zig
