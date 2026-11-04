const std = @import("std");


var gpa = std.heap.DebugAllocator(.{}){};
pub const allocator = gpa.allocator();


pub fn assemble() ![]u8
{
        defer gpa.deinit();


}
