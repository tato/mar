const std = @import("std");
const Vm = @import("../Vm.zig");
const bytecode = @import("../bytecode.zig");

fn runTest(code: []const u8, expect_stack: ?[]const i64) !void {
    var vm = Vm.init(std.testing.allocator);
    defer vm.deinit();

    try vm.run(code);
    if (expect_stack) |expect|
        try std.testing.expectEqualSlices(i64, expect, vm.stack.items);
}

test "bytecode exit" {
    const code = std.mem.sliceAsBytes(&[_]bytecode.OpCode{.exit});
    try runTest(code, &.{});
}

test "bytecode simple math" {
    var code = bytecode.Chunk.init(std.testing.allocator);
    defer code.deinit();

    try code.writeLoad(1);
    try code.writeLoad(256);
    try code.write(.add);
    try code.writeLoad(48);
    try code.write(.sub);
    try code.writeLoad(2);
    try code.write(.div);
    try code.write(.exit);

    try runTest(code.code.items, &.{104});
}
