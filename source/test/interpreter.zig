const std = @import("std");
const bytecode = @import("../bytecode.zig");
const runInterpreterTest = @import("util.zig").runInterpreterTest;

test "toosimple" {
    const program = "1 + 1";
    var result = try runInterpreterTest(program);
    defer result.deinit();
    try std.testing.expectEqualSlices(i64, &.{}, result.stack);
}

test "aparen" {
    const program = "(1 + 1)";
    var result = try runInterpreterTest(program);
    defer result.deinit();
    try std.testing.expectEqualSlices(i64, &.{}, result.stack);
}

test "hello" {
    const program = "(1 + (111 - 3)) * (2 / 1)"; // 218
    var result = try runInterpreterTest(program);
    defer result.deinit();
    try std.testing.expectEqualSlices(i64, &.{}, result.stack);
}

test "more" {
    const program =
        \\print(22 - 11)
        \\print(33 + 44)
        \\print(2 * (3))
    ;
    var result = try runInterpreterTest(program);
    defer result.deinit();

    const expected =
        \\11
        \\77
        \\6
        \\
    ;
    try std.testing.expectEqualSlices(u8, expected, result.output);
}

test "more expression" {
    const program =
        \\print(2 + 2 * 3)
        \\print(2+2*3+2)
    ;
    var result = try runInterpreterTest(program);
    defer result.deinit();

    const expected =
        \\8
        \\10
        \\
    ;
    try std.testing.expectEqualSlices(u8, expected, result.output);
}
