`timescale 1ns / 1ps

module mux2to1_8 (
    input  wire [7:0] in0,   // Input 0
    input  wire [7:0] in1,   // Input 1
    input  wire       sel,   // Select signal
    output reg  [7:0] out    // Output
);

// A combinational 2-to-1 multiplexer.  Selecting 0 forwards in0 and
// selecting 1 forwards in1.
always @(*) begin
    case (sel)
        1'b0:    out = in0;
        1'b1:    out = in1;
        default: out = 8'bx;
    endcase
end

endmodule
