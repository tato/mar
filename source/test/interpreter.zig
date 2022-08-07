const std = @import("std");
const bytecode = @import("../bytecode.zig");
const runInterpreterTest = @import("util.zig").runInterpreterTest;

test "toosimple" {
    if (true) return error.SkipZigTest;
    const program = "1 + 1";
    var result = try runInterpreterTest(program);
    defer result.deinit();
    try std.testing.expectEqualSlices(i64, &.{2}, result.stack);
}

test "aparen" {
    if (true) return error.SkipZigTest;
    const program = "(1 + 1)";
    var result = try runInterpreterTest(program);
    defer result.deinit();
    try std.testing.expectEqualSlices(i64, &.{2}, result.stack);
}

test "hello" {
    if (true) return error.SkipZigTest;
    const program = "(1 + (111 - 3)) * (2 / 1)";
    var result = try runInterpreterTest(program);
    defer result.deinit();
    try std.testing.expectEqualSlices(i64, &.{218}, result.stack);
}

test "more" {
    const program =
        \\print(22 - 11)
        \\print(33 + 44)
    ;
    var result = try runInterpreterTest(program);
    defer result.deinit();

    const expected =
        \\11
        \\77
        \\
    ;
    try std.testing.expectEqualSlices(u8, expected, result.output);
}
