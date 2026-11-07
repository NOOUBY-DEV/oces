const std = @import("std");
const tokenizer = @import("tokenizer.zig");


const debug_print = true;


pub const ir_marker = struct
{
        pub const end :u8 = 1;
        pub const regular_start :u8 = 2;
        pub const string_start :u8 = 3;
};


pub var gpa = std.heap.DebugAllocator(.{}){};
pub const allocator = gpa.allocator();


pub fn assemble(code :[]u8) !void //caller_allocator :std.heap.Allocator
{
        defer _ = gpa.deinit();

        const cleaned_code = try tokenizer.clean_code(code);

        defer allocator.free(cleaned_code);

        if  (debug_print)
        {
                for (cleaned_code[0..], 0..) |char, index|
                {
                        if (char == ir_marker.regular_start or char == ir_marker.string_start)
                        {
                                std.debug.print("|", .{});
                        }

                        else if (char == ir_marker.end)
                        {
                                if (index + 1 == cleaned_code.len)
                                {
                                        std.debug.print("|", .{});
                                }
                                else
                                {
                                        std.debug.print("|  :  ", .{});
                                }
                        }

                        else
                        {
                                std.debug.print("{c}", .{char});
                        }
                }

                std.debug.print("\n", .{});
        }
}
