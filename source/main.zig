const std = @import("std");

const compile = @import("compile.zig");
const Vm = @import("Vm.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const stdout = std.io.getStdOut();

    const args = try std.process.argsAlloc(arena.allocator());
    if (args.len < 2) {
        try stdout.writeAll(
            \\mar language interpreter 🐚
            \\Usage: mar [input file]
        );
        std.os.exit(0);
    }

    const source = try std.fs.cwd().readFileAlloc(arena.allocator(), args[1], 1 << 32);
    try runInterpreter(arena.allocator(), source);
}

fn runInterpreter(allocator: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error!void {
    var code = try compile.compile(allocator, source);
    defer allocator.free(code);

    var vm = Vm.init(allocator);
    defer vm.deinit();

    try vm.run(code);
}

fn runInterpreterTest(source: []const u8, expect_stack: []const i64) !void {
    const allocator = std.testing.allocator;

    var code = try compile.compile(allocator, source);
    defer allocator.free(code);

    var vm = Vm.init(allocator);
    defer vm.deinit();

    try vm.run(code);
    try std.testing.expectEqualSlices(i64, expect_stack, vm.stack.items);
}

comptime {
    _ = @import("bytecode.zig");
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
