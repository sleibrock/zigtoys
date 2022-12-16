// main.zig

const std = @import("std");
const alloc = std.heap.page_allocator;

const render = @import("src/render.zig");
const game = @import("src/game.zig");


// init the basic comptime types
const RenderT = render.createRenderT(.{
    .use_alpha = false,
});
const GameT = game.createGameT(RenderT); 

// initialize actual structs
var Render = RenderT.init(alloc);
var Game = GameT.init(&Render, alloc);


// public facing init function to set basic bootstrap values
export fn init(wx: u32, wy: u32, seed: u32) u32 {
    var bytes_allocd = Game.render.setResolution(wx, wy);
    if (bytes_allocd == 0) {
        return 0; // error resizing game world
    }
    Game.render.fillBuffer(255); // flush alpha channel

    var resize_res = Game.size1();
    if (resize_res == 0)
        return 0;
    _ = seed;

    // allocate the grid
    Game.randomizeGrid();

    // draw the scene once fully
    Game.renderGrid();
    
    return bytes_allocd;
}

// export the address to JS land
export fn startAddr() *u8 {
    return &Game.render.vbuf.items[0];
}

// export the memory buffer to JS land
export fn getSize() u32 {
    return Game.render.width * Game.render.height * 4;
}

// export game world size to JS land
export fn getWidth() u32 {
    return Game.render.width;
}

// export game world size to JS land
export fn getHeight() u32 {
    return Game.render.height;
}

// test function
export fn atAddr(x: u32) u8 {
    return Game.render.vbuf.items[x];
}


// update the function each allowable frame in client
// Some games this may be no-op as it awaits input
// from other callbacks like onclick/onkeydown etc
export fn update() void {
}

// handle mouse input and update the game world
export fn handle_input(x: u32, y: u32) void {
    Game.render.setColor(255, 255, 0, 255);
    Game.render.fillRect(x, y, 20, 20);
}


// end main.zig
