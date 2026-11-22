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
    wire       MoveKeep;
    wire [3:0] ALUOp;
    wire [1:0] SignOp;

    // Datapath connections.
    wire [63:0] regoutA;
    wire [63:0] regoutB;
    wire [63:0] extimm;
    wire [63:0] moveWideImmediate;
    wire [63:0] moveKeepMask;
    wire [63:0] moveKeepResult;
    wire [63:0] aluImmediate;
    wire [63:0] aluInputB;
    wire [63:0] aluout;
    wire [63:0] memoryReadData;
    wire        zero;
    wire        isMOVZ;
    wire        isMOVK;
    wire [4:0]  readRegA;

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

    // MOVZ and MOVK contain a 16-bit immediate and a two-bit half-word
    // selector. Other immediate formats come from the Lab 6 SignExtender.
    assign isMOVZ = (opcode[10:2] == 9'b110100101);
    assign isMOVK = (opcode[10:2] == 9'b111100101);
    assign moveWideImmediate = {48'b0, instruction[20:5]}
                               << {instruction[22:21], 4'b0000};
    assign aluImmediate = (isMOVZ || isMOVK) ? moveWideImmediate : extimm;

    // MOVK reads the old value of Rd, clears only the selected 16-bit field,
    // and inserts the shifted immediate. All other instructions read Rn.
    assign readRegA = MoveKeep ? rd : rn;
    assign moveKeepMask = 64'h000000000000ffff
                          << {instruction[22:21], 4'b0000};
    assign moveKeepResult = (regoutA & ~moveKeepMask) | moveWideImmediate;

    // ALUSrc selects the second ALU operand.
    assign aluInputB = ALUSrc ? aluImmediate : regoutB;

    // MemtoReg selects what is written back into Rd/Rt.
    assign MemtoRegOut = MemtoReg ? memoryReadData
                                  : (MoveKeep ? moveKeepResult : aluout);

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
        .MoveKeep(MoveKeep),
        .ALUOp(ALUOp),
        .SignOp(SignOp),
        .opcode(opcode)
    );

    RegisterFile registerFile (
        .BusA(regoutA),
        .BusB(regoutB),
        .BusW(MemtoRegOut),
        .RA(readRegA),
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

