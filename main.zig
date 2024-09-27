const std = @import("std");
const allocator = std.heap.page_allocator;

const ARRAY_SIZE: usize = 30_000;

const BrainzuckError = error{ UnmatchingBrackets, WrongUsage, PtrOutOfBounds };

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    if (args.len != 2) {
        try stdout.print("Wrong usage. For more information try brainzuck help\n", .{});
        return BrainzuckError.WrongUsage;
    }

    if (std.mem.eql(u8, args[1], "help")) {
        try stdout.print("Usage:\n\tto get help: brainzuck help\n\tto interpret a file: brainzuck [filename]\n\tto start the REPL: brainzuck REPL\n", .{});
        std.process.exit(1);
    }

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    // add file not existing error handling here

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);
    _ = try file.readAll(buffer);

    var array: [ARRAY_SIZE]u8 = std.mem.zeroes([ARRAY_SIZE]u8);

    // pre process brackets
    var brackets_mapping = std.AutoHashMap(usize, usize).init(allocator);
    defer brackets_mapping.deinit();

    var stack = std.ArrayList(usize).init(allocator);
    defer stack.deinit();

    for (buffer, 0..) |byte, i| {
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
    var idx: usize = 0;
    while (idx < buffer.len) : (idx += 1) {
        switch (buffer[idx]) {
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
            // I will deal with this later
            ',' => {
                const byte = try stdin.readByte();
                array[ptr] = byte;
            },
            '[' => {
                if (array[ptr] == 0) {
                    idx = brackets_mapping.get(idx).?;
                }
            },
            ']' => {
                if (array[ptr] != 0) {
                    idx = brackets_mapping.get(idx).?;
                }
            },
            '\n' => continue,
            else => try stdout.print("\ndon't know this byte\n", .{}),
        }
    }
}
