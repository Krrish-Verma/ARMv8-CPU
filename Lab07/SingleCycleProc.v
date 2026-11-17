`timescale 1ns / 1ps

module SingleCycleProc(
    input             reset,       // Active high, synchronous reset
    input      [63:0] startpc,
    output reg [63:0] currentpc,
    output     [63:0] MemtoRegOut,  // Register-file write-back bus
    input             CLK
);

    // Program-counter and instruction-memory connections.
    wire [63:0] nextpc;
    wire [31:0] instruction;

    // ARMv8 register fields.
    wire [4:0] rd;       // Rd or Rt: instruction[4:0]
    wire [4:0] rn;       // Rn:       instruction[9:5]
    wire [4:0] rm;       // Rm:       instruction[20:16]
    wire [4:0] readRegB;
    wire [10:0] opcode;

    // Main-control outputs.
    wire       Reg2Loc;
    wire       ALUSrc;
    wire       MemtoReg;
    wire       RegWrite;
    wire       MemRead;
    wire       MemWrite;
    wire       Branch;
    wire       Uncondbranch;
    wire [3:0] ALUOp;
    wire [1:0] SignOp;

    // Datapath connections.
    wire [63:0] regoutA;
    wire [63:0] regoutB;
    wire [63:0] extimm;
    wire [63:0] aluInputB;
    wire [63:0] aluout;
    wire [63:0] memoryReadData;
    wire        zero;

    // The PC is the only state element owned directly by this module.
    always @(posedge CLK) begin
        if (reset)
            currentpc <= #3 startpc;
        else
            currentpc <= #3 nextpc;
    end

    assign rd = instruction[4:0];
    assign rn = instruction[9:5];
    assign rm = instruction[20:16];
    assign opcode = instruction[31:21];

    // STUR and CBZ read Rt through the second register-file port. R-format
    // instructions read Rm instead.
    assign readRegB = Reg2Loc ? rd : rm;

    // ALUSrc selects the second ALU operand.
    assign aluInputB = ALUSrc ? extimm : regoutB;

    // MemtoReg selects what is written back into Rd/Rt.
    assign MemtoRegOut = MemtoReg ? memoryReadData : aluout;

    InstructionMemory instructionMemory (
        .Data(instruction),
        .Address(currentpc)
    );

    SC_Control controlUnit (
        .Reg2Loc(Reg2Loc),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Uncondbranch(Uncondbranch),
        .ALUOp(ALUOp),
        .SignOp(SignOp),
        .opcode(opcode)
    );

    RegisterFile registerFile (
        .BusA(regoutA),
        .BusB(regoutB),
        .BusW(MemtoRegOut),
        .RA(rn),
        .RB(readRegB),
        .RW(rd),
        .RegWr(RegWrite),
        .Clk(CLK)
    );

    SignExtender signExtender (
        .SignExOut(extimm),
        .Instruction(instruction[25:0]),
        .SignOp(SignOp)
    );

    ALU arithmeticLogicUnit (
        .BusW(aluout),
        .BusA(regoutA),
        .BusB(aluInputB),
        .ALUCtrl(ALUOp),
        .Zero(zero)
    );

    DataMemory dataMemory (
        .ReadData(memoryReadData),
        .Address(aluout),
        .WriteData(regoutB),
        .MemoryRead(MemRead),
        .MemoryWrite(MemWrite),
        .Clock(CLK)
    );

    NextPClogic nextPCLogic (
        .NextPC(nextpc),
        .CurrentPC(currentpc),
        .SignExtImm64(extimm),
        .Branch(Branch),
        .ALUZero(zero),
        .Uncondbranch(Uncondbranch)
    );

endmodule

