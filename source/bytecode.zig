const std = @import("std");

const CodeWriter = @import("CodeWriter.zig");

pub const OpCode = enum(u8) {
    load,
    add,
    sub,
    mul,
    div,
    exit,
};

pub fn dump(writer: anytype, code: []const u8) !void {
    var ip: usize = 0;

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
            .exit => try writer.writeAll("EXIT\n"),
        }
    }
}

fn runBytecodeTest(code: []const u8, expect_stack: ?[]const i64) !void {
    const Vm = @import("Vm.zig");
    var vm = Vm.init(std.testing.allocator);
    defer vm.deinit();

    try vm.run(code);
    if (expect_stack) |expect|
        try std.testing.expectEqualSlices(i64, expect, vm.stack.items);
}

test "bytecode exit" {
    const code = std.mem.sliceAsBytes(&[_]OpCode{.exit});
    try runBytecodeTest(code, &.{});
}

test "bytecode simple math" {
    var code = CodeWriter.init(std.testing.allocator);
    defer code.deinit();

    try code.writeLoad(1);
    try code.writeLoad(256);
    try code.write(.add);
    try code.writeLoad(48);
    try code.write(.sub);
    try code.writeLoad(2);
    try code.write(.div);
    try code.write(.exit);

    try runBytecodeTest(code.code.items, &.{104});
}
