`timescale 1ns / 1ps

// Self-checking testbench for the 64-bit ALU.
// This simulation-only module supplies inputs, computes the correct result
// independently, checks BusW and Zero, and records waveforms for GTKWave.
module ALUTest;

    // Inputs driven by the testbench and outputs driven by the DUT.
    reg  [63:0] BusA;
    reg  [63:0] BusB;
    reg  [3:0]  ALUCtrl;
    wire [63:0] BusW;
    wire        Zero;

    // Loop variables and pass/fail counters.
    integer i;
    integer operation_number;
    integer total_tests;
    integer error_count;

    // Temporary values used while creating random test vectors.
    reg [63:0] random_a;
    reg [63:0] random_b;
    reg [3:0]  current_control;
                                      
    // Readable names for the five  supported ALU control encodings.
    localparam OP_AND   = 4'b0000;
    localparam OP_OR    = 4'b0001;
    localparam OP_ADD   = 4'b0010;
    localparam OP_SUB   = 4'b0110;
    localparam OP_PASSB = 4'b0111;   //control  definitions   

    // Instantiate and connect the ALU being tested.
    ALU dut (
        .BusW   (BusW),                         
        .BusA   (BusA),
        .BusB   (BusB),
        .ALUCtrl(ALUCtrl),
        .Zero   (Zero)
    );

    // Run one self-checking test. expected_w is the reference result and
    // expected_zero is calculated from that result rather than from the DUT.
    task verify_test;
        input [3:0]  test_control;
        input [63:0] test_a;
        input [63:0] test_b;
        reg   [63:0] expected_w;
        reg          expected_zero;
        begin
            case (test_control)
                OP_AND:   expected_w = test_a & test_b;
                OP_OR:    expected_w = test_a | test_b;
                OP_ADD:   expected_w = test_a + test_b;
                OP_SUB:   expected_w = test_a - test_b;
                OP_PASSB: expected_w = test_b;
                default:  expected_w = 64'b0;
            endcase

            // The Zero flag must depend on the result for every operation.
            expected_zero = (expected_w == 64'b0);

            ALUCtrl = test_control;
            BusA    = test_a;
            BusB    = test_b;
            // Simulation-only settling time for the combinational ALU.
            #5;

            total_tests = total_tests + 1;

            // Case inequality catches wrong values as well as X and Z bits.
            if ((BusW !== expected_w) || (Zero !== expected_zero)) begin
                error_count = error_count + 1;
                $display("ERROR: Ctrl=%b A=%h B=%h ExpectedW=%h ExpectedZero=%b GotW=%h GotZero=%b",
                         test_control, test_a, test_b, expected_w,
                         expected_zero, BusW, Zero);
            end
        end
    endtask

    initial begin
        // Create the waveform file used for the GTKWave demonstration.
        $dumpfile("ALUTest.vcd");
        $dumpvars(0, ALUTest);

        total_tests = 0;
        error_count = 0;
        BusA        = 64'b0;
        BusB        = 64'b0;
        ALUCtrl     = OP_AND;
        #5;

        // Repeat the complete directed/random test set for every ALU function.
        for (operation_number = 0;
             operation_number < 5;
             operation_number = operation_number + 1) begin

            case (operation_number)
                0: current_control = OP_AND;
                1: current_control = OP_OR;
                2: current_control = OP_ADD;
                3: current_control = OP_SUB;
                4: current_control = OP_PASSB;
                default: current_control = OP_AND;
            endcase

            $display("Running directed tests for ALUCtrl=%b...",
                     current_control);

            // Every all-zero/all-one combination for BusA and BusB.
            verify_test(current_control, 64'h0000000000000000,
                                         64'h0000000000000000);
            verify_test(current_control, 64'h0000000000000000,
                                         64'hFFFFFFFFFFFFFFFF);
            verify_test(current_control, 64'hFFFFFFFFFFFFFFFF,
                                         64'h0000000000000000);
            verify_test(current_control, 64'hFFFFFFFFFFFFFFFF,
                                         64'hFFFFFFFFFFFFFFFF);

            // An explicit Zero=1 and Zero=0 test for every function.
            case (current_control)
                OP_AND: begin
                    verify_test(OP_AND, 64'hF0F0F0F0F0F0F0F0,
                                        64'h0F0F0F0F0F0F0F0F);
                    verify_test(OP_AND, 64'hF0F0F0F0F0F0F0F0,
                                        64'hF0F0F0F0F0F0F0F0);
                end
                OP_OR: begin
                    verify_test(OP_OR, 64'h0, 64'h0);
                    verify_test(OP_OR, 64'h0, 64'h1);
                end
                OP_ADD: begin
                    verify_test(OP_ADD, 64'h0, 64'h0);
                    verify_test(OP_ADD, 64'h1, 64'h0);
                end
                OP_SUB: begin
                    verify_test(OP_SUB, 64'h1, 64'h1);
                    verify_test(OP_SUB, 64'h1, 64'h0);
                end
                OP_PASSB: begin
                    verify_test(OP_PASSB, 64'h123456789ABCDEF0,
                                          64'h0);
                    verify_test(OP_PASSB, 64'h0,
                                          64'h123456789ABCDEF0);
                end
            endcase

            $display("Running 100 random tests for ALUCtrl=%b...",
                     current_control);

            // $random supplies 32 bits, so two calls are concatenated to make
            // each complete 64-bit operand.
            for (i = 0; i < 100; i = i + 1) begin
                random_a = {$random, $random};
                random_b = {$random, $random};
                verify_test(current_control, random_a, random_b);
            end
        end

        // Signed overflow: the largest positive signed value plus one wraps
        // to the most negative signed 64-bit bit pattern.
        verify_test(OP_ADD, 64'h7FFFFFFFFFFFFFFF, 64'h1);

        // Unsigned wraparound: the carry beyond bit 63 is discarded, leaving
        // a zero result and therefore setting the Zero flag.
        verify_test(OP_ADD, 64'hFFFFFFFFFFFFFFFF, 64'h1);

        $display("=== ALU Test Summary ===");
        $display("Total tests: %0d", total_tests);
        $display("Errors:      %0d", error_count);

        if (error_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED");

        $finish;
    end

endmodule
