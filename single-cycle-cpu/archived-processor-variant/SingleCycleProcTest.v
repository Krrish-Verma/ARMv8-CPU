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

   // Print the final summary after both programs have completed.
   task allPassed;
      input [7:0] passed;
      input [7:0] numTests;
      begin
         $display("=== SingleCycleProc Test Summary ===");
         if (passed == numTests)
            $display("ALL PROCESSOR TESTS PASSED: %0d of %0d", passed, numTests);
         else
            $display("PROCESSOR TEST FAILED: %0d of %0d passed", passed, numTests);
      end
   endtask

   // Inputs to the processor.
   reg        CLK;
   reg        Reset;
   reg [63:0] startPC;
   reg [7:0]  passed;
   reg [15:0] watchdog;

   // Values used by the self-checking tests.
   integer program1Cycles;
   integer program1Iterations;
   integer program2Cycles;

   // Processor outputs.
   wire [63:0] MemtoRegOut;
   wire [63:0] currentPC;

   // Debug wires make the required architectural results easy to check and
   // easy to display in GTKWave.
   wire [63:0] debugX9 = uut.registerFile.registers[9];
   wire [63:0] debugX10 = uut.registerFile.registers[10];
   wire [63:0] debugMemory28 = {
      uut.dataMemory.memBank[40], uut.dataMemory.memBank[41],
      uut.dataMemory.memBank[42], uut.dataMemory.memBank[43],
      uut.dataMemory.memBank[44], uut.dataMemory.memBank[45],
      uut.dataMemory.memBank[46], uut.dataMemory.memBank[47]
   };

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
      watchdog = 0;
      program1Cycles = 0;
      program1Iterations = 0;
      program2Cycles = 0;

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

      // ---------------------------------------------------------------
      // Program 2: MOVZ/MOVK extension test at address 0x100.
      // ---------------------------------------------------------------
      $display("Starting MOVZ/MOVK Program 2...");
      startPC = 64'h0000000000000100;
      Reset = 1'b1;

      // Reset the PC to 0x100. The register file and data memory retain their
      // state, but Program 2 begins by overwriting X9 with MOVZ.
      @(posedge CLK);
      @(negedge CLK);
      Reset = 1'b0;

      // Execute through LDUR at 0x114. Address 0x118 contains a terminal
      // self-branch, so reaching it proves the load has written X10.
      while (currentPC < 64'h118) begin
         @(posedge CLK);
         @(negedge CLK);
         program2Cycles = program2Cycles + 1;
      end

      #1;
      passTest(debugX9, 64'h123456789abcdef0,
               "Program 2 value constructed in X9", passed);
      passTest(debugMemory28, 64'h123456789abcdef0,
               "Program 2 value stored at address 0x28", passed);
      passTest(debugX10, 64'h123456789abcdef0,
               "Program 2 value loaded into X10", passed);
      passTest(currentPC, 64'h0000000000000118,
               "Program 2 final PC", passed);
      $display("Program 2 cycles executed: %0d", program2Cycles);

      // Seven total checks: three from Program 1 and four from Program 2.
      allPassed(passed, 7);
      $finish;
   end

   // Initialize the clock low, then toggle it every half period.
   initial begin
      CLK = 1'b0;
   end

   always begin
      #`HalfClockPeriod CLK = ~CLK;
      #`HalfClockPeriod CLK = ~CLK;
      watchdog = watchdog + 1;
   end

   // The original starter compared against 16'h00ff even though its comment
   // said 64K cycles. 16'hffff is the correct 16-bit terminal count.
   always @(*) begin
      if (watchdog == 16'hffff) begin
         $display("Watchdog Timer Expired.");
         $finish;
      end
   end

endmodule
