const std = @import("std");
const allocator = std.heap.page_allocator;

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);
    const stdin = std.io.getStdIn().reader();
    if (args.len != 2) {
        std.debug.print("Usage: branzuck [filename]", .{});
        std.process.exit(0);
    }

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);
    _ = try file.readAll(buffer);

    var array: [30000]u8 = std.mem.zeroes([30000]u8);

    // pre process brackets
    var brackets_mapping = std.AutoHashMap(usize, usize).init(allocator);
    defer brackets_mapping.deinit();

    var stack = std.ArrayList(usize).init(allocator);
    defer stack.deinit();

    for (buffer, 0..) |byte, i| {
        switch (byte) {
            '[' => try stack.append(i),
            ']' => if (stack.items.len == 0) {
                std.debug.print("there is a ] without a matching [\n", .{});
                std.process.exit(0);
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

    // var it = brackets_mapping.keyIterator();
    // while (it.next()) |k| {
    //     const val = brackets_mapping.get(k.*).?;
    //     std.debug.print("{d}: {d}\n", .{ k.*, val });
    // }
    // std.debug.print("----------------------------------\n", .{});

    // I should check if ptr is > 0
    var ptr: usize = 0;
    const input: []u8 = std.mem.zeroes([]u8);
    var idx: usize = 0;
    while (idx < buffer.len) : (idx += 1) {
        switch (buffer[idx]) {
            '>' => ptr += 1,
            '<' => ptr -= 1,
            '+' => array[ptr] += 1,
            '-' => {
                array[ptr] -= 1;
            },
            '.' => {
                std.debug.print("{c}", .{array[ptr]});
            },
            // I will deal with this later
            ',' => {
                _ = try stdin.readUntilDelimiter(input, '\n');
                // if (bytes_read > 1) {
                //     std.debug.print("Input in brainf*ck should contain only one byte\n", .{});
                //     std.process.exit(0);
                // }
                array[ptr] = input[0];
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
            else => std.debug.print("\ndon't know this byte\n", .{}),
        }
    }
}
