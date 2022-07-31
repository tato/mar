const std = @import("std");

const Tokenizer = @import("Tokenizer.zig");

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

    var tokenizer = Tokenizer{ .source = source };
    while (tokenizer.next()) |token| {
        try stdout.writer().print("{any}\n", .{ token });
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
