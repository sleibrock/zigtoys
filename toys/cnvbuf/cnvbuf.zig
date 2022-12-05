// cnvbuf.zig - modifying canvas directly with a buffer

const size_t = u32;

const WIDTH: size_t = 640;
const HEIGHT: size_t = 480;
const CHAN_SIZE: size_t = 4; // represent rgba (4) or rgb (3)
const B_SIZE: size_t = WIDTH * HEIGHT * CHAN_SIZE;

var DATA: [B_SIZE]u8 = undefined;

const State = struct {
    color: u8,
    tracker: u8,
    refresh: u8,
};
var STATE = State{
    .color = 0,
    .tracker = 0,
    .refresh = 60,
};

export fn getWidth() size_t {
    return WIDTH;
}

export fn getHeight() size_t {
    return HEIGHT;
}

export fn getSize() size_t {
    return B_SIZE;
}

fn calcPos(x: size_t, y: size_t) usize {
    return ((y * WIDTH) + x) * CHAN_SIZE;
}

export fn setRGBA(x: size_t, y: size_t, r: u8, g: u8, b: u8, a: u8) void {
    const index = calcPos(x, y);
    DATA[index] = r;
    DATA[index + 1] = g;
    DATA[index + 2] = b;
    DATA[index + 3] = a;
}

export fn init() void {
    var index: usize = 0;
    while (index < B_SIZE) : (index += 1) {
        DATA[index] = 200;
    }
}

export fn update() void {}

/// Inform the JS where the address of our buffer actually starts.
export fn startAddr() *[B_SIZE]u8 {
    return &DATA;
}

//// Provide a generalized drawing API here
export fn clear() void {
    var x: u32 = 0;
    var y: u32 = 0;
    while (y < HEIGHT) : (y += 1) {
        x = 0;
        while (x < WIDTH) : (x += 1) {
            setRGBA(x, y, 255, 255, 255, 0);
        }
    }
}

export fn straightLine(x1: u32, y1: u32, x2: u32) void {
    var x: u32 = x1;
    while (x < x2) : (x += 1) {
        setRGBA(x, y1, 0, 0, 0, 0);
    }
}

// end cnvbuf.zig
