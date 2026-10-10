# Sky130 ASIC Flow — RISC-V Core & Safety Monitor

This directory documents taking the [RISC-V pipelined processor](../rtl_projects/riscv_pipeline/) through an RTL-to-GDS physical design flow using **LibreLane** on the open-source **Sky130 PDK**.

A smaller design (the [Safety Monitor FSM](../rtl_projects/safety_monitor/)) was run through the same flow first, as a toolchain validation step. *(Run executed locally; metrics not committed).*

## Toolchain

* **LibreLane** — RTL-to-GDS flow (synthesis → floorplan → placement → CTS → routing → signoff), installed via Nix
* **Sky130 PDK** — SkyWater/Google's open-source 130nm process, fetched automatically via Volare
* **OpenROAD, Yosys, Magic, KLayout, netgen** — invoked internally by the flow for placement/routing, synthesis, layout, and LVS

## Run 1 — Safety Monitor FSM (Toolchain Validation)

| Metric            | Value                                        |
| ----------------- | -------------------------------------------- |
| Instance area     | 1,745.42 µm²                                 |
| Die area          | 3,512.12 µm²                                 |
| Utilization       | 37.6%                                        |
| Worst setup slack | +12.99 ns (comfortable margin at 20ns/50MHz) |
| Result            | 80/80 stages, zero errors                    |

## Run 2 — RISC-V Core: Baseline vs. SRAM Macro Integration

The 5-stage RV32I core was evaluated under multiple constraints and physical architectures.

**RTL Identity & Simulation Note:**

* **RTL Baseline:** 17 of the module files match `main` at commit `8f67a7e`. The top-level file used for baseline physical design is `riscv_core_baseline.sv`, which differs only by adding a `probe_out` port.
* **Macro Sourcing:** The SRAM Macro runs utilize a modified RTL branch featuring an `observe_out` port, synchronous-read memory, and an `EX/MEM` pipeline register bypass to accommodate the native 1-cycle access latency of the Sky130 SRAM macro. `SKY130_SRAM_PATH` must point directly to the simulation `.v` file (not the directory). The SRAM macros were obtained from the open-source `sky130_sram_macros` repository.
* Passing the 18-test regression suite requires the vendor macro simulation model (`sky130_sram_1kbyte_1rw1r_32x256_8`). A skipped macro simulation will fail the runner.

### Results Summary

| **Metric**                          | **20ns RTL Baseline** | **20ns with SRAM Macro (Relative Floorplan)** | **20ns with SRAM Macro (Absolute Floorplan)** | **35ns RTL Baseline** | **35ns with SRAM Macro (Absolute Floorplan)** |
| ----------------------------------- | :-------------------: | :-------------------------------------------: | :-------------------------------------------: | :-------------------: | :-------------------------------------------: |
| **Setup WNS (ns)**                  |  −4.79 (**FAILED**)   |              −4.62 (**FAILED**)               |              −3.36 (**FAILED**)               |  +8.90 (**PASSED**)   |              +8.15 (**PASSED**)               |
| **Max Slew Violations**             |        16,712         |                     1,940                     |                     2,138                     |        16,777         |                     2,217                     |
| **Max Cap Violations**              |          110          |                      15                       |                      41                       |          108          |                      39                       |
| **Max Fanout Violations**           |          446          |                      56                       |                      16                       |          448          |                      15                       |
| **Instance Area (std cells+macro)** |     ~543,000 µm²      |                 ~253,000 µm²                  |                 ~284,000 µm²                  |     ~543,000 µm²      |                 ~284,000 µm²                  |
| **Die Area (µm²)**                  |        762,310        |                    541,770                    |          2,250,000 (Fixed 1500x1500)          |        762,310        |          2,250,000 (Fixed 1500x1500)          |
| **Utilization**                     |        74.21%         |                    48.98%                     |                    12.92%                     |        74.21%         |                    12.93%                     |
| **Magic DRC Errors**                |           0           |                   2,832,616                   |                   2,832,616                   |           0           |                   2,832,616                   |
| **LVS / Antenna**                   |    Clean / 0 nets     |                Clean / 0 nets                 |                Clean / 0 nets                 |    Clean / 0 nets     |                Clean / 2 nets                 |

### Key Technical Findings

1. **Fanout vs. Setup Causality:**
   Initial physical synthesis revealed severe physical signal-integrity violations (slew, cap, and fanout) consistent with synthesizing the memory into standard flip-flop arrays. Integrating the Sky130 1KB SRAM macro was consistent with dropping max fanout violations. The relative-area run demonstrates this: while it shrank the die by 28.9% and reduced max slew violations by 88% compared to the baseline, the 20ns setup timing still failed (−4.62ns WNS). This demonstrates that eliminating the heavy memory fanout loading was not sufficient to close setup timing at 50MHz.

2. **Magic DRC Analysis on Macro Runs:**
   The RTL baselines are perfectly DRC clean. Conversely, Magic reports 2,832,616 DRC errors on the SRAM macro runs (the top rules being `diff/tap.9` and `li.1`). Spatial bounding-box analysis confirms that all markers fall strictly within the vendor-provided SRAM macro's layout box (X: 150-629.78, Y: 150-547.5). While the core routing logic contains no markers outside the macro box, the runs themselves are not DRC-clean as built.

## Repository Structure

```text
librelane/runs/
├── riscv_20ns/                  # RTL baseline
├── riscv_35ns/                  # RTL baseline (Canonical GDS)
├── riscv_macro_20ns/            # Macro integration (Absolute floorplan)
├── riscv_macro_35ns/            # Macro integration (Absolute floorplan)
└── riscv_macro_relative_area/   # Macro integration (Relative floorplan)
```

*(Run artifacts are trimmed to metrics and constraints to preserve repository size. Only the riscv_35ns baseline retains its canonical GDS).*

## How to Reproduce

The macro simulation requires the OpenRAM-generated SRAM macros from the open-source sky130_sram_macros repository. It should be located at `<repo root>/sky130_sram_macros/` or linked via the `SKY130_SRAM_PATH` environment variable.

**Macro File Hashes (SHA256):**

* `.v`: `ecc3992c8232353517feeb4dedaa5bbae752216e7edc6d4f9f24cbb797316344`
* `.lef`: `f5389fa908c5876ef034c487b4363e755b3e13bf88ba924815c6fcea17965b92`
* `.gds`: `d342f811d3822b39e95c496739f511276146356ec00d2052ea663550cd293c1d`

```bash
# Parse timing and PPA metrics
python3 scripts/parse_timing.py librelane/runs/riscv_35ns librelane/runs/riscv_macro_35ns
```

## Baseline Configs

> **Note:** These configurations are recorded for reference and are not directly runnable. The macro configurations use absolute paths tied to the original build environment, and the RTL configurations use `dir::*.sv` which resolves only to the baseline SV file in this directory.

## Portfolio Statement

Ran the RISC-V pipeline through the LibreLane RTL-to-GDS flow on the Sky130 PDK. Identified severe slew and fanout violations caused by standard-cell memory arrays, integrated a Sky130 SRAM macro to reduce max fanout violations by 96% to 97% (using an absolute floorplan), and documented the Performance and Area impacts across multiple clock constraints—demonstrating that reducing physical routing strain was insufficient to close the 50MHz setup timing budget.