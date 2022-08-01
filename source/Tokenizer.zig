const std = @import("std");
const Token = @import("Token.zig");

source: []const u8,
current: u32 = 0,

pub fn next(tokenizer: *@This()) Token {
    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        switch (tokenizer.source[tokenizer.current]) {
            ' ', '\r', '\t' => continue,
            else => break,
        }
    } else return Token{ .kind = .eof, .start = tokenizer.current };

    var result = Token{ .kind = undefined, .start = tokenizer.current };

    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        const c = tokenizer.source[tokenizer.current];
        switch (c) {
            '\n' => {
                tokenizer.current += 1;
                result.kind = .newline;
                break;
            },
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
                if (std.ascii.isDigit(c)) {
                    tokenizer.tokenizeInteger();
                    result.kind = .integer;
                    break;
                }

                if (c == '_' or std.ascii.isAlpha(c)) {
                    tokenizer.tokenizeIdent();
                    const ident = tokenizer.source[result.start..tokenizer.current];
                    if (std.mem.eql(u8, "print", ident)) {
                        result.kind = .print;
                    } else {
                        result.kind = .identifier;
                    }
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
        if (!std.ascii.isDigit(c)) break;
    }
}

fn tokenizeIdent(tokenizer: *@This()) void {
    while (tokenizer.current < tokenizer.source.len) : (tokenizer.current += 1) {
        const c = tokenizer.source[tokenizer.current];
        if (c != '_' and !std.ascii.isAlNum(c)) break;
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
