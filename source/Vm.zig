const std = @import("std");
const bytecode = @import("bytecode.zig");
const Vm = @This();

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

pub fn run(vm: *Vm, chunk: bytecode.Chunk, output: anytype) !void {
    const code = chunk.code.items;
    while (vm.ip < code.len) {
        const instr = @intToEnum(bytecode.OpCode, code[vm.ip]);
        vm.ip += 1;

        switch (instr) {
            .push => {
                const val = std.mem.readIntLittle(i64, code[vm.ip..][0..8]);
                vm.ip += 8;
                try vm.stack.append(vm.allocator, val);
            },
            .pop => {
                _ = vm.stack.pop();
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
            .neg => {
                const stack = vm.stack.items;
                stack[stack.len - 1] = -stack[stack.len - 1];
            },
            .print => {
                const top = vm.stack.pop();
                try output.print("{d}\n", .{top});
            },
            .exit => break,
        }
    } else @panic("Mar bug: Reached end of bytecode.");
}
