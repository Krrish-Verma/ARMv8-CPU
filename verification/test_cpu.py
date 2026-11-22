"""Cycle-by-cycle checks against a Python instruction-level model."""

import os

import cocotb
from cocotb.triggers import Timer

from verification.program import Instruction, RANDOM_INSTRUCTIONS, build_program, encode
from verification.reference import ReferenceCPU


def current_program():
    return build_program(int(os.environ["ARMV8_TEST_SEED"]))


async def tick(dut):
    dut.CLK.value = 1
    await Timer(5, units="ns")
    dut.CLK.value = 0
    await Timer(5, units="ns")


async def reset_to(dut, pc):
    dut.CLK.value = 0
    dut.startpc.value = pc
    dut.reset.value = 1
    await Timer(5, units="ns")
    await tick(dut)
    assert int(dut.currentpc.value) == pc


async def checked_step(dut, model, instruction):
    pc = model.pc
    context = f"PC {pc:#x}, {instruction}"
    assert int(dut.currentpc.value) == pc, context
    assert int(dut.instruction.value) == encode(instruction), f"{context}: fetch"

    writeback, store = model.step(instruction)
    assert int(dut.regWriteEnable.value) == int(writeback is not None), f"{context}: RegWrite"
    assert int(dut.memWriteEnable.value) == int(store is not None), f"{context}: MemWrite"

    if writeback is not None:
        assert int(dut.rd.value) == instruction.rd, f"{context}: write destination"
        actual = int(dut.MemtoRegOut.value)
        assert actual == writeback, f"{context}: write-back {actual:#x} != {writeback:#x}"
    if store is not None:
        actual = int(dut.aluout.value), int(dut.regoutB.value)
        assert actual == store, f"{context}: store (address, data) {actual!r} != {store!r}"

    await tick(dut)
    next_pc = int(dut.currentpc.value)
    assert next_pc == model.pc, f"{context}: next PC {next_pc:#x} != {model.pc:#x}"


@cocotb.test()
async def directed_and_random_program(dut):
    program = current_program()
    model = ReferenceCPU()
    await reset_to(dut, 0)
    dut.reset.value = 0
    await Timer(1, units="ns")

    for cycles in range(1, len(program) + 33):
        instruction = program[model.pc // 4]
        await checked_step(dut, model, instruction)
        if model.pc == len(program) * 4:
            break
    else:
        assert False, "Program failed to reach the end within its cycle budget"

    await checked_step(dut, model, Instruction("unsupported"))
    dut._log.info("Checked %d cycles including %d randomized instructions (seed %s)",
                  cycles + 1, RANDOM_INSTRUCTIONS, os.environ["ARMV8_TEST_SEED"])


@cocotb.test()
async def reset_and_invalid_fetch(dut):
    await reset_to(dut, 0)
    assert int(dut.RegWrite.value) == 1
    assert int(dut.regWriteEnable.value) == 0

    store_pc = 4 * next(index for index, instruction in enumerate(current_program())
                        if instruction.op == "STUR")
    dut.startpc.value = store_pc
    await tick(dut)
    assert int(dut.currentpc.value) == store_pc
    assert int(dut.MemWrite.value) == 1
    assert int(dut.memWriteEnable.value) == 0

    for pc in (1, 0x1000, 0xFFFFFFFFFFFFFFFC):
        await reset_to(dut, pc)
        dut.reset.value = 0
        await Timer(1, units="ns")
        await checked_step(dut, ReferenceCPU(pc=pc), Instruction("unsupported"))
