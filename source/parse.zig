const std = @import("std");
const Token = @import("Token.zig");
const Tokenizer = @import("Tokenizer.zig");

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

pub fn parse(allocator: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error!Ast {

    var parser = Parser.init(allocator, source);

    const root = try parser.expression();
    return Ast{
        .nodes = parser.node_list.toOwnedSlice(allocator),
        .root = root,
    };
}


const Parser = struct {
    allocator: std.mem.Allocator,
    tokenizer: Tokenizer,
    current: Token,
    previous: Token,
    panic_mode: bool = false,
    node_list: std.ArrayListUnmanaged(Ast.Node) = .{},
    
    fn init(allocator: std.mem.Allocator, source: []const u8) Parser {
        var tokenizer = Tokenizer{ .source = source };
        const token = tokenizer.next();
        return Parser{
            .allocator = allocator,
            .tokenizer = Tokenizer{ .source = source },
            .current = token,
            .previous = token,
        };
    }

    fn advance(parser: *Parser) void {
        parser.previous = parser.current;
        while (true) {
            parser.current = parser.tokenizer.next();
            if (parser.current.kind != .err) break;

            parser.panic_mode = true;
            std.log.err("something something error", .{});
        }
    }

    fn consume(parser: *Parser, kind: Token.Kind, message: []const u8) void {
        if (parser.current.kind == kind) {
            parser.advance();
            return;
        }

        parser.panic_mode = true;
        std.log.err("something auuugh consume: {s}", .{message});
    }

    fn expression(parser: *Parser) std.mem.Allocator.Error!Ast.Node.Index {
        const left = if (parser.current.kind == .left_paren) blk: {
            parser.advance();
            const idx = try parser.expression();
            parser.consume(.right_paren, "Expected right paren");
            break :blk idx;
        } else blk: {
            const node = Ast.Node{
                .token = parser.current,
                .left = .empty,
                .right = .empty,
            };
            try parser.node_list.append(parser.allocator, node);

            parser.advance();

            break :blk @intToEnum(Ast.Node.Index, parser.node_list.items.len - 1);
        };

        var opp = Ast.Node {
            .token = undefined,
            .left = left,  
            .right = undefined,   
        };
        parser.advance();
        switch (parser.current.kind) {
            .plus, .minus, .asterisk, .slash => opp.token = parser.current,
            else => std.debug.panic("Not Valid: {any}", .{parser.current.kind}),
        }
        
        const right = if (parser.current.kind == .left_paren) blk: {
            parser.advance();
            const idx = try parser.expression();
            parser.consume(.right_paren, "Expected right paren");
            break :blk idx;
        } else blk: {
            const node = Ast.Node{
                .token = parser.current,
                .left = .empty,
                .right = .empty,
            };
            try parser.node_list.append(parser.allocator, node);
            break :blk @intToEnum(Ast.Node.Index, parser.node_list.items.len - 1);
        };
        opp.right = right;

        try parser.node_list.append(parser.allocator, opp);
        return @intToEnum(Ast.Node.Index, parser.node_list.items.len - 1);
    }
};
