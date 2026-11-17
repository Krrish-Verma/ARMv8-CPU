`timescale 1ns / 1ps

module mux2to1_8Test;
    reg  [7:0] in0;
    reg  [7:0] in1;
    reg        sel;
    wire [7:0] out;
    integer errors;
    integer i;

    mux2to1_8 dut (.in0(in0), .in1(in1), .sel(sel), .out(out));

    task check;
        input [7:0] test_in0;
        input [7:0] test_in1;
        input       test_sel;
        input [7:0] expected;
        begin
            in0 = test_in0;
            in1 = test_in1;
            sel = test_sel;
            #1;
            if (out !== expected) begin
                errors = errors + 1;
                $display("ERROR: in0=%h in1=%h sel=%b expected=%h got=%h",
                         test_in0, test_in1, test_sel, expected, out);
            end
        end
    endtask

    initial begin
        errors = 0;
        check(8'h00, 8'hff, 1'b0, 8'h00);
        check(8'h00, 8'hff, 1'b1, 8'hff);
        for (i = 0; i < 100; i = i + 1) begin
            in0 = $random;
            in1 = $random;
            check(in0, in1, 1'b0, in0);
            check(in0, in1, 1'b1, in1);
        end
        if (errors == 0)
            $display("mux2to1_8: ALL 202 TESTS PASSED");
        else
            $display("mux2to1_8: %0d TESTS FAILED", errors);
        $finish;
    end
endmodule
