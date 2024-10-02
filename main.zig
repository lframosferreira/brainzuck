const std = @import("std");
const allocator = std.heap.page_allocator;

const ARRAY_SIZE: usize = 30_000;
const MAX_BYTES_PER_REPL_LINE: usize = 30_000;

const BrainzuckError = error{ InvalidByteError, UnmatchingBrackets, WrongUsage, PtrOutOfBounds };

var array: [ARRAY_SIZE]u8 = std.mem.zeroes([ARRAY_SIZE]u8);
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

fn eval(instructions: []const u8) !void {

    // pre process brackets
    var brackets_mapping = std.AutoHashMap(usize, usize).init(allocator);
    defer brackets_mapping.deinit();

    var stack = std.ArrayList(usize).init(allocator);
    defer stack.deinit();

    for (instructions, 0..) |byte, i| {
        switch (byte) {
            '[' => try stack.append(i),
            ']' => if (stack.items.len == 0) {
                return BrainzuckError.UnmatchingBrackets;
            } else {
                const pos = stack.pop();
                // maps [ to ]
                try brackets_mapping.put(pos, i);
                // maps ] to [
                try brackets_mapping.put(i, pos);
            },
            else => continue,
        }
    }

    var ptr: usize = 0;
    var instructions_ptr: usize = 0;
    while (instructions_ptr < instructions.len) : (instructions_ptr += 1) {
        switch (instructions[instructions_ptr]) {
            '>' => {
                if (ptr == ARRAY_SIZE - 1) {
                    return BrainzuckError.PtrOutOfBounds;
                }
                ptr += 1;
            },
            '<' => {
                if (ptr == 0) {
                    return BrainzuckError.PtrOutOfBounds;
                }
                ptr -= 1;
            },
            '+' => array[ptr] +%= 1,
            '-' => {
                array[ptr] -%= 1;
            },
            '.' => {
                try stdout.print("{c}", .{array[ptr]});
            },
            ',' => {
                const byte = try stdin.readByte();
                array[ptr] = byte;
            },
            '[' => {
                if (array[ptr] == 0) {
                    instructions_ptr = brackets_mapping.get(instructions_ptr).?;
                }
            },
            ']' => {
                if (array[ptr] != 0) {
                    instructions_ptr = brackets_mapping.get(instructions_ptr).?;
                }
            },
            else => continue,
        }
    }
}

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);
    if (args.len != 2) {
        try stdout.print("Wrong usage. For more information try brainzuck help\n", .{});
        return BrainzuckError.WrongUsage;
    }

    if (std.mem.eql(u8, args[1], "help")) {
        try stdout.print("Usage:\n\tto get help: brainzuck help\n\tto interpret a file: brainzuck [filename]\n\tto start the REPL: brainzuck REPL\n", .{});
        std.process.exit(1);
    } else if (std.mem.eql(u8, args[1], "REPL")) {
        while (true) {
            try stdout.print("brainzuck> ", .{});
            const line = try stdin.readUntilDelimiterAlloc(allocator, '\n', MAX_BYTES_PER_REPL_LINE);
            defer allocator.free(line);
            try eval(line);
        }
    }

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const instructions = try allocator.alloc(u8, file_size);
    defer allocator.free(instructions);
    _ = try file.readAll(instructions);
    try eval(instructions);
}
