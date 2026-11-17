`timescale 1ns / 1ps

module NextPClogicTest;
    reg  [63:0] CurrentPC;
    reg  [63:0] SignExtImm64;
    reg         Branch;
    reg         ALUZero;
    reg         Uncondbranch;
    wire [63:0] NextPC;
    integer errors;

    NextPClogic dut (
        .NextPC(NextPC), .CurrentPC(CurrentPC),
        .SignExtImm64(SignExtImm64), .Branch(Branch),
        .ALUZero(ALUZero), .Uncondbranch(Uncondbranch)
    );

    task check;
        input [63:0] pc;
        input [63:0] immediate;
        input        conditional;
        input        zero;
        input        unconditional;
        input [63:0] expected;
        begin
            CurrentPC = pc;
            SignExtImm64 = immediate;
            Branch = conditional;
            ALUZero = zero;
            Uncondbranch = unconditional;
            #1;
            if (NextPC !== expected) begin
                errors = errors + 1;
                $display("ERROR: PC=%h imm=%h B=%b Z=%b UB=%b expected=%h got=%h",
                         pc, immediate, conditional, zero, unconditional,
                         expected, NextPC);
            end
        end
    endtask

    initial begin
        errors = 0;
        check(64'h100, 64'h40,  1'b0, 1'b0, 1'b0, 64'h104);
        check(64'h100, 64'h40,  1'b1, 1'b0, 1'b0, 64'h104);
        check(64'h100, 64'h40,  1'b1, 1'b1, 1'b0, 64'h140);
        check(64'h100, 64'h40,  1'b0, 1'b0, 1'b1, 64'h140);
        check(64'h100, -64'sd16, 1'b1, 1'b1, 1'b0, 64'h0f0);
        check(64'h100, -64'sd16, 1'b0, 1'b0, 1'b1, 64'h0f0);
        check(64'hfffffffffffffffc, 64'h0, 1'b0, 1'b0, 1'b0,
              64'h0000000000000000);

        if (errors == 0)
            $display("NextPClogic: ALL 7 TESTS PASSED");
        else
            $display("NextPClogic: %0d TESTS FAILED", errors);
        $finish;
    end
endmodule
