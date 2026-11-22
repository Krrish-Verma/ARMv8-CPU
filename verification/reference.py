"""Instruction-level scoreboard for the educational CPU profile."""

from dataclasses import dataclass, field
import operator

MASK64 = (1 << 64) - 1
BINARY_OPERATIONS = {
    "AND": operator.and_,
    "ORR": operator.or_,
    "ADD": operator.add,
    "SUB": operator.sub,
    "ADDI": operator.add,
    "SUBI": operator.sub,
}


@dataclass
class ReferenceCPU:
    pc: int = 0
    registers: list[int] = field(default_factory=lambda: [0] * 32)
    memory: bytearray = field(default_factory=lambda: bytearray(1024))

    def step(self, instruction):
        """Execute one semantic instruction and return its expected bus activity."""
        op, rd, rn, rm, imm, shift = instruction
        next_pc = self.pc + 4
        writeback = None
        store = None

        if op in BINARY_OPERATIONS:
            rhs = (imm << shift) if op in ("ADDI", "SUBI") else self.registers[rm]
            writeback = BINARY_OPERATIONS[op](self.registers[rn], rhs)
        elif op == "MOVZ":
            writeback = imm << shift
        elif op in ("LDUR", "STUR"):
            address = (self.registers[rn] + imm) & MASK64
            end = address + 8
            in_bounds = end <= len(self.memory)
            if op == "LDUR":
                writeback = int.from_bytes(self.memory[address:end], "big") if in_bounds else 0
            else:
                value = self.registers[rd]
                store = address, value
                if in_bounds:
                    self.memory[address:end] = value.to_bytes(8, "big")
        elif op == "B" or (op == "CBZ" and self.registers[rd] == 0):
            next_pc = self.pc + imm * 4

        if writeback is not None:
            writeback &= MASK64
            if rd != 31:
                self.registers[rd] = writeback
        self.pc = next_pc & MASK64
        return writeback, store
