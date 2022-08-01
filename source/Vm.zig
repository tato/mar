const std = @import("std");
const Vm = @This();
const OpCode = @import("bytecode.zig").OpCode;

allocator: std.mem.Allocator,
ip: usize = 0,
stack: std.ArrayListUnmanaged(i64) = .{},

pub fn init(allocator: std.mem.Allocator) Vm {
    return Vm{ .allocator = allocator };
}

pub fn deinit(vm: *Vm) void {
    vm.stack.deinit(vm.allocator);
    vm.* = undefined;
}

pub fn run(vm: *Vm, code: []const u8) std.mem.Allocator.Error!void {
    while (vm.ip < code.len) {
        const instr = @intToEnum(OpCode, code[vm.ip]);
        vm.ip += 1;

        switch (instr) {
            .load => {
                const val = std.mem.readIntLittle(i64, code[vm.ip..][0..8]);
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
    } else @panic("Mar bug: Reached end of bytecode.");
}
