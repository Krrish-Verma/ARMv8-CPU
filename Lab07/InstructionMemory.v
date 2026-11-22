`timescale 1ns / 1ps

module InstructionMemory #(
    parameter PROGRAM_FILE = ""
)(
    output wire [31:0] Data,
    input      [63:0] Address
);

    localparam WORDS = 1024;
    reg [31:0] words [0:WORDS-1];
    integer index;

    initial begin
        for (index = 0; index < WORDS; index = index + 1)
            words[index] = 32'b0;

        if (PROGRAM_FILE != "") begin
            $readmemh(PROGRAM_FILE, words);
        end else begin
            // ECEN 350 Processor Test Functions, Texas A&M University.
            // Load the demo constants, mask the counter value, count down
            // in a loop, and store and reload the result at byte address 0x20.
            words[0]  = 32'hf84003e9;  // LDUR X9,  [XZR, #0x00]
            words[1]  = 32'hf84083ea;  // LDUR X10, [XZR, #0x08]
            words[2]  = 32'hf84103eb;  // LDUR X11, [XZR, #0x10]
            words[3]  = 32'hf84183ec;  // LDUR X12, [XZR, #0x18]
            words[4]  = 32'hf84203ed;  // LDUR X13, [XZR, #0x20]
            words[5]  = 32'haa0b014a;  // ORR X10, X10, X11
            words[6]  = 32'h8a0a018c;  // AND X12, X12, X10
            words[7]  = 32'hb400008c;  // CBZ X12, +0x10
            words[8]  = 32'h8b0901ad;  // ADD X13, X13, X9
            words[9]  = 32'hcb09018c;  // SUB X12, X12, X9
            words[10] = 32'h17fffffd;  // B -0x0c
            words[11] = 32'hf80203ed;  // STUR X13, [XZR, #0x20]
            words[12] = 32'hf84203ed;  // LDUR X13, [XZR, #0x20]
        end
    end

    // An invalid or unaligned fetch returns an unsupported opcode.
    assign Data = (Address[63:12] == 52'b0 && Address[1:0] == 2'b00) ?
                  words[Address[11:2]] : 32'b0;
endmodule
