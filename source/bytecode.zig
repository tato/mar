const std = @import("std");

pub const Instr = enum(u8) {
    load,
    add,
    sub,
    mul,
    div,
    exit,
};

pub fn run(allocator: std.mem.Allocator, code: []const u8) std.mem.Allocator.Error!void {
    var vm = Vm {
        .allocator = allocator,
        .code = code,
    };
    defer vm.deinit();

    while (true) {
        const instr = @intToEnum(Instr, vm.code[vm.ip]);
        vm.ip += 1;

        switch (instr) {
            .load => {
                const val = std.mem.readIntLittle(i64, vm.code[vm.ip..][0..8]);
                vm.ip += 8;
                try vm.stack.append(vm.allocator, val);
            },
            .add => {
                const right = vm.stack.pop();
                const left = vm.stack.pop();
                try vm.stack.append(vm.allocator, left + right);
            },
            .sub => {
                const right = vm.stack.pop();
                const left = vm.stack.pop();
                try vm.stack.append(vm.allocator, left - right);
            },
            .mul => {
                const right = vm.stack.pop();
                const left = vm.stack.pop();
                try vm.stack.append(vm.allocator, left * right);
            },
            .div => {
                const right = vm.stack.pop();
                const left = vm.stack.pop();
                try vm.stack.append(vm.allocator, @divFloor(left, right));
            },
            .exit => break,
        }
    }

    std.debug.print("\n{any}\n", .{ vm.stack.items });
}

const Vm = struct {
    allocator: std.mem.Allocator,
    code: []const u8,
    ip: usize = 0,
    stack: std.ArrayListUnmanaged(i64) = .{},

    fn deinit(vm: *Vm) void {
        vm.stack.deinit(vm.allocator);
        vm.* = undefined;
    }
};

const CodeWriter = struct {
    code: std.ArrayList(u8),

    fn init(allocator: std.mem.Allocator) CodeWriter {
        return CodeWriter{ .code = std.ArrayList(u8).init(allocator) };
    }

    fn deinit(cw: *CodeWriter) void {
        cw.code.deinit();
        cw.* = undefined;
    }

    fn writeInstr(cw: *CodeWriter, instr: Instr) !void {
        try cw.code.append(@enumToInt(instr));
    }

    fn writeInt(cw: *CodeWriter, comptime T: type, val: T) !void {
        try cw.code.writer().writeIntLittle(T, val);
    }
};

test {
    const code = std.mem.sliceAsBytes(&[_]Instr{ .exit });
    try run(std.testing.allocator, code);
}

test {
    var code = CodeWriter.init(std.testing.allocator);
    defer code.deinit();

    try code.writeInstr(.load);
    try code.writeInt(i64, 1);
    try code.writeInstr(.load);
    try code.writeInt(i64, 256);
    try code.writeInstr(.add);
    try code.writeInstr(.load);
    try code.writeInt(i64, 48);
    try code.writeInstr(.sub);
    try code.writeInstr(.load);
    try code.writeInt(i64, 2);
    try code.writeInstr(.div);
    try code.writeInstr(.exit);

    try run(std.testing.allocator, code.code.items);
}