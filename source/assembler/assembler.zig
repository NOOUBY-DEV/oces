const std = @import("std");
const tokenizer = @import("tokenizer.zig");
const isa = @import("../isa_data/isa.zig");


pub const debug_print = true;


pub var gpa = std.heap.DebugAllocator(.{}){};
pub const allocator = gpa.allocator();


pub const assembler_error = error
{
        tokenizer_error,
};

pub const token_value = extern union
{
        as_usize :usize,
        as_isize :isize,
        as_u32 :u32,
        as_i32 :i32,
        as_f32 :f32,
};

pub const token_data = struct
{
        type  :isa.token_type,
        value :token_value,
        index :usize,

        pub fn new() token_data
        {
                return .{.type = isa.token_type.INSTRUCTION, .value = .{ .as_usize = 0 }, .index = 0};
        }
};


pub fn assemble(code :[]u8) assembler_error!void //caller_allocator :std.heap.Allocator
{
        var ir_code :[]u8 = undefined;

        const token_list = tokenizer.tokenize_code(code, &ir_code)

        catch
        {
                return assembler_error.tokenizer_error;
        };

        defer
        {
                allocator.free(ir_code);

                allocator.free(token_list);

                _ = gpa.deinit();
        }
}
