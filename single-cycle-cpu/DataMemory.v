`timescale 1ns / 1ps

module DataMemory #(
    parameter INIT_DEMO = 1
)(
    output reg [63:0] ReadData,
    input      [63:0] Address,
    input      [63:0] WriteData,
    input             MemoryRead,
    input             MemoryWrite,
    input             Clock
);

    localparam SIZE = 1024;
    reg [7:0] memBank [0:SIZE-1];
    wire [9:0] byteAddress = Address[9:0];
    wire inBounds = Address <= 64'd1016;
    integer index;
    integer readByte;
    integer writeByte;

    // The course demo expects these big-endian words. Custom programs
    // start with zero-filled data memory.
    initial begin
        for (index = 0; index < SIZE; index = index + 1)
            memBank[index] = 8'b0;
        if (INIT_DEMO) begin
            memBank[7] = 8'h01;
            memBank[15] = 8'h0a;
            memBank[23] = 8'h05;
            {memBank[24], memBank[25], memBank[26], memBank[27],
             memBank[28], memBank[29], memBank[30], memBank[31]} =
                64'h0ffbea7deadbeeff;
        end
    end

    // Unaligned 64-bit accesses are allowed when all eight bytes fit.
    always @* begin
        ReadData = 64'b0;
        if (MemoryRead && inBounds) begin
            for (readByte = 0; readByte < 8; readByte = readByte + 1)
                ReadData[63 - 8*readByte -: 8] = memBank[byteAddress + readByte[9:0]];
        end
    end

    always @(posedge Clock) begin
        if (MemoryWrite && inBounds) begin
            for (writeByte = 0; writeByte < 8; writeByte = writeByte + 1)
                memBank[byteAddress + writeByte[9:0]] <= WriteData[63 - 8*writeByte -: 8];
        end
    end
endmodule
