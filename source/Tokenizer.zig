const std = @import("std");
const Token = @import("Token.zig");

source: []const u8,
current: usize = 0,

pub fn next(tokenizer: *@This()) ?Token {
    var result = Token{ .kind = undefined, .start = tokenizer.current };

    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        const c = tokenizer.source[tokenizer.current];
        switch (c) {
            ' ', '\n', '\r', '\t' => continue,
            '+' => {
                result.kind = .plus;
                break;
            },
            '-' => {
                result.kind = .minus;
                break;
            },
            '*' => {
                result.kind = .asterisk;
                break;
            },
            '/' => {
                result.kind = .slash;
                break;
            },
            '(' => {
                result.kind = .left_paren;
                break;
            },
            ')' => {
                result.kind = .right_paren;
                break;
            },
            else => {
                tokenizer.current += 1;
                if (c >= '0' and c <= '9') {
                    tokenizer.tokenizeNumber();
                    result.kind = .number;
                    break;
                }
            },
        }
    } else return null;

    tokenizer.current += 1;
    return result;
}

fn tokenizeNumber(tokenizer: *@This()) void {
    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        const c = tokenizer.source[tokenizer.current];
        const is_number = c >= '0' and c <= '9';
        if (!is_number) break;
    }
}