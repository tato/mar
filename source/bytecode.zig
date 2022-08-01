const std = @import("std");

pub const Chunk = @import("bytecode/Chunk.zig");

pub const OpCode = enum(u8) {
    push,
    pop,
    add,
    sub,
    mul,
    div,
    print,
    exit,
};

