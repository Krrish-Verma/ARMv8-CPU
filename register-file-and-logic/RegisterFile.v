`timescale 1ns / 1ps

module RegisterFile(
    output wire [63:0] BusA, 
    output wire [63:0] BusB,
    input  wire [63:0] BusW,
    input  wire [4:0]  RA, 
    input  wire [4:0]  RB, 
    input  wire [4:0]  RW,
    input  wire        RegWr,
    input  wire        Clk
);

// Thirty-two 64-bit architectural registers.  Register 31 is ARMv8's XZR
// for the instruction subset used by this processor: it always reads as zero
// and discards writes.
reg [63:0] registers [0:31];

// Both read ports are asynchronous.
assign BusA = (RA == 5'd31) ? 64'b0 : registers[RA];
assign BusB = (RB == 5'd31) ? 64'b0 : registers[RB];

// The single write port updates on the rising edge of the clock.
always @(posedge Clk) begin
    if (RegWr && (RW != 5'd31))
        registers[RW] <= BusW;
end

endmodule
