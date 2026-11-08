const std = @import("std");
const assembler = @import("assembler.zig");
const isa = @import("../isa_data/isa.zig");



pub fn parse_to_binary(tokens : []assembler.token_data) ![]isa.binary_instruction
{
        // for (tokens[0..]) |token|
        // {
        // }
}

pub fn get_expected_next_token_types_sequence(current_token_data : assembler.token_data) []isa.token_type
{
        switch (current_token_data.type)
        {
                .INSTRUCTION =>
                {
                        var sequence : [3]isa.token_type = .{};

                        sequence[1] = isa.token_type.NEWLINE;


                }
        }
}

fn token_type_in_expected(token : isa.token_type ,expected_tokens : []isa.token_type) bool
{
        for (expected_tokens[0..]) |expected_token|
        {
                if (token == expected_token) return true;
        }

        return false;
}
