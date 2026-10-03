# Digital IC Design & FPGA Architecture — Learning Portfolio

Self-directed preparation for graduate research in digital IC design and FPGA architecture. Everything here — from HDL fundamentals through a pipelined RISC-V core to a full RTL-to-GDS physical design run — reflects independent understanding: AI tools were used throughout for explanation, debugging, scaffolding, and drafting documentation, but every design decision, testbench scenario, and result here is something I can walk through and defend line by line.

## Highlights
* **100+ HDLBits problems solved** across combinational logic, sequential logic, and finite state machines.
* **5-stage RV32I subset pipeline** — 13 integrated modules, hardware hazard detection and forwarding, measured CPI 1.70 (10 instructions retired, 17 cycles, 1 stall plus 2 flush bubbles).
* **Full RTL-to-GDS run on the Sky130 PDK via LibreLane** — evaluated multiple clock constraints and floorplan strategies. Quantitatively showed that relaxing the clock period from 20ns to 35ns closes setup timing (+8.90 ns WNS) while electrical violations persist, and integrating a Sky130 1KB SRAM macro cut max fanout, slew, and cap violations by 87–97% (referencing [librelane/README.md](librelane/README.md) for DRC and antenna details).
* **Independent Python tooling** — `parse_timing.py` for comparing JSON metric files across runs and `parse_path_details.py` for parsing per-path text timing reports.

## What's here

### `rtl_projects/safety_monitor/` — Safety Monitor FSM
First original RTL project. A 4-state Moore FSM for an IoT multi-gas detection system, with a 10-cycle fault-integration counter and a non-recoverable lockout state. Self-checking SystemVerilog testbench, 12 scenarios covering synchronous glitch filtering, zero errors.

### `rtl_projects/riscv_pipeline/` — RISC-V RV32I subset Pipeline
A classic 5-stage pipeline (fetch → decode → execute → memory → writeback) with hazard detection and forwarding. A single stress-test program exercises EX/MEM forwarding, MEM/WB forwarding, store-data forwarding, a load-use stall, a taken-branch flush, and a not-taken branch in sequence — passes clean. 18-testbench regression suite, full hazard-scenario checklist, and measured performance numbers in the project README.

### `librelane/` — Physical Design (RTL-to-GDS)
The RISC-V pipeline taken through the full LibreLane flow on the Sky130 130nm PDK: synthesis, floorplanning, placement, clock tree synthesis, routing, and static timing analysis. Evaluated under multiple configurations: baseline runs at 20ns and 35ns, macro integration runs at 20ns and 35ns with an absolute floorplan, and a 20ns run with a relative floorplan. Includes the integration of a physical Sky130 SRAM macro, documented with remaining routing caveats and Magic DRC errors in [librelane/README.md](librelane/README.md).

### `hdlbits/`
Solutions to 100+ HDLBits problems, spanning Verilog language basics through finite state machines — the foundational reps behind everything else in this repo.

### `scripts/`
* `parse_timing.py` — a JSON comparator for evaluating performance and area metrics across physical design runs.
* `parse_path_details.py` — a regex-based parser for raw text timing reports (`.rpt`).

## Tech stack
SystemVerilog · Icarus Verilog / EDA Playground / GTKWave · LibreLane (FOSSi Foundation) · Sky130 PDK · Python · WSL2 / Nix

## Future work
* **Custom MAC accelerator instruction** — extending the RISC-V ISA with a multiply-accumulate instruction, to explore hardware acceleration at the ISA boundary.
* **FPGA implementation report (optional)** — synthesis and resource-utilization numbers via a free-tool FPGA flow, as a secondary data point alongside the ASIC flow above.

---
**About**
Built by Chidindu Henry Udeji. Individual project READMEs contain full technical detail, verification methodology, and results.