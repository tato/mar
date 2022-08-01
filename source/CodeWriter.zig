const std = @import("std");
const OpCode = @import("bytecode.zig").OpCode;

const CodeWriter = @This();

code: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator) CodeWriter {
    return CodeWriter{ .code = std.ArrayList(u8).init(allocator) };
}

pub fn deinit(cw: *CodeWriter) void {
    cw.code.deinit();
    cw.* = undefined;
}

pub fn toOwnedSlice(cw: *CodeWriter) []const u8 {
    const res = cw.code.toOwnedSlice();
    cw.* = undefined;
    return res;
}

pub fn write(cw: *CodeWriter, instr: OpCode) !void {
    try cw.code.append(@enumToInt(instr));
}

pub fn writeInt(cw: *CodeWriter, comptime T: type, val: T) !void {
    try cw.code.writer().writeIntLittle(T, val);
}

pub fn writeLoad(cw: *CodeWriter, val: i64) !void {
    try cw.write(.load);
    try cw.writeInt(i64, val);
}