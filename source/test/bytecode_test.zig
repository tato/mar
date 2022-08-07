const std = @import("std");
const bytecode = @import("../bytecode.zig");
const runTest = @import("util.zig").runTest;

test "bytecode exit" {
    var code = bytecode.Chunk.init(std.testing.allocator);
    defer code.deinit();
    try code.write(.exit);
    _ = try runTest(code);
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

    var result = try runTest(code);
    defer result.deinit();

    try std.testing.expectEqualSlices(i64, &.{104}, result.stack);
}

test "printing" {
    var code = bytecode.Chunk.init(std.testing.allocator);
    defer code.deinit();

    try code.writeLoad(101);
    try code.writeLoad(99);
    try code.write(.sub);
    try code.write(.print);
    try code.write(.exit);

    var result = try runTest(code);
    defer result.deinit();

    const expected_output =
        \\2
        \\
    ;
    try std.testing.expectEqualSlices(u8, expected_output, result.output);
}

test "unary minus" {
    var code = bytecode.Chunk.init(std.testing.allocator);
    defer code.deinit();

    try code.writeLoad(11);
    try code.write(.neg);
    try code.writeLoad(-101);
    try code.write(.neg);
    try code.write(.exit);

    var result = try runTest(code);
    defer result.deinit();

    try std.testing.expectEqualSlices(i64, &.{ -11, 101 }, result.stack);
}

test "comparison ops" {
    var code = bytecode.Chunk.init(std.testing.allocator);
    defer code.deinit();

    try code.writeLoad(11);
    try code.write(.neg);
    try code.writeLoad(-101);
    try code.write(.gt);
    try code.writeLoad(1);
    try code.write(.eq);
    try code.write(.exit);

    var result = try runTest(code);
    defer result.deinit();

    try std.testing.expectEqualSlices(i64, &.{1}, result.stack);
}
