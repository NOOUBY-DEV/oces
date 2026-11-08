const std = @import("std");
const assembler = @import("assembler.zig");
const isa = @import("../isa_data/isa.zig");
const printing = @import("../tools/printing.zig");


pub const tokenizing_error = error
{
        STRING_IMPROPER_ENDING_WITH_NEWLINE,
        STRING_IMPROPER_ENDING_WITH_NULLCHAR,
        UNKNOWN_REGISTER,
        UNKNOWN_INSTRUCTION,
        INVALID_NUMBER,
        MEMORY_ERROR,
        NO_ERROR,
};


pub const ir_markers = struct
{
        pub const END :u8 = 1;
        pub const REGULAR_START :u8 = 2;
        pub const STRING_START :u8 = 3;
};


pub fn tokenize_code(code : []u8, ir_code_ptr :*[]u8) tokenizing_error![]assembler.token_data
{
        var token_list = std.ArrayList(assembler.token_data).empty;

        defer token_list.deinit(assembler.allocator);

        const ir_code = sanitize_to_ir_code(code)

        catch
        {
                std.debug.print("[OCES ASSEMBLER ERROR] : heap memory error \n", .{});

                return tokenizing_error.MEMORY_ERROR;
        };

        ir_code_ptr.* = ir_code;

        if (assembler.debug_print) print_ir_code(ir_code);

        var line :usize = 1;

        var caught_syntax_error :tokenizing_error = tokenizing_error.NO_ERROR;

        var code_index :usize = 0; while (code_index < ir_code.len) : (code_index += 1)
        {
                var current_token_data = assembler.token_data.new();

                const marker = ir_code[code_index];

                if (marker == ir_markers.REGULAR_START)
                {
                        code_index += 1;

                        switch (ir_code[code_index])
                        {
                                '@' =>
                                {
                                        const register_value = get_register_value(ir_code, code_index)

                                        catch |syntax_error|
                                        {
                                                caught_syntax_error = syntax_error;

                                                break;
                                        };

                                        current_token_data.type = isa.token_type.REGISTER;
                                        current_token_data.value.as_usize = register_value;
                                },

                                '$' =>
                                {
                                        const number_value = get_number_value(ir_code, code_index)

                                        catch |syntax_error|
                                        {
                                                caught_syntax_error = syntax_error;

                                                break;
                                        };

                                        current_token_data.type = isa.token_type.VALUE;
                                        current_token_data.value = number_value;
                                },

                                '\n' =>
                                {
                                        current_token_data.type = isa.token_type.NEWLINE;
                                        current_token_data.value.as_usize = '\n';

                                        line += 1;
                                },

                                ',' =>
                                {
                                        current_token_data.type = isa.token_type.COMMA;
                                        current_token_data.value.as_usize = ',';
                                },

                                else =>
                                {
                                        var instruction_index :u8 = undefined;

                                        const instruction_value = get_instruction_value(ir_code, code_index, &instruction_index)

                                        catch |syntax_error|
                                        {
                                                caught_syntax_error = syntax_error;

                                                break;
                                        };

                                        current_token_data.type = isa.token_type.INSTRUCTION;
                                        current_token_data.value.as_usize = instruction_value;
                                        current_token_data.index = instruction_index;
                                }
                        }
                }
                else if (marker == ir_markers.STRING_START)
                {
                        current_token_data.type = isa.token_type.STRING;
                        current_token_data.value.as_usize = code_index + 1;
                }

                token_list.append(assembler.allocator, current_token_data)

                catch
                {
                        std.debug.print("[OCES ASSEMBLER ERROR] : heap memory error \n", .{});

                        return tokenizing_error.MEMORY_ERROR;
                };

                while (ir_code[code_index] != ir_markers.END)code_index += 1;
        }

        if (caught_syntax_error != tokenizing_error.NO_ERROR)
        {
                show_tokenizing_error(caught_syntax_error, ir_code, line, code_index);

                return caught_syntax_error;
        }

        const final_token_list = token_list.toOwnedSlice(assembler.allocator)

        catch
        {
                std.debug.print("{s}[OCES ASSEMBLER ERROR]{s} : heap memory error \n", .{printing.red, printing.reset});

                return tokenizing_error.MEMORY_ERROR;
        };

        print_token_list(final_token_list);

        return final_token_list;
}

fn show_tokenizing_error(exact_error :tokenizing_error, ir_code :[]u8, line :usize, code_index :usize) void
{
        std.debug.print("{s}[OCES SYNTAX ERROR]{s} \n", .{printing.red, printing.reset});

        const error_string = switch (exact_error)
        {
                tokenizing_error.UNKNOWN_REGISTER => "unknown register",
                tokenizing_error.UNKNOWN_INSTRUCTION => "unknown instruction",
                tokenizing_error.INVALID_NUMBER => "invalid number",
                else => "unknown"
        };

        std.debug.print("{s} at line : {d} \n", .{error_string, line});

        // [print token]
        {
                std.debug.print("+---  '", .{});

                var index = code_index; while (ir_code[index] != ir_markers.END) : (index += 1)
                {
                        std.debug.print("{c}", .{ir_code[index]});
                }

                std.debug.print("' \n\n", .{});
        }
}

fn get_register_value(ir_code :[]u8, start_index :usize) tokenizing_error!usize
{
        for (isa.register_data_list[0..]) |current_register_data|
        {
                if (ir_token__equal__token(ir_code, start_index, current_register_data.string))
                {
                        return @intFromEnum(current_register_data.value);
                }
        }

        return tokenizing_error.UNKNOWN_REGISTER;
}

fn get_instruction_value(ir_code :[]u8, start_index :usize, instruction_data_index_ptr :*u8) tokenizing_error!u8
{
        for (isa.instruction_data_list[0..], 0..) |current_instruction_data, instruction_data_index|
        {
                if (ir_token__equal__token(ir_code, start_index, current_instruction_data.string))
                {
                        instruction_data_index_ptr.* = @intCast(instruction_data_index);

                        return @intFromEnum(current_instruction_data.value);
                }
        }

        return tokenizing_error.UNKNOWN_INSTRUCTION;
}

fn get_number_value(ir_code :[]u8, start_index :usize) tokenizing_error!assembler.token_value
{
        var value : assembler.token_value = undefined;

        var is_negative :bool = false;

        for (ir_code[(start_index + 1)..], 0..) |digit, index|
        {
                if (digit == ir_markers.END) break;

                if (digit == '-')
                {
                        if (index > 0) return tokenizing_error.INVALID_NUMBER;

                        is_negative = true;

                        continue;
                }

                if (digit < '0' or digit > '9') return tokenizing_error.INVALID_NUMBER;
        }

        if (is_negative)
        {
                value = .{ .as_isize = 0 };
        }
        else
        {
                value = .{ .as_usize = 0 };
        }

        for (ir_code[(start_index + 1)..]) |digit|
        {
                if (digit == ir_markers.END) break;

                if (digit == '-') continue;

                const digit_value = digit - '0';

                if (is_negative)
                {
                        value.as_isize = (value.as_isize * 10) - digit_value;
                }
                else
                {
                        value.as_usize = (value.as_usize * 10) + digit_value;
                }
        }

        return value;
}

fn ir_token__equal__token(ir_code :[]u8, start_index :usize, token_string :[]const u8) bool
{
        for (token_string[0..], start_index..) |token_char, code_index|
        {
                const code_char = ir_code[code_index];

                if (code_char == ir_markers.END and token_char == 0)
                {
                        break;
                }

                if (code_char != token_char) return false;
        }

        return true;
}

pub fn sanitize_to_ir_code(code : []u8) ![]u8
{
        var ir_code = std.ArrayList(u8).empty;

        const code_length = code.len - 1; // code.len includes '\0', which we dont count for

        const local = struct
        {
                inline fn ir_code_append(ir_code_ref :*std.ArrayList(u8), char : u8) !void
                {
                        ir_code_ref.*.append(assembler.allocator, char)

                        catch
                        {
                                return tokenizing_error.MEMORY_ERROR;
                        };
                }

                inline fn ir_code_append_slice(ir_code_ref :*std.ArrayList(u8), string : []const u8) !void
                {
                        ir_code_ref.*.appendSlice(assembler.allocator, string)

                        catch
                        {
                                return tokenizing_error.MEMORY_ERROR;
                        };
                }
        };

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
                                const string = &[_]u8{ir_markers.REGULAR_START, ',', ir_markers.END};

                                try local.ir_code_append_slice(&ir_code, string);

                                index += 1;
                        }

                        else if (char == '\n')
                        {
                                const string = &[_]u8{ir_markers.REGULAR_START, '\n', ir_markers.END};

                                try local.ir_code_append_slice(&ir_code, string);

                                index += 1;
                        }

                        else if (char == '#')
                        {
                                while (code[index] != '\n' and code[index] != 0) index += 1;
                        }

                        else if (char == '\"')
                        {
                                try local.ir_code_append(&ir_code, ir_markers.STRING_START);

                                index += 1;

                                while (index < code_length and code[index] != '\"') : (index += 1)
                                {
                                        const current_char = code[index];

                                        if (current_char == '\n') return tokenizing_error.STRING_IMPROPER_ENDING_WITH_NEWLINE;

                                        if (current_char == 0) return tokenizing_error.STRING_IMPROPER_ENDING_WITH_NULLCHAR;

                                        try local.ir_code_append(&ir_code, current_char);
                                }

                                index += 1;

                                try local.ir_code_append(&ir_code, ir_markers.END);
                        }
                }

                else
                {
                        try local.ir_code_append(&ir_code, ir_markers.REGULAR_START);

                        while ( !( is_space_char(code[index]) or is_special_char(code[index]) ) ) : (index += 1)
                        {
                                try local.ir_code_append(&ir_code, code[index]);
                        }

                        try local.ir_code_append(&ir_code, ir_markers.END);
                }
        }

        if (ir_code.last() != ir_markers.END)
        {
                try local.ir_code_append(&ir_code, ir_markers.END);
        }

        const final_ir_code = ir_code.toOwnedSlice(assembler.allocator) catch { return tokenizing_error.MEMORY_ERROR; };

        return final_ir_code;
}

fn is_space_char(char :u8) bool
{
        return switch (char)
        {
                ' ', '\t' => true,
                else => false,
        };
}

fn is_special_char(char :u8) bool
{
        return switch (char)
        {
                '\n', '\"', '#', ',' => true,
                else => false,
        };
}

fn print_ir_code(ir_code :[]u8) void
{
        for (ir_code[0..], 0..) |char, index|
        {
                if (char == ir_markers.REGULAR_START or char == ir_markers.STRING_START)
                {
                        std.debug.print("|", .{});
                }

                else if (char == ir_markers.END)
                {
                        if (index + 1 == ir_code.len)
                        {
                                std.debug.print("|", .{});
                        }
                        else
                        {
                                std.debug.print("|  :  ", .{});
                        }
                }

                else if (char == '\n')
                {
                        std.debug.print("\"n", .{});
                }

                else
                {
                        std.debug.print("{c}", .{char});
                }
        }

        std.debug.print("\n", .{});
}

fn print_token_list(token_list :[]assembler.token_data) void
{
        for (token_list[0..]) |current_token_data|
        {
                const value :usize = @bitCast(current_token_data.value.as_usize);

                std.debug.print("|0x{x:0>16}| : |0x{x:0>16}| : |0x{x:0>16}|\n", .{@intFromEnum(current_token_data.type), value, current_token_data.index});
        }
}
