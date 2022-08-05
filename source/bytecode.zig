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

pub const Value = union(enum) {
    integer: i64,
    boolean: bool,
};
