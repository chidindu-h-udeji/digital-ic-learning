# Digital IC Design & FPGA Architecture — Learning Portfolio

Self-directed preparation for graduate research in digital IC design and FPGA architecture. Everything here — from HDL fundamentals through a pipelined RISC-V core to a full RTL-to-GDS physical design run — reflects independent understanding: AI tools were used throughout for explanation, debugging, scaffolding, and drafting documentation, but every design decision, testbench scenario, and result here is something I can walk through and defend line by line.

## Highlights
* **100+ HDLBits problems solved** across combinational logic, sequential logic, and finite state machines.
* **5-stage RV32I pipeline** — 13 integrated modules, hardware hazard detection and forwarding, measured CPI 1.60 (10 instructions retired, 16 cycles, exactly 1 architecturally unavoidable load-use stall).
* **Full RTL-to-GDS run on the Sky130 PDK via LibreLane** — diagnosed a hard timing failure to its physical root cause (flip-flop-based memory arrays driving 2,048-terminal fanout nets) and quantitatively showed that relaxing clock period fixes setup timing without resolving the underlying signal-integrity violation.
* **Independent Python tooling** — a timing-report parser and multi-run comparator.

## What's here

### `rtl_projects/safety_monitor/` — Safety Monitor FSM
First original RTL project. A 4-state Moore FSM for an IoT multi-gas detection system, with a 10-cycle fault-integration counter and a non-recoverable lockout state. Self-checking SystemVerilog testbench, 14+ scenarios including sub-clock-cycle glitch immunity, zero errors.

### `rtl_projects/riscv_pipeline/` — RISC-V RV32I Pipeline
A classic 5-stage pipeline (fetch → decode → execute → memory → writeback) with hazard detection and forwarding. A single stress-test program exercises EX/MEM forwarding, MEM/WB forwarding, store-data forwarding, a load-use stall, a taken-branch flush, and a not-taken branch in sequence — passes clean. 18-testbench regression suite, full hazard-scenario checklist, and measured performance numbers in the project README.

### `librelane/` — Physical Design (RTL-to-GDS)
The RISC-V pipeline taken through the full LibreLane flow on the Sky130 130nm PDK: synthesis, floorplanning, placement, clock tree synthesis, routing, and static timing analysis. Two clock constraints were run deliberately, to isolate a real signal-integrity problem from a simple timing violation. Full diagnosis, waveforms, and reproduction commands in the project README.

### `hdlbits/`
Solutions to 100+ HDLBits problems, spanning Verilog language basics through finite state machines — the foundational reps behind everything else in this repo.

### `scripts/`
`parse_timing.py` — a Python tool for parsing and comparing EDA timing reports across multiple synthesis runs.

## Tech stack
SystemVerilog · Icarus Verilog / EDA Playground / GTKWave · LibreLane (FOSSi Foundation) · Sky130 PDK · Python · WSL2 / Nix

## Future work
* **SRAM macro integration** — replacing the flip-flop-array memories identified in the LibreLane run with proper SRAM macros, to resolve the diagnosed fanout/signal-integrity issue directly rather than only documenting it.
* **Custom MAC accelerator instruction** — extending the RISC-V ISA with a multiply-accumulate instruction, to explore hardware acceleration at the ISA boundary.
* **FPGA implementation report (optional)** — synthesis and resource-utilization numbers via a free-tool FPGA flow, as a secondary data point alongside the ASIC flow above.

---
**About**
Built by Chidindu Henry Udeji. Individual project READMEs contain full technical detail, verification methodology, and results.
