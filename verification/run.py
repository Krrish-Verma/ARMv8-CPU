"""Build and run the RTL regressions from the repository root."""

import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
CONTROL = "Lab07/SingleCycleControl.v"
PROCESSOR = [
    "Lab07/SingleCycleProc.v",
    CONTROL,
    "Lab07/InstructionMemory.v",
    "Lab07/DataMemory.v",
    "Lab05/RegisterFile.v",
    "Lab06/ALU.v",
    "Lab06/SignExtender.v",
    "Lab06/NextPClogic.v",
]
LEGACY_TESTS = [
    ("ALUTest", "Lab06/ALUTest.v", ["Lab06/ALU.v"]),
    ("SignExtenderTest", "Lab06/SignExtenderTest.v", ["Lab06/SignExtender.v"]),
    ("SingleCycleControlTest", "Lab07/SingleCycleControlTest.v", [CONTROL]),
    ("RegisterFileTest", "Lab05/RegisterFileTest.v", ["Lab05/RegisterFile.v"]),
    ("mux2to1_8Test", "Lab05/mux2to1_8Test.v", ["Lab05/mux2to1_8.v"]),
    ("NextPClogicTest", "Lab06/NextPClogicTest.v", ["Lab06/NextPClogic.v"]),
    ("SingleCycleProcTest_v", "Lab07/SingleCycleProcTest.v", PROCESSOR),
]


def run_legacy():
    build_dir = BUILD / "icarus"
    build_dir.mkdir(parents=True, exist_ok=True)
    for top, testbench, sources in LEGACY_TESTS:
        executable = build_dir / top
        subprocess.run(
            ["iverilog", "-g2012", "-s", top, "-o", executable, testbench, *sources],
            cwd=ROOT,
            check=True,
        )
        subprocess.run(["vvp", executable], cwd=build_dir, check=True, timeout=30)


def run_cocotb(seed, waves):
    from cocotb.runner import get_results, get_runner

    from verification.program import ROM_WORDS, build_program, encode

    build_dir = BUILD / "verilator"
    cpu_dir = build_dir / "cpu"
    cpu_dir.mkdir(parents=True, exist_ok=True)
    words = [encode(instruction) for instruction in build_program(seed)]
    if len(words) >= ROM_WORDS:
        raise ValueError("The generated program must leave room for a blank instruction")
    words.extend([0] * (ROM_WORDS - len(words)))
    (cpu_dir / "program.hex").write_text(
        "".join(f"{word:08x}\n" for word in words), encoding="ascii"
    )

    suites = [
        ("control", "SC_Control", [CONTROL], {}, "verification.test_control", 1),
        (
            "cpu", "SingleCycleProc", PROCESSOR, {"PROGRAM_FILE": '"program.hex"'},
            "verification.test_cpu", 2,
        ),
    ]
    for directory, top, sources, parameters, module, expected_tests in suites:
        runner = get_runner("verilator")
        runner.build(
            hdl_toplevel=top,
            verilog_sources=[ROOT / source for source in sources],
            parameters=parameters,
            build_dir=build_dir / directory,
            waves=waves,
        )
        results = runner.test(
            hdl_toplevel=top,
            test_module=module,
            extra_env={"ARMV8_TEST_SEED": str(seed)},
            seed=seed,
            waves=waves,
        )
        tests, failures = get_results(results)
        if tests != expected_tests or failures:
            raise SystemExit(f"{top}: expected {expected_tests} passing tests; ran {tests}, {failures} failed")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", nargs="?", choices=("all", "legacy", "cocotb"), default="all")
    parser.add_argument("--seed", type=lambda number: int(number, 0), default=0x350)
    parser.add_argument("--waves", action="store_true", help="save Verilator VCD traces")
    args = parser.parse_args()
    if args.suite in ("all", "legacy"):
        run_legacy()
    if args.suite in ("all", "cocotb"):
        run_cocotb(args.seed, args.waves)


if __name__ == "__main__":
    main()
