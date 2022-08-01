const std = @import("std");
const Token = @import("../Token.zig");
const Tokenizer = @import("../Tokenizer.zig");

test "print" {
    const source =
        \\print(1)
        \\print(2)
    ;

    var tokenizer = Tokenizer{ .source = source };
    
    try std.testing.expectEqual(Token{ .kind = .print, .start = 0 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .left_paren, .start = 5 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .integer, .start = 6 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .right_paren, .start = 7 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .newline, .start = 8 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .print, .start = 9 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .left_paren, .start = 14 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .integer, .start = 15 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .right_paren, .start = 16 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .newline, .start = 17 }, tokenizer.next());
    try std.testing.expectEqual(Token{ .kind = .eof, .start = 17 }, tokenizer.next());
}