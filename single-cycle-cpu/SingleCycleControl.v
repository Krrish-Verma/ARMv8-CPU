`timescale 1ns / 1ps

// Eleven-bit opcode patterns taken from instruction[31:21]. Question marks
// are don't-care bits and are matched by the casez statement below.
`define OPCODE_ANDREG 11'b10001010000
`define OPCODE_ORRREG 11'b10101010000
`define OPCODE_ADDREG 11'b10001011000
`define OPCODE_SUBREG 11'b11001011000

`define OPCODE_ADDIMM 11'b100100010??
`define OPCODE_SUBIMM 11'b110100010??

`define OPCODE_MOVZ   11'b110100101??

`define OPCODE_B      11'b000101?????
`define OPCODE_CBZ    11'b10110100???

`define OPCODE_LDUR   11'b11111000010
`define OPCODE_STUR   11'b11111000000

// ALU control values from Lab 6.
`define ALU_AND       4'b0000
`define ALU_OR        4'b0001
`define ALU_ADD       4'b0010
`define ALU_SUB       4'b0110
`define ALU_PASS_B    4'b0111

// Sign-extension format values from Lab 6.
`define SIGN_I        2'b00
`define SIGN_D        2'b01
`define SIGN_CB       2'b10
`define SIGN_B        2'b11
module SC_Control(
    output reg       Reg2Loc,
    output reg       ALUSrc,
    output reg       MemtoReg,
    output reg       RegWrite,
    output reg       MemRead,
    output reg       MemWrite,
    output reg       Branch,
    output reg       Uncondbranch,
    output reg [3:0] ALUOp,
    output reg [1:0] SignOp,
    input      [10:0] opcode
);

always @(*) begin
    // Safe defaults both prevent inferred latches and disable all state
    // changes for an unsupported/garbled binary opcode.
    Reg2Loc      = 1'b0;
    ALUSrc       = 1'b0;
    MemtoReg     = 1'b0;
    RegWrite     = 1'b0;
    MemRead      = 1'b0;
    MemWrite     = 1'b0;
    Branch       = 1'b0;
    Uncondbranch = 1'b0;
    ALUOp        = 4'b0000;
    SignOp       = 2'b00;

    casez (opcode)
        `OPCODE_ANDREG: begin
            RegWrite = 1'b1;
            ALUOp    = `ALU_AND;
        end

        `OPCODE_ORRREG: begin
            RegWrite = 1'b1;
            ALUOp    = `ALU_OR;
        end

        `OPCODE_ADDREG: begin
            RegWrite = 1'b1;
            ALUOp    = `ALU_ADD;
        end

        `OPCODE_SUBREG: begin
            RegWrite = 1'b1;
            ALUOp    = `ALU_SUB;
        end

        `OPCODE_ADDIMM: begin
            ALUSrc   = 1'b1;
            RegWrite = 1'b1;
            ALUOp    = `ALU_ADD;
            SignOp   = `SIGN_I;
        end

        `OPCODE_SUBIMM: begin
            ALUSrc   = 1'b1;
            RegWrite = 1'b1;
            ALUOp    = `ALU_SUB;
            SignOp   = `SIGN_I;
        end

        `OPCODE_MOVZ: begin
            ALUSrc   = 1'b1;
            RegWrite = 1'b1;
            ALUOp    = `ALU_PASS_B;
            SignOp   = `SIGN_I;
        end

        `OPCODE_LDUR: begin
            ALUSrc   = 1'b1;
            MemtoReg = 1'b1;
            RegWrite = 1'b1;
            MemRead  = 1'b1;
            ALUOp    = `ALU_ADD;
            SignOp   = `SIGN_D;
        end

        `OPCODE_STUR: begin
            Reg2Loc  = 1'b1;
            ALUSrc   = 1'b1;
            MemWrite = 1'b1;
            ALUOp    = `ALU_ADD;
            SignOp   = `SIGN_D;
        end

        `OPCODE_CBZ: begin
            Reg2Loc = 1'b1;
            Branch  = 1'b1;
            ALUOp   = `ALU_PASS_B;
            SignOp  = `SIGN_CB;
        end

        `OPCODE_B: begin
            Uncondbranch = 1'b1;
            SignOp       = `SIGN_B;
        end

        default: begin
            // Retain the safe all-zero defaults assigned above.
        end
    endcase
end

endmodule
