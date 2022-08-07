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

test "unary minus" {
    const program =
        \\print(-11)
    ;
    var result = try runInterpreterTest(program);
    defer result.deinit();

    const expected =
        \\-11
        \\
    ;
    try std.testing.expectEqualSlices(u8, expected, result.output);
}

test "same precedence" {
    var result = try runInterpreterTest(
        \\print(3 - 2 - 1)
    );
    defer result.deinit();

    try std.testing.expectEqualSlices(u8, "0\n", result.output);
}

test "compare" {
    var result = try runInterpreterTest(
        \\print(3 - 2 == 10 / 10)
        \\print(10*10 == 101 - 30)
        \\print(31 < 28)
        \\print(42 >= -1000)
    );
    defer result.deinit();

    try std.testing.expectEqualSlices(u8, "1\n0\n0\n1\n", result.output);
}
