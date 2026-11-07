
pub const token_type = enum(u32)
{
        INSTRUCTION = 0,
        OPERAND,
        COMMA,
        COMMENT,
        SYMBOL,
};

pub const operand_type = enum(u8)
{
        REG = 0,
        VAL,
        ANY,
        NON,
};

pub const instructions = enum(u8)
{
        EXIT = 0,
        JMP,
        CALL,
        SET,
        ADD,
        SUB,
        MUL,
        DIV,
};

pub const expected_op_types = struct
{
        op1 : u8,
        op2 : u8,
};

pub const token_data = struct
{
        type : token_type,
        value : u32,
        string : []u8,
        expected_ops : expected_op_types,
};

pub const token_data_List : []token_data = &[_]token_data
{
        .{.INSTRUCTION, .EXIT, "EXIT", .{.ANY, .NON}},
        .{.INSTRUCTION, .JMP, "JMP",  .{.ANY, .NON}},
        .{.INSTRUCTION, .CALL, "CALL",  .{.ANY, .NON}},
};
