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
        var nodes: std.ArrayListUnmanaged(ExpressionNode) = .{};
        defer nodes.deinit(parser.allocator);

        const root = try parser.parseExpressionTree(&nodes);
        try parser.checkExpressionTree(nodes.items, root);
        try parser.lowerExpression(nodes.items, root);
    }

    fn lowerExpression(
        parser: *Parser,
        nodes: []const ExpressionNode,
        node_idx: ExpressionNode.Index,
    ) std.mem.Allocator.Error!void {
        const ast_node = &nodes[node_idx.toUsize().?];

        switch (ast_node.op.kind) {
            .integer => {
                const val = parser.tokenizer.getInteger(ast_node.op);
                try parser.chunk.writeLoad(val);
                return;
            },
            .@"false" => {
                try parser.chunk.writeLoad(0);
                return;
            },
            .@"true" => {
                try parser.chunk.writeLoad(1);
                return;
            },
            else => {},
        }

        if (ast_node.left != .none) try parser.lowerExpression(nodes, ast_node.left);
        try parser.lowerExpression(nodes, ast_node.right);
        switch (ast_node.op.kind) {
            .plus => try parser.chunk.write(.add),
            .minus => if (ast_node.left == .none)
                try parser.chunk.write(.neg)
            else
                try parser.chunk.write(.sub),
            .asterisk => try parser.chunk.write(.mul),
            .slash => try parser.chunk.write(.div),
            .equals_equals => try parser.chunk.write(.eq),
            .not_equals => try parser.chunk.write(.ne),
            .greater_than => try parser.chunk.write(.gt),
            .greater_than_or_equal => try parser.chunk.write(.gte),
            .lesser_than => try parser.chunk.write(.lt),
            .lesser_than_or_equal => try parser.chunk.write(.lte),
            else => unreachable,
        }
    }

    fn parseExpressionTree(parser: *Parser, nodes: *std.ArrayListUnmanaged(ExpressionNode)) std.mem.Allocator.Error!ExpressionNode.Index {
        const left = if (parser.current.kind == .left_paren) blk: {
            parser.advance();
            const index = try parser.parseExpressionTree(nodes);
            parser.consume(.right_paren, "Expected right paren");
            break :blk index;
        } else switch (parser.current.kind) {
            .integer, .@"false", .@"true" => blk: {
                try nodes.append(parser.allocator, .{ .op = parser.current, .left = .none, .right = .none });
                parser.advance();
                break :blk ExpressionNode.Index.fromUsize(nodes.items.len - 1);
            },
            .minus => blk: {
                const minus_tok = parser.current;
                parser.advance();
                try nodes.append(parser.allocator, .{ .op = parser.current, .left = .none, .right = .none });
                try nodes.append(parser.allocator, .{ .op = minus_tok, .left = .none, .right = ExpressionNode.Index.fromUsize(nodes.items.len - 1) });
                parser.advance();
                break :blk ExpressionNode.Index.fromUsize(nodes.items.len - 1);
            },
            else => unreachable,
        };

        var op = switch (parser.current.kind) {
            .plus,
            .minus,
            .asterisk,
            .slash,
            .equals_equals,
            .not_equals,
            .greater_than,
            .greater_than_or_equal,
            .lesser_than,
            .lesser_than_or_equal,
            => parser.current,
            else => return left,
        };
        parser.advance();

        var right_precedence: Precedence = .constant;
        const right = if (parser.current.kind == .left_paren) blk: {
            parser.advance();
            const index = try parser.parseExpressionTree(nodes);
            parser.consume(.right_paren, "Expected right paren");
            break :blk index;
        } else blk: {
            const index = try parser.parseExpressionTree(nodes);
            right_precedence = getTokenPrecedence(nodes.items[index.toUsize().?].op);
            break :blk index;
        };

        const op_precedence: Precedence = getTokenPrecedence(op);

        if (@enumToInt(right_precedence) > @enumToInt(op_precedence)) {
            // normal
            try nodes.append(parser.allocator, .{ .op = op, .left = left, .right = right });
            return ExpressionNode.Index.fromUsize(nodes.items.len - 1);
        } else {
            // swap
            try nodes.append(parser.allocator, .{ .op = op, .left = left, .right = nodes.items[right.toUsize().?].left });
            nodes.items[right.toUsize().?].left = ExpressionNode.Index.fromUsize(nodes.items.len - 1);
            return right;
        }
    }

    fn checkExpressionTree(
        parser: *Parser,
        nodes: []const ExpressionNode,
        node_idx: ExpressionNode.Index,
    ) !void {
        _ = parser;
        _ = nodes;
        _ = node_idx;
    }
};

fn getOperandResultType(token: Token) Type {
    return switch (token.kind) {
        .integer,
        .plus,
        .minus,
        => .integer,

        .@"false",
        .@"true",
        .equals_equals,
        .not_equals,
        .greater_than,
        .lesser_than,
        .greater_than_or_equal,
        .lesser_than_or_equal,
        => .boolean,

        else => unreachable,
    };
}

fn getOperationType(token: Token) Type {
    return switch (token.kind) {
        .plus,
        .minus,
        .asterisk,
        .slash,
        => .integer,

        .equals_equals,
        .not_equals,
        .greater_than,
        .lesser_than,
        .greater_than_or_equal,
        .lesser_than_or_equal,
        => .boolean,

        else => unreachable,
    };
}
fn getTokenPrecedence(token: Token) Precedence {
    return switch (token.kind) {
        .integer, .@"false", .@"true" => .constant,
        .plus, .minus => .add_sub,
        .asterisk, .slash => .mul_div,
        .equals_equals, .not_equals, .greater_than, .lesser_than, .greater_than_or_equal, .lesser_than_or_equal => .comparison,
        else => unreachable,
    };
}

const ExpressionNode = struct {
    op: Token,
    left: Index,
    right: Index,

    const Index = enum(usize) {
        none = std.math.maxInt(usize),
        _,

        fn fromUsize(idx: usize) Index {
            std.debug.assert(idx != @enumToInt(Index.none));
            return @intToEnum(Index, idx);
        }

        fn toUsize(idx: Index) ?usize {
            if (idx == .none) return null;
            return @enumToInt(idx);
        }
    };
};

const Precedence = enum {
    comparison,
    add_sub,
    mul_div,
    constant,
};

const Type = enum {
    integer,
    boolean,
};
