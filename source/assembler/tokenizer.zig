const std = @import("std");
const assembler = @import("assembler.zig");
const isa = @import("../isa_data/isa.zig");


const token_error = error
{
        unknown_token,
};


const cleaner_error = error
{
        string_improper_ending_with_newline,
        string_improper_ending_with_nullchar,
};


const ir_marker = assembler.ir_marker;


pub fn tokenize_code(code : []u8) ![]u32
{
        // var token_list = std.ArrayList(u32).empty;
        const ir_code = clean_code(code);
        defer assembler.allocator.free(ir_code);
}

pub fn clean_code(code : []u8) ![]u8
{
        var cleaned_code = std.ArrayList(u8).empty;

        const code_length = code.len - 1; // code.len includes '\0', which we dont count for

        var index :usize = 0; while (index < code_length)
        {
                const char = code[index];

                if (is_space_char(char))
                {
                        index += 1;
                }

                else if (is_special_char(char))
                {
                        if (char == ',')
                        {
                                const string :[3]u8 = .{ir_marker.string_start, ',', ir_marker.end};

                                try cleaned_code.appendSlice(assembler.allocator, &string);

                                index += 1;
                        }

                        else if (char == '#')
                        {
                                while (code[index] != '\n' and code[index] != 0) index += 1;
                        }

                        else if (char == '\"')
                        {
                                try cleaned_code.append(assembler.allocator, ir_marker.string_start);

                                index += 1;

                                while (index < code_length and code[index] != '\"') : (index += 1)
                                {
                                        const current_char = code[index];

                                        if (current_char == '\n') return cleaner_error.string_improper_ending_with_newline;

                                        if (current_char == 0) return cleaner_error.string_improper_ending_with_nullchar;

                                        try cleaned_code.append(assembler.allocator, code[index]);
                                }

                                index += 1;

                                try cleaned_code.append(assembler.allocator, ir_marker.end);
                        }
                }

                else
                {
                        try cleaned_code.append(assembler.allocator, ir_marker.regular_start);

                        while ( !( is_space_char(code[index]) or is_special_char(code[index]) ) ) : (index += 1)
                        {
                                try cleaned_code.append(assembler.allocator, code[index]);
                        }

                        try cleaned_code.append(assembler.allocator, ir_marker.end);
                }
        }

        if (cleaned_code.last() != ir_marker.end)
        {
                try cleaned_code.append(assembler.allocator, ir_marker.end);
        }

        return try cleaned_code.toOwnedSlice(assembler.allocator);
}

fn is_space_char(char :u8) bool
{
        return switch (char)
        {
                ' ', '\t', '\n' => true,
                else => false,
        };
}

fn is_special_char(char :u8) bool
{
        return switch (char)
        {
                '\"', '#', ',' => true,
                else => false,
        };
}
