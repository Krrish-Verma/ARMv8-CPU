`timescale 1ns / 1ps

module RegisterFileTest;
    reg  [63:0] BusW;
    reg  [4:0]  RA;
    reg  [4:0]  RB;
    reg  [4:0]  RW;
    reg         RegWr;
    reg         Clk;
    wire [63:0] BusA;
    wire [63:0] BusB;
    integer errors;
    integer i;

    RegisterFile dut (
        .BusA(BusA), .BusB(BusB), .BusW(BusW),
        .RA(RA), .RB(RB), .RW(RW), .RegWr(RegWr), .Clk(Clk)
    );

    task write_register;
        input [4:0] address;
        input [63:0] data;
        begin
            RW = address;
            BusW = data;
            RegWr = 1'b1;
            #4 Clk = 1'b1;
            #1 Clk = 1'b0;
            RegWr = 1'b0;
        end
    endtask

    task check_reads;
        input [4:0] address_a;
        input [4:0] address_b;
        input [63:0] expected_a;
        input [63:0] expected_b;
        begin
            RA = address_a;
            RB = address_b;
            #1;
            if ((BusA !== expected_a) || (BusB !== expected_b)) begin
                errors = errors + 1;
                $display("ERROR: RA=%0d RB=%0d expected A=%h B=%h got A=%h B=%h",
                         address_a, address_b, expected_a, expected_b, BusA, BusB);
            end
        end
    endtask

    initial begin
        Clk = 1'b0;
        RegWr = 1'b0;
        BusW = 64'b0;
        RA = 5'd31;
        RB = 5'd31;
        RW = 5'd0;
        errors = 0;

        // XZR must read zero before and after an attempted write.
        check_reads(5'd31, 5'd31, 64'b0, 64'b0);
        write_register(5'd31, 64'hffffffffffffffff);
        check_reads(5'd31, 5'd31, 64'b0, 64'b0);

        // Populate every writable register with a distinct value.
        for (i = 0; i < 31; i = i + 1)
            write_register(i[4:0], 64'h1000000000000000 + i);

        // Verify both asynchronous read ports and preservation of all values.
        for (i = 0; i < 31; i = i + 1)
            check_reads(i[4:0], (30-i),
                        64'h1000000000000000 + i,
                        64'h1000000000000000 + (30-i));

        // A rising edge with RegWr low must not change the selected register.
        RW = 5'd7;
        BusW = 64'hdeadbeefcafef00d;
        RegWr = 1'b0;
        #4 Clk = 1'b1;
        #1 Clk = 1'b0;
        check_reads(5'd7, 5'd31, 64'h1000000000000007, 64'b0);

        if (errors == 0)
            $display("RegisterFile: ALL 34 TESTS PASSED");
        else
            $fatal(1, "RegisterFile: %0d TESTS FAILED", errors);
        $finish;
    end
endmodule
