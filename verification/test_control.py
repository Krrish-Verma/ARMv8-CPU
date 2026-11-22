"""Exhaustive checks of the 11-bit opcode interface."""

import cocotb
from cocotb.triggers import Timer

# The A64 instruction masks are projected onto bits [31:21] below.
# Expected control tuples list the enabled signals, ALU operation and format.
CONTROL_CASES = [
    (0xFFE00000, 0x8A000000, {"RegWrite"}, 0, 0),
    (0xFFE00000, 0xAA000000, {"RegWrite"}, 1, 0),
    (0xFFE00000, 0x8B000000, {"RegWrite"}, 2, 0),
    (0xFFE00000, 0xCB000000, {"RegWrite"}, 6, 0),
    (0xFF800000, 0x91000000, {"ALUSrc", "RegWrite"}, 2, 0),
    (0xFF800000, 0xD1000000, {"ALUSrc", "RegWrite"}, 6, 0),
    (0xFF800000, 0xD2800000, {"ALUSrc", "RegWrite"}, 7, 0),
    (0xFFE00000, 0xF8400000, {"ALUSrc", "MemtoReg", "RegWrite", "MemRead"}, 2, 1),
    (0xFFE00000, 0xF8000000, {"Reg2Loc", "ALUSrc", "MemWrite"}, 2, 1),
    (0xFF000000, 0xB4000000, {"Reg2Loc", "Branch"}, 7, 2),
    (0xFC000000, 0x14000000, {"Uncondbranch"}, 0, 3),
]
FLAGS = ("Reg2Loc", "ALUSrc", "MemtoReg", "RegWrite", "MemRead",
         "MemWrite", "Branch", "Uncondbranch")


@cocotb.test()
async def every_opcode(dut):
    matched = 0
    for opcode in range(1 << 11):
        dut.opcode.value = opcode
        await Timer(1, units="ns")

        instruction_prefix = opcode << 21
        matches = [(flags, alu, immediate) for mask, value, flags, alu, immediate
                   in CONTROL_CASES if (instruction_prefix & mask) == value]
        assert len(matches) <= 1, f"Ambiguous test pattern for opcode {opcode:011b}"
        expected = matches[0] if matches else (set(), 0, 0)
        matched += bool(matches)

        flags = {name for name in FLAGS if int(getattr(dut, name).value)}
        actual = flags, int(dut.ALUOp.value), int(dut.SignOp.value)
        assert actual == expected, f"opcode {opcode:011b}: got {actual}, expected {expected}"

    dut._log.info("Checked all 2048 opcode values: %d supported, %d default",
                  matched, 2048 - matched)
