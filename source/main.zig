const std = @import("std");

const parse = @import("parse.zig");

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

    const source = try std.fs.cwd().readFileAlloc(arena.allocator(), args[1], 1<<32);
    try runInterpreter(arena.allocator(), source);
}

fn runInterpreter(allocator: std.mem.Allocator, source: []const u8) !void {
    var ast = try parse.parse(allocator, source);
    defer ast.deinit(allocator);

    std.debug.print("{any}\n", .{ast});
}

test "toosimple" {
    const program = @embedFile("../mar/toosimple.mar");
    try runInterpreter(std.testing.allocator, program);
}

test "hello" {
    const program = @embedFile("../mar/hello.mar");
    try runInterpreter(std.testing.allocator, program);
}