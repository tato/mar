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
        var nodes: std.ArrayListUnmanaged(ExpressionAstNode) = .{};
        defer nodes.deinit(parser.allocator);

        const root = try parser.getExpressionAst(&nodes);
        try parser.lowerExpressionAst(nodes.items, root);
    }

    fn lowerExpressionAst(
        parser: *Parser,
        nodes: []const ExpressionAstNode,
        node_idx: usize,
    ) std.mem.Allocator.Error!void {
        const ast_node = &nodes[node_idx];

        switch (ast_node.op.kind) {
            .integer => {
                const val = parser.tokenizer.getInteger(ast_node.op);
                try parser.chunk.writeLoad(val);
                return;
            },
            else => {},
        }

        try parser.lowerExpressionAst(nodes, ast_node.left);
        try parser.lowerExpressionAst(nodes, ast_node.right);
        switch (ast_node.op.kind) {
            .plus => try parser.chunk.write(.add),
            .minus => try parser.chunk.write(.sub),
            .asterisk => try parser.chunk.write(.mul),
            .slash => try parser.chunk.write(.div),
            else => unreachable,
        }
    }

    fn getExpressionAst(parser: *Parser, nodes: *std.ArrayListUnmanaged(ExpressionAstNode)) std.mem.Allocator.Error!usize {
        const left = if (parser.current.kind == .left_paren) blk: {
            parser.advance();
            const index = try parser.getExpressionAst(nodes);
            parser.consume(.right_paren, "Expected right paren");
            break :blk index;
        } else if (parser.current.kind == .integer) blk: {
            try nodes.append(parser.allocator, .{ .op = parser.current, .left = undefined, .right = undefined });
            parser.advance();
            break :blk nodes.items.len - 1;
        } else unreachable;

        var op = switch (parser.current.kind) {
            .plus, .minus, .asterisk, .slash => parser.current,
            else => return left,
        };
        parser.advance();

        var right_precedence: Precedence = .constant;
        const right = if (parser.current.kind == .left_paren) blk: {
            parser.advance();
            const index = try parser.getExpressionAst(nodes);
            parser.consume(.right_paren, "Expected right paren");
            break :blk index;
        } else blk: {
            const index = try parser.getExpressionAst(nodes);
            right_precedence = switch (nodes.items[index].op.kind) {
                .integer => .constant,
                .plus, .minus => .add_sub,
                .asterisk, .slash => .mul_div,
                else => unreachable,
            };
            break :blk index;
        };

        const op_precedence: Precedence = switch (op.kind) {
            .plus, .minus => .add_sub,
            .asterisk, .slash => .mul_div,
            else => unreachable,
        };

        if (@enumToInt(right_precedence) > @enumToInt(op_precedence)) {
            // normal
            try nodes.append(parser.allocator, .{ .op = op, .left = left, .right = right });
            return nodes.items.len - 1;
        } else {
            // swap
            try nodes.append(parser.allocator, .{ .op = op, .left = left, .right = nodes.items[right].left });
            nodes.items[right].left = nodes.items.len - 1;
            return right;
        }
    }
};

const ExpressionAstNode = struct {
    op: Token,
    left: usize,
    right: usize,
};

const Precedence = enum {
    add_sub,
    mul_div,
    constant,
};
