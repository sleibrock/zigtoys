const BlankStruct = struct {};

const U8struct = struct {
    item: u8 = 0,
};

extern fn print(str: [*]u8) void;

export fn do_i32(a: i32) i32 {
    return a;
}

export fn do_i64(a: i64) i64 {
    return a;
}

export fn do_u32(a: u32) u32 {
    return a;
}

export fn do_u64(a: u64) u64 {
    return a;
}

export fn do_str(str: [*]u8) void {
    print(str);
}

export fn do_struct(thing: *U8struct) void {
    if (thing.item == 0)
        return;
    return;
}
