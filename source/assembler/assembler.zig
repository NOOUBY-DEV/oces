const std = @import("std");
const tokenizer = @import("tokenizer.zig");


pub const debug_print = true;


pub var gpa = std.heap.DebugAllocator(.{}){};
pub const allocator = gpa.allocator();


pub const assembler_error = error
{
        tokenizer_error,
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
