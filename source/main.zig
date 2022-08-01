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
    defer code.deinit();

    var vm = Vm.init(allocator);
    defer vm.deinit();

    try vm.run(code.code.items);
}

comptime {
    _ = @import("test/bytecode.zig");
    _ = @import("test/interpreter.zig");
}
