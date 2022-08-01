const std = @import("std");
const Token = @import("Token.zig");

source: []const u8,
current: u32 = 0,

pub fn next(tokenizer: *@This()) Token {
    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        switch (tokenizer.source[tokenizer.current]) {
            ' ', '\n', '\r', '\t' => continue,
            else => break,
        }
    } else return Token{ .kind = .eof, .start = tokenizer.current };

    var result = Token{ .kind = undefined, .start = tokenizer.current };

    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        const c = tokenizer.source[tokenizer.current];
        switch (c) {
            '+' => {
                tokenizer.current += 1;
                result.kind = .plus;
                break;
            },
            '-' => {
                tokenizer.current += 1;
                result.kind = .minus;
                break;
            },
            '*' => {
                tokenizer.current += 1;
                result.kind = .asterisk;
                break;
            },
            '/' => {
                tokenizer.current += 1;
                result.kind = .slash;
                break;
            },
            '(' => {
                tokenizer.current += 1;
                result.kind = .left_paren;
                break;
            },
            ')' => {
                tokenizer.current += 1;
                result.kind = .right_paren;
                break;
            },
            else => {
                if (c >= '0' and c <= '9') {
                    tokenizer.tokenizeInteger();
                    result.kind = .integer;
                    break;
                }

                result.kind = .err;
                return result;
            },
        }
    } else {
        result.kind = .eof;
        return result;
    }

    return result;
}

fn tokenizeInteger(tokenizer: *@This()) void {
    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        const c = tokenizer.source[tokenizer.current];
        const is_number = c >= '0' and c <= '9';
        if (!is_number) break;
    }
}

pub fn getInteger(tokenizer: *@This(), token: Token) i64 {
    std.debug.assert(token.kind == .integer);
    var copy = tokenizer.*;
    copy.current = token.start;
    copy.tokenizeInteger();
    const end = copy.current;
    return std.fmt.parseInt(i64, tokenizer.source[token.start..end], 10) catch unreachable;
}
