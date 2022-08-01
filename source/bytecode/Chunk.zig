const std = @import("std");
const OpCode = @import("../bytecode.zig").OpCode;

const Chunk = @This();

code: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator) Chunk {
    return Chunk{ .code = std.ArrayList(u8).init(allocator) };
}

pub fn deinit(cw: *Chunk) void {
    cw.code.deinit();
    cw.* = undefined;
}

pub fn write(cw: *Chunk, instr: OpCode) !void {
    try cw.code.append(@enumToInt(instr));
}

pub fn writeInt(cw: *Chunk, comptime T: type, val: T) !void {
    try cw.code.writer().writeIntLittle(T, val);
}

pub fn writeLoad(cw: *Chunk, val: i64) !void {
    try cw.write(.push);
    try cw.writeInt(i64, val);
}

pub fn dump(chunk: *Chunk, writer: anytype) !void {
    var ip: usize = 0;
    const code = chunk.code.items;

    while (ip < code.len) {
        const instr = @intToEnum(OpCode, code[ip]);
        ip += 1;

        switch (instr) {
            .load => {
                const val = std.mem.readIntLittle(i64, code[ip..][0..8]);
                ip += 8;
                try writer.print("LOAD {d}\n", .{val});
            },
            .add => try writer.writeAll("ADD\n"),
            .sub => try writer.writeAll("SUB\n"),
            .mul => try writer.writeAll("MUL\n"),
            .div => try writer.writeAll("DIV\n"),
            .print => try writer.writeAll("PRINT\n"),
            .exit => try writer.writeAll("EXIT\n"),
        }
    }
}