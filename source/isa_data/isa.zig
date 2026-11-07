
pub const token_type = enum(usize)
{
        INSTRUCTION = 0,
        REGISTER,
        VALUE,
        SYMBOL,
        STRING,
        _,
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
        _,
};

pub const registers = enum(u32)
{
        SP = 0,
        SB,
        LX,
        LA,
        X0,
        X1,
        X2,
        X3,
        X4,
        X5,
        X6,
        X7,
        _,
};

pub const expected_op_types = struct
{
        op1 : u8,
        op2 : u8,
};

pub const instruction_data = struct
{
        value :instructions,
        string : []const u8,
        expected_op1 : operand_type,
        expected_op2 : operand_type,
};

pub const register_data = struct
{
        value :registers,
        string : []const u8,
};

pub const instruction_data_list = [_]instruction_data
{
        .{ .value = instructions.EXIT, .string = "EXIT", .expected_op1 = .ANY, .expected_op2 = .NON },
        .{ .value = instructions.ADD, .string = "ADD", .expected_op1 = .REG, .expected_op2 = .ANY },
        .{ .value = instructions.SUB, .string = "SUB", .expected_op1 = .REG, .expected_op2 = .ANY },
};

pub const register_data_list = [_]register_data
{
        .{ .value = registers.SP, .string = "@SP" },
        .{ .value = registers.SB, .string = "@SB" },
        .{ .value = registers.LX, .string = "@LX" },
        .{ .value = registers.LA, .string = "@LA" },
};
