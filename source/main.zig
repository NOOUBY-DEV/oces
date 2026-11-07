const std = @import("std");
const assembler = @import("assembler/assembler.zig");


pub var gpa = std.heap.DebugAllocator(.{}){};
pub const allocator = gpa.allocator();


pub fn main() !void
{
        defer _ = gpa.deinit();

        const temp_code = "ADD %SP , $8 \n";

        const temp_code_heap = try allocator.alloc(u8, temp_code.len);
        defer allocator.free(temp_code_heap);
        @memcpy(temp_code_heap, temp_code);

        try assembler.assemble(temp_code_heap);
}
