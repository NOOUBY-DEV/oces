const std = @import("std");
const assembler = @import("assembler.zig");
const isa = @import("../isa_data/isa.zig");


const token_error = error
{
        unknown_token,
};


pub fn tokenize_code(code : []u8) ![]u32
{
        var token_list = std.ArrayList(u32).empty;

        var index :u32 = 0; while (1)
        {
                const char = code[index];

                if (!is_stopper_char(char))
                {

                }
                else
                {
                        index += 1;
                }
        }
}

fn get_token_data_index(code : []u8, start_index : u32) token_error!u32
{
        const code_token_length = token_length(code, start_index);

        for (isa.token_data_List[0..], 0..) |current_token_data, token_index|
        {
                if (current_token_data.string.len != code_token_length) continue;

                var found = true;

                for (code[start_index..], current_token_data.string[0..]) |code_char, token_char|
                {
                        if (code_char != token_char) found = false; break;
                }

                if (found) return token_index;
        }

        return error.unknown_token;
}

fn token_length(code : []u8, start_index :u32) u32
{
        var final_index :u32 = 0;

        return for (code[start_index..], 0..) |char, current_index|
        {
                final_index = current_index;

                if (is_stopper_char(char)) break current_index;
        }
        else final_index;
}

fn is_stopper_char(char :u8) bool
{
        return switch (char)
        {
                ' ', '\t', '\n' , ',', 0 => true,
                else => false,
        };
}
