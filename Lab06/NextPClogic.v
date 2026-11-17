`timescale 1ns / 1ps

module NextPClogic(
    output reg [63:0] NextPC,
    input  [63:0] CurrentPC,
    input  [63:0] SignExtImm64,
    input         Branch,
    input         ALUZero,
    input         Uncondbranch
);

// SignExtImm64 already includes the two low zero bits for B and CB-type
// instructions.  A conditional branch is taken only when both Branch and
// ALUZero are asserted; an unconditional branch ignores ALUZero.
always @(*) begin
    if (Uncondbranch || (Branch && ALUZero))
        NextPC = CurrentPC + SignExtImm64;
    else
        NextPC = CurrentPC + 64'd4;
end

endmodule
