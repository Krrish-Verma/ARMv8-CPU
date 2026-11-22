# GTKWave startup script for the SingleCycleProc demonstration.
# Run after simulation with:
#   gtkwave singlecycle.vcd -S SingleCycleProcTest.gtkw.tcl

set processor_signals [list \
    {SingleCycleProcTest_v.CLK} \
    {SingleCycleProcTest_v.Reset} \
    {SingleCycleProcTest_v.currentPC[63:0]} \
    {SingleCycleProcTest_v.uut.instruction[31:0]} \
    {SingleCycleProcTest_v.uut.opcode[10:0]} \
    {SingleCycleProcTest_v.uut.Reg2Loc} \
    {SingleCycleProcTest_v.uut.ALUSrc} \
    {SingleCycleProcTest_v.uut.MemtoReg} \
    {SingleCycleProcTest_v.uut.RegWrite} \
    {SingleCycleProcTest_v.uut.MemRead} \
    {SingleCycleProcTest_v.uut.MemWrite} \
    {SingleCycleProcTest_v.uut.Branch} \
    {SingleCycleProcTest_v.uut.Uncondbranch} \
    {SingleCycleProcTest_v.uut.SignOp[1:0]} \
    {SingleCycleProcTest_v.uut.extimm[63:0]} \
    {SingleCycleProcTest_v.uut.regoutA[63:0]} \
    {SingleCycleProcTest_v.uut.regoutB[63:0]} \
    {SingleCycleProcTest_v.uut.ALUOp[3:0]} \
    {SingleCycleProcTest_v.uut.aluInputB[63:0]} \
    {SingleCycleProcTest_v.uut.aluout[63:0]} \
    {SingleCycleProcTest_v.uut.zero} \
    {SingleCycleProcTest_v.uut.memoryReadData[63:0]} \
    {SingleCycleProcTest_v.MemtoRegOut[63:0]} \
    {SingleCycleProcTest_v.uut.nextpc[63:0]}]

gtkwave::addSignalsFromList $processor_signals
gtkwave::/Time/Zoom/Zoom_Full
