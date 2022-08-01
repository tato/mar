const std = @import("std");

pub const Chunk = @import("bytecode/Chunk.zig");

pub const OpCode = enum(u8) {
    load,
    add,
    sub,
    mul,
    div,
    exit,
};

