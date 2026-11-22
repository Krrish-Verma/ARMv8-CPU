 `timescale 1ns / 1ps

module SingleCycleControlTest;
    reg  [10:0] opcode;
    wire        Reg2Loc;
    wire        ALUSrc;
    wire        MemtoReg;
    wire        RegWrite;
    wire        MemRead;
    wire        MemWrite;
    wire        Branch;
    wire        Uncondbranch;
    wire [3:0]  ALUOp;
    wire [1:0]  SignOp;

    integer i;
    integer errors;
    integer total_tests;
    integer random_seed;
    reg [10:0] random_opcode;

    wire [13:0] actual_controls = {
        Reg2Loc, ALUSrc, MemtoReg, RegWrite,
        MemRead, MemWrite, Branch, Uncondbranch,
        ALUOp, SignOp
    };

    localparam [13:0] CTRL_DEFAULT =
        {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,2'b00};
    localparam [13:0] CTRL_AND =
        {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0000,2'b00};
    localparam [13:0] CTRL_ORR =
        {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0001,2'b00};
    localparam [13:0] CTRL_ADD =
        {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0010,2'b00};
    localparam [13:0] CTRL_SUB =
        {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0110,2'b00};
    localparam [13:0] CTRL_ADDI =
        {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0010,2'b00};
    localparam [13:0] CTRL_SUBI =
        {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0110,2'b00};
    localparam [13:0] CTRL_MOVZ =
        {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0111,2'b00};
    localparam [13:0] CTRL_LDUR =
        {1'b0,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,4'b0010,2'b01};
    localparam [13:0] CTRL_STUR =
        {1'b1,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,4'b0010,2'b01};
    localparam [13:0] CTRL_CBZ =
        {1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,4'b0111,2'b10};
    localparam [13:0] CTRL_B =
        {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,4'b0000,2'b11};

    SC_Control dut (
        .Reg2Loc(Reg2Loc), .ALUSrc(ALUSrc), .MemtoReg(MemtoReg),
        .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite),
        .Branch(Branch), .Uncondbranch(Uncondbranch),
        .ALUOp(ALUOp), .SignOp(SignOp), .opcode(opcode)
    );

    function is_supported;
        input [10:0] candidate;
        begin
            casez (candidate)
                11'b10001010000, 11'b10101010000,
                11'b10001011000, 11'b11001011000,
                11'b100100010??, 11'b110100010??,
                11'b110100101??, 11'b000101?????,
                11'b10110100???, 11'b11111000010,
                11'b11111000000: is_supported = 1'b1;
                default:          is_supported = 1'b0;
            endcase
        end
    endfunction

    task check_control;
        input [13:0] expected_controls;
        begin
            #5;
            total_tests = total_tests + 1;
            if (actual_controls !== expected_controls) begin
                errors = errors + 1;
                $display("ERROR test %0d: opcode=%b expected=%b actual=%b",
                         total_tests, opcode, expected_controls, actual_controls);
            end
        end
    endtask

    initial begin
        $dumpfile("SingleCycleControlTest.vcd");
        $dumpvars(0, SingleCycleControlTest);
        opcode = 11'b0;
        errors = 0;
        total_tests = 0;
        random_seed = 32'h350007;

        opcode = 11'b10001010000; check_control(CTRL_AND);
        opcode = 11'b10101010000; check_control(CTRL_ORR);
        opcode = 11'b10001011000; check_control(CTRL_ADD);
        opcode = 11'b11001011000; check_control(CTRL_SUB);
        opcode = 11'b11111000010; check_control(CTRL_LDUR);
        opcode = 11'b11111000000; check_control(CTRL_STUR);

        for (i = 0; i < 2; i = i + 1) begin
            opcode = 11'b10010001000 + i; check_control(CTRL_ADDI);
        end
        for (i = 0; i < 2; i = i + 1) begin
            opcode = 11'b11010001000 + i; check_control(CTRL_SUBI);
        end
        for (i = 0; i < 4; i = i + 1) begin
            opcode = 11'b11010010100 + i; check_control(CTRL_MOVZ);
        end
        for (i = 0; i < 8; i = i + 1) begin
            opcode = 11'b10110100000 + i; check_control(CTRL_CBZ);
        end
        for (i = 0; i < 32; i = i + 1) begin
            opcode = 11'b00010100000 + i; check_control(CTRL_B);
        end

        for (i = 0; i < 10; i = i + 1) begin
            random_opcode = $random(random_seed);
            while (is_supported(random_opcode))
                random_opcode = $random(random_seed);
            opcode = random_opcode;
            check_control(CTRL_DEFAULT);
            $display("Unsupported opcode %0d checked: %b", i + 1, opcode);
        end

        $display("=== SingleCycleControl Test Summary ===");
        $display("Total tests: %0d", total_tests);
        $display("Errors:      %0d", errors);
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $fatal(1, "Control test failed");
        $finish;
    end
endmodule
