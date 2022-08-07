const std = @import("std");
const build_options = @import("build_options");
const Token = @import("Token.zig");
const Tokenizer = @import("Tokenizer.zig");
const bytecode = @import("bytecode.zig");

pub fn compile(allocator: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error!bytecode.Chunk {
    var parser = Parser.init(allocator, source);

    while (!parser.match(.eof)) try parser.declaration();
    try parser.chunk.write(.exit);

    if (build_options.dump)
        parser.chunk.dump(std.io.getStdErr().writer()) catch @panic("👹 Dump failed");

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

    fn check(parser: *Parser, kind: Token.Kind) bool {
        return parser.current.kind == kind;
    }

    fn match(parser: *Parser, kind: Token.Kind) bool {
        if (!parser.check(kind)) return false;
        parser.advance();
        return true;
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

        std.debug.print("Expect {any}, found {any}.\n", .{ kind, parser.current.kind });
        std.debug.panic("Something went wrong 👹: '{s}'", .{message});
    }

    fn declaration(parser: *Parser) !void {
        try parser.statement();
    }

    fn statement(parser: *Parser) !void {
        if (parser.match(.print)) {
            try parser.printStatement();
        } else {
            try parser.expressionStatement();
        }
    }

    fn printStatement(parser: *Parser) !void {
        parser.consume(.left_paren, "Expect '(' before argument list.");
        try parser.expression();
        parser.consume(.right_paren, "Expect ')' after argument list.");
        parser.consume(.newline, "Expect newline after value.");
        try parser.chunk.write(.print);
    }

    fn expressionStatement(parser: *Parser) !void {
        try parser.expression();
        parser.consume(.newline, "Expect newline after expression.");
        try parser.chunk.write(.pop);
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
            .eof, .newline => return,
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
