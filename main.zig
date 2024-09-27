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

    std.debug.print("{s}\n", .{buffer});

    var array: [30000]u8 = std.mem.zeroes([30000]u8);

    // I should check if ptr is > 0
    var ptr: u32 = 0;
    const input: []u8 = std.mem.zeroes([]u8);
    for (buffer) |byte| {
        switch (byte) {
            '>' => ptr += 1,
            '<' => ptr -= 1,
            '+' => array[ptr] += 1,
            '-' => array[ptr] -= 1,
            '.' => {
                std.debug.print("{c}", .{array[ptr]});
            },
            ',' => {
                _ = try stdin.readUntilDelimiter(input, '\n');
                // if (bytes_read > 1) {
                //     std.debug.print("Input in brainf*ck should contain only one byte\n", .{});
                //     std.process.exit(0);
                // }
                array[ptr] = input[0];
            },
            '[' => std.debug.print("\nopen bracket\n", .{}),
            ']' => std.debug.print("\nclosing bracket\n", .{}),
            else => std.debug.print("\ndon't know this byte\n", .{}),
        }
    }
}
