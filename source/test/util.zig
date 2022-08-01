const std = @import("std");
const bytecode = @import("../bytecode.zig");
const compile = @import("../compile.zig");
const Vm = @import("../Vm.zig");

pub const TestResult = struct {
    allocator: std.mem.Allocator,
    stack: []const i64,
    output: []const u8,

    pub fn deinit(res: *TestResult) void {
        res.allocator.free(res.stack);
        res.allocator.free(res.output);
        res.* = undefined;
    }
};

pub fn runTest(chunk: bytecode.Chunk) !TestResult {
    var vm = Vm.init(std.testing.allocator);
    defer vm.deinit();

    var output = std.ArrayList(u8).init(std.testing.allocator);

    try vm.run(chunk, output.writer());

    return TestResult {
        .allocator = std.testing.allocator,
        .stack = vm.stack.toOwnedSlice(std.testing.allocator),
        .output = output.toOwnedSlice(),
    };
}


pub fn runInterpreterTest(source: []const u8) !TestResult {
    var chunk = try compile.compile(std.testing.allocator, source);
    defer chunk.deinit();

    return runTest(chunk);
}