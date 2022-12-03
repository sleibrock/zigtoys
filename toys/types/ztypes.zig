

const Entity = struct {
    bytes: [1024]u8,

    fn set(self: Entity, index:usize, val: u8) void {
        self.bytes[index] = val;
    }
};


var Game = Entity {
    .bytes = undefined,
};

export fn init() void {
    var index:usize = 0;
    while (index < 1024) : (index += 1) {
        Game.bytes[index] = 5;
    }
}


export fn get(index: usize) u8 {
    return Game.bytes[index];
}
