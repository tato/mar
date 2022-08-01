const std = @import("std");
const Token = @import("Token.zig");
const Tokenizer = @import("Tokenizer.zig");
const bytecode = @import("bytecode.zig");

pub fn compile(allocator: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error!bytecode.Chunk {
    var parser = Parser.init(allocator, source);
    try parser.expression();
    try parser.chunk.write(.exit);
    parser.chunk.code.shrinkAndFree(parser.chunk.code.items.len);
    return parser.chunk;
}

const Parser = struct {
    allocator: std.mem.Allocator,
    tokenizer: Tokenizer,
    current: Token,
    previous: Token,
    chunk: bytecode.Chunk,
    
    fn init(allocator: std.mem.Allocator, source: []const u8) Parser {
        var tokenizer = Tokenizer{ .source = source };
        const token = tokenizer.next();
        return Parser{
            .allocator = allocator,
            .tokenizer = tokenizer,
            .current = token,
            .previous = token,
            .chunk = bytecode.Chunk.init(allocator),
        };
    }

    fn advance(parser: *Parser) void {
        parser.previous = parser.current;
        while (true) {
            parser.current = parser.tokenizer.next();
            if (parser.current.kind != .err) break;
            @panic("Something went wrong 👹");
        }
    }

    fn consume(parser: *Parser, kind: Token.Kind, message: []const u8) void {
        if (parser.current.kind == kind) {
            parser.advance();
            return;
        }

        std.debug.panic("Something went wrong 👹: '{s}'", .{message});
    }

    fn expression(parser: *Parser) std.mem.Allocator.Error!void {
        if (parser.current.kind == .left_paren) {
            parser.advance();
            try parser.expression();
            parser.consume(.right_paren, "Expected right paren");
        } else {
            const val = parser.tokenizer.getInteger(parser.current);
            try parser.chunk.writeLoad(val);
            parser.advance();
        }

        var opp = switch (parser.current.kind) {
            .plus, .minus, .asterisk, .slash => parser.current,
            .eof => return,
            else => std.debug.panic("Not a valid binary operator: {any}", .{parser.current.kind}),
        };
        parser.advance();
        
        if (parser.current.kind == .left_paren) {
            parser.advance();
            try parser.expression();
            parser.consume(.right_paren, "Expected right paren");
        } else {
            const val = parser.tokenizer.getInteger(parser.current);
            try parser.chunk.writeLoad(val);
            parser.advance();
        }

        switch (opp.kind) {
            .plus => try parser.chunk.write(.add),
            .minus => try parser.chunk.write(.sub),
            .asterisk => try parser.chunk.write(.mul),
            .slash => try parser.chunk.write(.div),
            else => unreachable,
        }
    }
};
