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
    } else return tokenizer.getEof();

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
            '=' => if (tokenizer.peekOrZero() == '=') {
                tokenizer.current += 2;
                result.kind = .equals_equals;
                break;
            } else {
                std.debug.print("Unexpected character: '='", .{});
                tokenizer.current += 1;
                result.kind = .err;
                break;
            },
            '!' => if (tokenizer.peekOrZero() == '=') {
                tokenizer.current += 2;
                result.kind = .not_equals;
                break;
            } else {
                std.debug.print("Unexpected character: '!'", .{});
                tokenizer.current += 1;
                result.kind = .err;
                break;
            },
            '>' => if (tokenizer.peekOrZero() == '=') {
                tokenizer.current += 2;
                result.kind = .greater_than_or_equal;
                break;
            } else {
                tokenizer.current += 1;
                result.kind = .greater_than;
                break;
            },
            '<' => if (tokenizer.peekOrZero() == '=') {
                tokenizer.current += 2;
                result.kind = .lesser_than_or_equal;
                break;
            } else {
                tokenizer.current += 1;
                result.kind = .lesser_than;
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
                    } else if (std.mem.eql(u8, "true", ident)) {
                        result.kind = .@"true";
                    } else if (std.mem.eql(u8, "false", ident)) {
                        result.kind = .@"false";
                    } else {
                        result.kind = .identifier;
                    }
                    break;
                }

                std.debug.print("Unexpected character: '{c}'\n", .{c});
                tokenizer.current += 1;
                result.kind = .err;
                return result;
            },
        }
    } else return tokenizer.getEof();

    return result;
}

fn peekOrZero(tokenizer: @This()) u8 {
    if (tokenizer.source.len > tokenizer.current + 1)
        return tokenizer.source[tokenizer.current + 1];
    return 0;
}

fn getEof(tokenizer: *@This()) Token {
    var result = Token{ .kind = .eof, .start = @intCast(u32, tokenizer.source.len) };
    if (tokenizer.current == tokenizer.source.len) {
        result.kind = .newline;
        tokenizer.current += 1;
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
