const std = @import("std");
const Token = @import("Token.zig");
const Tokenizer = @import("Tokenizer.zig");
const CodeWriter = @import("CodeWriter.zig");

pub const Ast = struct {
    root: Node.Index,
    nodes: []const Node,

    const Node = struct {
        token: Token,
        left: Index,
        right: Index,

        const Index = enum(u32) {
            empty = std.math.maxInt(u32),
            _,
        };
    };

    pub fn deinit(ast: *Ast, allocator: std.mem.Allocator) void {
        allocator.free(ast.nodes);
        ast.* = undefined;
    }
};

pub fn compile(allocator: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error![]const u8 {
    var parser = Parser.init(allocator, source);
    try parser.expression();
    try parser.code_writer.write(.exit);
    return parser.code_writer.toOwnedSlice();
}


const Parser = struct {
    allocator: std.mem.Allocator,
    tokenizer: Tokenizer,
    current: Token,
    previous: Token,
    code_writer: CodeWriter,
    
    fn init(allocator: std.mem.Allocator, source: []const u8) Parser {
        var tokenizer = Tokenizer{ .source = source };
        const token = tokenizer.next();
        return Parser{
            .allocator = allocator,
            .tokenizer = tokenizer,
            .current = token,
            .previous = token,
            .code_writer = CodeWriter.init(allocator),
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
            try parser.code_writer.writeLoad(val);
            parser.advance();
        }

        var opp = switch (parser.current.kind) {
            .plus, .minus, .asterisk, .slash => parser.current,
            else => std.debug.panic("Not a valid binary operator: {any}", .{parser.current.kind}),
        };
        parser.advance();
        
        if (parser.current.kind == .left_paren) {
            parser.advance();
            try parser.expression();
            parser.consume(.right_paren, "Expected right paren");
        } else {
            const val = parser.tokenizer.getInteger(parser.current);
            try parser.code_writer.writeLoad(val);
            parser.advance();
        }

        switch (opp.kind) {
            .plus => try parser.code_writer.write(.add),
            .minus => try parser.code_writer.write(.sub),
            .asterisk => try parser.code_writer.write(.mul),
            .slash => try parser.code_writer.write(.div),
            else => unreachable,
        }
    }
};
