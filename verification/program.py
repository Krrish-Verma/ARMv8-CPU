"""A64 instruction words and reproducible processor test programs."""

from random import Random
from typing import NamedTuple

ROM_WORDS = 1024
RANDOM_INSTRUCTIONS = 256

REGISTER_OPCODES = {
    "AND": 0x8A000000,
    "ORR": 0xAA000000,
    "ADD": 0x8B000000,
    "SUB": 0xCB000000,
}
IMMEDIATE_OPCODES = {"ADDI": 0x91000000, "SUBI": 0xD1000000}
MEMORY_OPCODES = {"LDUR": 0xF8400000, "STUR": 0xF8000000}


class Instruction(NamedTuple):
    op: str
    rd: int = 31
    rn: int = 31
    rm: int = 31
    imm: int = 0
    shift: int = 0


def encode(instruction):
    """Encode the supported fields or pass through an unsupported test word."""
    op, rd, rn, rm, imm, shift = instruction
    registers = (rn << 5) | rd

    if op in REGISTER_OPCODES:
        return REGISTER_OPCODES[op] | (rm << 16) | registers
    if op in IMMEDIATE_OPCODES:
        return IMMEDIATE_OPCODES[op] | ((shift // 12) << 22) | (imm << 10) | registers
    if op in MEMORY_OPCODES:
        return MEMORY_OPCODES[op] | ((imm & 0x1FF) << 12) | registers
    if op == "MOVZ":
        return 0xD2800000 | ((shift // 16) << 21) | (imm << 5) | rd
    if op == "CBZ":
        return 0xB4000000 | ((imm & 0x7FFFF) << 5) | rd
    if op == "B":
        return 0x14000000 | (imm & 0x3FFFFFF)
    if op == "unsupported":
        return imm
    raise ValueError(f"Unknown test instruction {op}")


def build_program(seed):
    rng = Random(seed)
    # The physical register file does not initialize X0 through X30.
    program = [Instruction("MOVZ", rd=reg, imm=rng.randrange(1, 65536))
               for reg in range(31)]
    program.extend([
        Instruction("MOVZ", rd=1, imm=0xABCD),
        Instruction("MOVZ", rd=2, imm=0xFEDC, shift=16),
        Instruction("MOVZ", rd=3, imm=0x9876, shift=32),
        Instruction("MOVZ", rd=4, imm=0x8123, shift=48),
        Instruction("MOVZ", rd=31, imm=0xFFFF),
        Instruction("ADDI", rd=5, imm=0xFFF, shift=12),
        Instruction("SUBI", rd=6, imm=1),
        Instruction("ADD", rd=7, rn=6, rm=31),
        Instruction("ADDI", rd=7, rn=7, imm=1),
        Instruction("SUBI", rd=8, rn=5, imm=0xABC, shift=12),
        Instruction("ORR", rd=9, rn=1, rm=4),
        Instruction("AND", rd=10, rn=9, rm=4),
        Instruction("SUB", rd=11, rn=9, rm=4),
        Instruction("MOVZ", rd=12, imm=8),
        Instruction("STUR", rd=9, rn=12, imm=-4),
        Instruction("LDUR", rd=13, rn=12, imm=-4),
        Instruction("LDUR", rd=14, rn=12, imm=-3),
        Instruction("MOVZ", rd=15, imm=1020),
        Instruction("STUR", rd=9, rn=15, imm=-4),  # Last valid address.
        Instruction("STUR", rd=31, rn=15, imm=-3),  # One byte too far.
        Instruction("LDUR", rd=16, rn=15, imm=-4),
        Instruction("LDUR", rd=16, rn=15, imm=-3),
        Instruction("STUR", rd=9, imm=-1),  # Unsigned address wraps to 2**64 - 1.
        Instruction("LDUR", rd=16, imm=-1),
        Instruction("unsupported", imm=0x8B010421),  # ADD X1, X1, X1, LSL #1.
        Instruction("unsupported", imm=0xF8000429),  # Post-indexed store.
        Instruction("unsupported", imm=0xF8400429),  # Post-indexed load.
        Instruction("unsupported", imm=0xFFFFFFFF),
        Instruction("MOVZ", rd=20, imm=3),
        Instruction("MOVZ", rd=21, imm=0),
        Instruction("ADDI", rd=21, rn=21, imm=1),  # Loop start.
        Instruction("SUBI", rd=20, rn=20, imm=1),
        Instruction("CBZ", rd=20, imm=2),
        Instruction("B", imm=-3),
        Instruction("CBZ", rd=1, imm=2),  # Fall through.
        Instruction("B", imm=2),
        Instruction("B", imm=3),  # Exit via the backward CBZ.
        Instruction("CBZ", imm=-1),  # Always taken through XZR.
        Instruction("MOVZ", rd=21, imm=0xBAD),  # Skipped.
        Instruction("MOVZ", rd=28, imm=256),  # Base for randomized memory accesses.
    ])

    operations = [*REGISTER_OPCODES, *IMMEDIATE_OPCODES, *MEMORY_OPCODES, "MOVZ"]
    destinations = [register for register in range(32) if register != 28]
    stored_offsets = set()
    for _ in range(RANDOM_INSTRUCTIONS):
        op = rng.choice(operations)
        rd = rng.choice(destinations)
        if op in REGISTER_OPCODES:
            instruction = Instruction(op, rd, rng.randrange(32), rng.randrange(32))
        elif op in IMMEDIATE_OPCODES:
            instruction = Instruction(
                op, rd, rng.randrange(32), imm=rng.randrange(4096), shift=rng.choice((0, 12))
            )
        elif op in MEMORY_OPCODES:
            instruction = Instruction(op, rd, rn=28, imm=rng.randrange(-256, 256))
            if op == "STUR":
                stored_offsets.add(instruction.imm)
        else:
            instruction = Instruction(op, rd, imm=rng.randrange(65536), shift=rng.randrange(4) * 16)
        program.append(instruction)

    # Check the final RAM contents at every randomized store and read all registers.
    program.extend(Instruction("LDUR", rn=28, imm=offset) for offset in sorted(stored_offsets))
    program.extend(Instruction("ORR", rd=31, rn=reg) for reg in range(32))
    return program
