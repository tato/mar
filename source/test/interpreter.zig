const std = @import("std");
const Vm = @import("../Vm.zig");
const bytecode = @import("../bytecode.zig");
const compile = @import("../compile.zig");

fn runInterpreterTest(source: []const u8, expect_stack: []const i64) !void {
    const allocator = std.testing.allocator;

    var code = try compile.compile(allocator, source);
    defer code.deinit();

    var vm = Vm.init(allocator);
    defer vm.deinit();

    try vm.run(code.code.items);
    try std.testing.expectEqualSlices(i64, expect_stack, vm.stack.items);
}

test "toosimple" {
    const program = "1 + 1";
    try runInterpreterTest(program, &.{2});
}

test "aparen" {
    const program = "(1 + 1)";
    try runInterpreterTest(program, &.{2});
}

test "hello" {
    const program = "(1 + (111 - 3)) * (2 / 1)";
    try runInterpreterTest(program, &.{218});
}