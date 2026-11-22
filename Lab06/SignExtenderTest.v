`timescale 1ns / 1ps

// Self-checking testbench for SignExtender.
// This is simulation-only code; it is not synthesized into processor
// hardware. It creates directed and random inputs, computes the expected
// answer, and reports every mismatch.
module SignExtenderTest;

    // reg signals are driven by this testbench. SignExOut is a wire because
    // it is driven by the SignExtender DUT (Design Under Test).
    reg  [25:0] Instruction;
    reg  [1:0]  SignOp;
    wire [63:0] SignExOut;

    // Counters used to produce the final pass/fail summary.
    integer i;
    integer total_tests;
    integer error_count;

    // Readable names for the four SignOp encodings.
    localparam TYPE_I  = 2'b00;
    localparam TYPE_D  = 2'b01;
    localparam TYPE_CB = 2'b10;
    localparam TYPE_B  = 2'b11;

    // Connect the testbench signals to the hardware module being tested.
    SignExtender dut (
        .SignExOut  (SignExOut),
        .Instruction(Instruction),
        .SignOp     (SignOp)
    );

    // Run one test. The task first computes a reference result, then applies
    // the inputs to the DUT and compares its output with that result.
    task verify_test;
        input [25:0] test_instr;
        input [1:0]  test_signop;
        reg   [63:0] expected_out;
        begin
            case (test_signop)
                // The formulas below are the testbench's reference model.
                TYPE_I:  expected_out = {52'b0, test_instr[21:10]};
                TYPE_D:  expected_out = {{55{test_instr[20]}},
                                         test_instr[20:12]};
                TYPE_CB: expected_out = {{43{test_instr[23]}},
                                         test_instr[23:5], 2'b00};
                                       
                TYPE_B:  expected_out = {{36{test_instr[25]}},
                                         test_instr[25:0], 2'b00};
                default: expected_out = 64'b0; 
                
            endcase 
            Instruction = test_instr;
            SignOp      = test_signop;
            // Simulation-only delay that allows combinational signals to
            // settle before the output is checked.
            #5;

            total_tests = total_tests + 1;

            // Case inequality also treats X or Z bits as an error.
            if (SignExOut !== expected_out) begin
                error_count = error_count + 1;
                $display("ERROR: SignOp=%b Instruction=%h Expected=%h Got=%h",
                         test_signop, test_instr, expected_out, SignExOut);
            end
        end
    endtask

    initial begin
        // Record every testbench signal change for viewing in GTKWave.
        $dumpfile("SignExtenderTest.vcd");
        $dumpvars(0, SignExtenderTest);

        total_tests = 0;
        error_count = 0;
        Instruction = 26'b0;
        SignOp      = TYPE_I;
        #5;

        // Directed boundary tests exercise all-zero and all-one patterns,
        // including both possible values of every immediate sign bit.
        verify_test(26'b0,            TYPE_I);
        verify_test({26{1'b1}},       TYPE_I);
        verify_test(26'b0,            TYPE_D);
        verify_test({26{1'b1}},       TYPE_D);
        verify_test(26'b0,            TYPE_CB);
        verify_test({26{1'b1}},       TYPE_CB);
        verify_test(26'b0,            TYPE_B);
        verify_test({26{1'b1}},       TYPE_B);


        // Each format receives at least the required 100 random instructions.
        $display("Running 100 random I-type tests...");
        for (i = 0; i < 100; i = i + 1)
            verify_test($random, TYPE_I);

        $display("Running 100 random D-type tests...");
        for (i = 0; i < 100; i = i + 1)
            verify_test($random, TYPE_D);

        $display("Running 100 random CB-type tests...");
        for (i = 0; i < 100; i = i + 1)
            verify_test($random, TYPE_CB);

        $display("Running 100 random B-type tests...");
        for (i = 0; i < 100; i = i + 1)
            verify_test($random, TYPE_B);

        $display("=== Sign Extender Test Summary ===");
        $display("Total tests: %0d", total_tests);
        $display("Errors:      %0d", error_count);
        if (error_count == 0)
            $display("ALL TESTS PASSED");
        else
            $fatal(1, "Sign extender test failed");
        $finish;
    end

endmodule
