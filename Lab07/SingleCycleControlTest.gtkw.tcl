                                                     # GTKWave startup script for the SingleCycleControl demonstration.
# Usage: gtkwave SingleCycleControlTest.vcd -S SingleCycleControlTest.gtkw.tcl

set control_signals [list \
    {SingleCycleControlTest.opcode[10:0]} \
    {SingleCycleControlTest.Reg2Loc} \
    {SingleCycleControlTest.ALUSrc} \
    {SingleCycleControlTest.MemtoReg} \
    {SingleCycleControlTest.RegWrite} \
    {SingleCycleControlTest.MemRead} \
    {SingleCycleControlTest.MemWrite} \
    {SingleCycleControlTest.Branch} \
    {SingleCycleControlTest.Uncondbranch} \
    {SingleCycleControlTest.ALUOp[3:0]} \
    {SingleCycleControlTest.SignOp[1:0]} \
    {SingleCycleControlTest.total_tests[31:0]} \
    {SingleCycleControlTest.errors[31:0]}]

gtkwave::addSignalsFromList $control_signals
gtkwave::/Time/Zoom/Zoom_Full
