`timescale 1ns / 1ps

`define Itype   2'b00  // These defines are not required but may be helpful.
`define Dtype   2'b01
`define CBtype  2'b10
`define Btype   2'b11

// SignExtender
// Converts the immediate field from one of four ARMv8 instruction formats
// into a 64-bit value. SignOp selects the instruction format. Branch
// immediates are also shifted left by two because instructions are aligned
// on four-byte boundaries.
module SignExtender(
    output reg [63:0] SignExOut,
    input      [25:0] Instruction,
    input      [1:0]  SignOp
);

// This is combinational logic: the result is recalculated whenever an input
// changes. Every case assigns SignExOut, so no storage or latch is created.
always @(*) begin
    case (SignOp)
        `Itype: begin
            // I-type immediate is bits [21:10] (12 bits).
            // Add 52 zeros on the left to make a 64-bit unsigned value.
            SignExOut = {52'b0, Instruction[21:10]};
        end

        `Dtype: begin
            // D-type offset is bits [20:12] (9 bits). Bit 20 is its sign
            // bit, so repeat it 55 times to preserve a negative value.
            SignExOut = {{55{Instruction[20]}}, Instruction[20:12]};
        end

        `CBtype: begin
            // CB-type offset is bits [23:5] (19 bits). Repeat its sign bit
            // 43 times and append 00 on the right (a left shift by two).
            //SignExOut = {{43{Instruction[23]}}, Instruction[23:5], 2'b00};
            SignExOut = {{45{Instruction[23]}}, Instruction[23:5]}  <<2;
        end

        `Btype: begin
            // /B-type offset is all 26 input bits. Repeat its sign bit 36
            // times and append 00 on the right (a left shift by two).
            //SignExOut = {{36{Instruction[25]}}, Instruction[25:0], 2'b00};
            SignExOut = {{38{Instruction[25]}}, Instruction[25:0]}  <<2;
        end

        default: begin
            // Safe value for an unknown or unsupported SignOp.
            SignExOut = 64'b0;
        end
    endcase
end

endmodule
