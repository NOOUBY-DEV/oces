const std = @import("std");


pub const token = struct


var gpa = std.heap.DebugAllocator(.{}){};
pub const allocator = gpa.allocator();


pub fn assemble() ![]u8
{
        defer gpa.deinit();
}
