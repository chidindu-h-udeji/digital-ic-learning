# RV32I 5-Stage Pipelined Processor

A pipelined RISC-V (RV32I subset) processor implemented in SystemVerilog, featuring hardware forwarding, load-use hazard detection, and control-hazard flushing. Built module-by-module with self-checking testbenches at every stage — 13 independently verified modules, 18-instruction subset, culminating in a full-pipeline test exercising every hazard type simultaneously.

## Architecture

Classic 5-stage in-order pipeline: **Fetch → Decode → Execute → Memory → Writeback**, with a pipeline register between each stage and a shared register file closing the loop from Writeback back to Decode.

![RV32I pipeline architecture](./diagrams/RV32I%20pipeline%20architecture.drawio.png)

**Reading the diagram:** The solid black lines trace the main datapath left-to-right, while the dashed blue line shows the write-back data looping back to the register file. The tall yellow bars represent the pipeline registers physically dividing the stages (IF/ID, ID/EX, EX/MEM, MEM/WB). Datapath computation and memory blocks are blue, while multiplexers are purple. The Hazard Detection Unit and Forwarding Unit (highlighted in red) operate outside the main datapath; they monitor pipeline states and assert control via the dashed red lines to inject stalls, bubbles, and forwarding mux selections.

**Key design decisions:**
- **Branch resolution happens entirely in Execute** — target address (`PC + immediate`, not `PC + 4`) and comparison both computed there, feeding back directly to `pc_logic`. Keeps the pipeline register field lists contained; no early-resolution optimization attempted.
- **The register file's own internal same-cycle write-then-read forwarding structurally resolves the write-back-to-decode hazard** — no dedicated forwarding hardware needed for that case. The forwarding unit's scope is therefore narrower than a textbook diagram might suggest: only **EX/MEM → EX** and **MEM/WB → EX** paths.
- **Instruction and data memory are separate**, avoiding the structural hazard a shared memory port would otherwise create between Fetch and Memory in the same cycle.
- **Reset is synchronous, active-high, project-wide** — a deliberate verification-practicality choice, not an RV32I spec requirement (the spec only mandates x0's zero-read behavior).

## Instruction Set Support

18 instructions across all four RV32I formats relevant to hazard demonstration:

| Type | Instructions |
|---|---|
| R-type | `add`, `sub`, `and`, `or`, `xor`, `slt`, `sll`, `srl`, `sra` |
| I-type ALU | `addi`, `andi`, `ori`, `xori`, `slti` |
| Load/Store | `lw`, `sw` |
| Branch | `beq`, `bne` |

`jal`/`jalr`/`lui`/`auipc` (U-type, J-type) are deliberately out of scope — not needed to demonstrate forwarding, stalling, or flushing, and excluded to keep the control unit and immediate generator's scope contained.

## Hazard Handling

| Hazard type | Mechanism | Where it's resolved |
|---|---|---|
| Structural | Separate instruction/data memory | Architectural, by design |
| Data (general) | Forwarding — EX/MEM and MEM/WB paths, EX/MEM prioritized when both match | Forwarding unit, muxes at ALU inputs |
| Data (write-back to decode) | Register file's internal same-cycle forwarding | Register file, structurally — no dedicated hardware |
| Data (load-use) | 1-cycle stall (forwarding alone can't resolve it — loaded data isn't ready in time) | Hazard detection unit → PC + IF/ID freeze, ID/EX bubble |
| Control (branch) | Flush IF/ID and ID/EX on taken branch, redirect PC | EX stage's `branch_taken`, ORed into `id_ex_reg.flush` alongside the stall bubble condition |

**Forwarding priority, and why the order matters:** EX/MEM is checked before MEM/WB. If both stages happen to hold results destined for the same register simultaneously, the EX/MEM value is more recent (it's from a later instruction in program order) — checking MEM/WB first would forward a stale value.

**x0 guard, applied everywhere a register-number comparison could produce a false positive:** the register file, hazard detection unit, and forwarding unit all explicitly exclude `rd_addr == 0` from triggering their respective logic. Necessary because `x0` appears constantly as an operand in ordinary code — without the guard, hazard/forwarding logic would trigger on every such instruction for no reason, a real (if non-corrupting) performance cost.

## Hazard-Scenario Checklist

Verified through a full-pipeline test program exercising every case in one sequence:

| Scenario | Status |
|---|---|
| EX/MEM forwarding (back-to-back dependent ALU instructions) | ✅ |
| MEM/WB forwarding (one independent instruction between producer and consumer) | ✅ |
| Store-data forwarding (forwarded value routed to `sw`, not just the ALU) | ✅ |
| Load-use hazard (exactly 1 stall cycle, then forward normally) | ✅ |
| Branch taken (flush, no wrong-path instruction executes) | ✅ |
| Branch not taken (no false flush, sequential execution continues) | ✅ |
| Structural hazard | N/A — architecturally impossible by design (split I/D memory) |

## Performance Metrics

*(From the full-pipeline stress test — exercises EX/MEM forwarding, MEM/WB forwarding, store-data forwarding, a load-use hazard, and a taken branch flush in one 10-instruction sequence)*

| Metric | Value |
|---|---|
| Instructions retired | 10 |
| Total active cycles | 16 |
| Stall cycles | 1 |
| Measured CPI | 1.60 |

**Context for the CPI figure:** ideal pipelined CPI is 1.0. The program fetches 11 instructions in total — the 10 that retire, plus one instruction fetched behind a taken branch before being flushed. A zero-hazard run of 11 back-to-back instructions through a 5-stage pipeline takes 15 cycles (11 instructions plus 4 cycles to fill the pipeline). The measured 16 cycles is exactly one cycle more, matching the single reported stall — the load-use hazard, the one case forwarding cannot resolve on its own. The branch flush contributes no additional cycles: the flushed instruction was already occupying a pipeline slot regardless of the branch outcome; flushing only prevents it from committing its effects. CPI is computed against the 10 retired instructions (16 / 10 = 1.60).

## Verification Approach

Every module — register file, each pipeline stage, each pipeline register, the hazard detection unit, and the forwarding unit — has an independent self-checking SystemVerilog testbench with hand-derived expected values (never inferred from what the RTL currently outputs), following the same testbench-integrity discipline throughout: **every claim a testbench makes must be independently provable**, not just plausible. Multiple real bugs were caught this way during development — among them, a load/store addressing bug in the ALU control decoder, an inconsistent reset style, and several instances of control signals or output fields that were present in the RTL but never actually exercised by their testbench.

## Project Structure

```text
riscv_pipeline/
├── core/                # Top-level core integration (riscv_core.sv) & stress testbench
├── decode_stage/        # ID wrapper, control unit, immediate generator
├── execute/             # EX stage (ALU, ALU control, branch comparator)
├── fetch_stage/         # PC logic, instruction memory, IF wrapper
├── forwarding_unit/     # EX/MEM and MEM/WB forwarding logic
├── hazard_unit/         # Load-use hazard detection
├── mem_stage/           # Data memory, MEM wrapper
├── pipeline_regs/       # IF/ID, ID/EX, EX/MEM, MEM/WB pipeline registers
├── register_file/       # Shared register file and testbench
├── wb_stage/            # Writeback stage wrapper
└── run_all_tests.sh     # Global 18-test regression suite runner
```

Each subdirectory contains its module(s), a self-checking testbench, and a sim_*.sh script to compile and run it independently. `run_all_tests.sh` at the repo root runs the full regression suite across all of them in pipeline order.

## How to Run

**Individual module tests:** from within any subdirectory, `./sim_<module>.sh`

**Full regression suite:** `./run_all_tests.sh` from the `riscv_pipeline` root — runs all module-level testbenches in pipeline order and reports pass/fail per module plus an aggregate summary.

**Full pipeline integration test:** `cd core && ./sim_core.sh`

## Portfolio Statement

*My RV32I pipeline implements a 5-stage in-order datapath with hardware forwarding (EX/MEM and MEM/WB paths, correctly prioritized), a dedicated load-use hazard detection unit, and control-hazard flushing — verified through per-module self-checking testbenches plus a full-pipeline integration test exercising every hazard type in a single 10-instruction sequence, achieving a measured CPI of 1.60 with only the architecturally unavoidable load-use stall contributing overhead.*