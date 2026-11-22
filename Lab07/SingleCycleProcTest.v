`timescale 1ns / 1ps

`define STRLEN 40
`define HalfClockPeriod 60
`define ClockPeriod (`HalfClockPeriod * 2)

module SingleCycleProcTest_v;

   initial begin
      $dumpfile("singlecycle.vcd");
      $dumpvars(0, SingleCycleProcTest_v);
   end

   // Check one 64-bit result and increment passed when it is correct.
   // Case equality also treats an X or Z in actualOut as a failed test.
   task passTest;
      input [63:0] actualOut;
      input [63:0] expectedOut;
      input [`STRLEN*8-1:0] testType;
      inout [7:0] passed;
      begin
         if (actualOut === expectedOut) begin
            $display("PASS: %s = 0x%016h", testType, actualOut);
            passed = passed + 1;
         end
         else begin
            $display("FAIL: %s = 0x%016h, expected 0x%016h",
                     testType, actualOut, expectedOut);
         end
      end
   endtask

   // Print the final summary after Program 1 has completed.
   task allPassed;
      input [7:0] passed;
      input [7:0] numTests;
      begin
         $display("=== SingleCycleProc Test Summary ===");
         if (passed == numTests)
            $display("ALL PROCESSOR TESTS PASSED: %0d of %0d", passed, numTests);
         else
            $fatal(1, "PROCESSOR TEST FAILED: %0d of %0d passed", passed, numTests);
      end
   endtask

   // Inputs to the processor.
   reg        CLK;
   reg        Reset;
   reg [63:0] startPC;
   reg [7:0]  passed;

   // Values used by the self-checking tests.
   integer program1Cycles;
   integer program1Iterations;

   // Processor outputs.
   wire [63:0] MemtoRegOut;
   wire [63:0] currentPC;

   // Instantiate the Unit Under Test. The supplied starter used the old name
   // "singlecycle"; the completed processor module is named SingleCycleProc.
   SingleCycleProc uut (
      .CLK(CLK),
      .reset(Reset),
      .startpc(startPC),
      .currentpc(currentPC),
      .MemtoRegOut(MemtoRegOut)
   );

   initial begin
      Reset = 1'b1;
      startPC = 64'h0;
      passed = 0;
      program1Cycles = 0;
      program1Iterations = 0;

      // ---------------------------------------------------------------
      // Program 1: original processor test at address 0x000.
      // ---------------------------------------------------------------
      $display("Starting original Program 1...");

      // Hold synchronous reset across two rising edges, then release it on a
      // falling edge. This avoids racing the processor's posedge PC update.
      repeat (2) @(posedge CLK);
      @(negedge CLK);
      Reset = 1'b0;

      // Run until the final LDUR at address 0x30 is selected.
      while (currentPC < 64'h30) begin
         @(posedge CLK);
         @(negedge CLK);
         program1Cycles = program1Cycles + 1;
         if (currentPC == 64'h20)
            program1Iterations = program1Iterations + 1;
      end

      #1; 
      passTest(MemtoRegOut, 64'h000000000000000f,
               "Program 1 loaded result", passed);
      passTest(program1Iterations, 64'd15,
               "Program 1 loop iterations", passed);
      passTest(currentPC, 64'h0000000000000030,
               "Program 1 final PC", passed);
      $display("Program 1 cycles executed: %0d", program1Cycles);

      // Three total checks are performed for the original processor program.
      allPassed(passed, 3);
      $finish;
   end

   // Initialize the clock low, then toggle it every half period.
   initial begin
      CLK = 1'b0;
   end

   always #`HalfClockPeriod CLK = ~CLK;

   initial begin
      #(`ClockPeriod * 256);
      $fatal(1, "Processor did not reach the demo's final load");
   end

endmodule
