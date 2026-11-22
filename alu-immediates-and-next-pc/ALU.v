`timescale 1ns / 1ps

`define AND   4'b0000  // These defines are not required but may be helpful.
`define OR    4'b0001
`define ADD   4'b0010
`define SUB   4'b0110
`define PassB 4'b0111

// ALU (Arithmetic Logic Unit)
// Performs one selected 64-bit arithmetic or bitwise operation. ALUCtrl
// chooses the operation, BusW carries the result, and Zero indicates whether
// every bit of the result is zero.
module ALU(
    output reg [63:0] BusW,
    input      [63:0] BusA,
    input      [63:0] BusB,
    input      [3:0]  ALUCtrl,
    output            Zero
);

// Combinational operation selection. Since every case, including default,
// assigns BusW, this block does not infer a latch.
always @(*) begin
    case (ALUCtrl)
        `AND:    BusW = BusA & BusB; // Bit-by-bit logical AND.
        `OR:     BusW = BusA | BusB; // Bit-by-bit logical OR.
        `ADD:    BusW = BusA + BusB; // 64-bit addition; carry-out is discarded.
        `SUB:    BusW = BusA - BusB; // BusA minus BusB.
        `PassB:  BusW = BusB;        // Ignore BusA and copy BusB to the output.
        default: BusW = 64'b0;       // Safe result for an unsupported control.
    endcase
end

// This continuous assignment is active for every ALU operation. Zero is 1
// exactly when the complete 64-bit result is zero; otherwise Zero is 0.                                                                                                                                        
assign Zero = (BusW == 64'b0);

endmodule
