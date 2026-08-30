# RISC-V Pipeline: RTL-to-GDS Physical Implementation

## Overview

This directory documents taking the [RISC-V pipelined processor](../rtl_projects/riscv_pipeline/) through a complete RTL-to-GDS physical design flow using **LibreLane** (the actively-maintained successor to OpenLane 2) on the open-source **Sky130 PDK**. The design was run at two clock constraints deliberately, to produce a real comparison rather than a single pass/fail result.

A smaller design (the [Safety Monitor FSM](../rtl_projects/safety_monitor/)) was run through the same flow first, as a toolchain validation step — confirming the install and flow mechanics worked before risking the main portfolio design on it.

## Toolchain

- **LibreLane** — RTL-to-GDS flow (synthesis → floorplan → placement → CTS → routing → signoff), installed via Nix
- **Sky130 PDK** — SkyWater/Google's open-source 130nm process, fetched automatically via Volare on first run
- **OpenROAD, Yosys, Magic, KLayout, netgen** — invoked internally by the flow for placement/routing, synthesis, layout, and LVS respectively

## Run 1 — Safety Monitor FSM (Toolchain Validation)

Small, already-verified design, run first to confirm the flow itself worked correctly.

| Metric | Value |
|---|---|
| Instance area | 1,745.42 µm² |
| Die area | 3,512.12 µm² |
| Utilization | 37.6% |
| Worst setup slack | +12.99 ns (comfortable margin at 20ns/50MHz) |
| Result | 80/80 stages, zero errors |

## Run 2 — RISC-V Core: Two Clock Constraints

### Configuration

```json
{
  "DESIGN_NAME": "riscv_core",
  "VERILOG_FILES": "dir::*.sv",
  "CLOCK_PERIOD": 20,
  "CLOCK_PORT": "clk"
}
```

Run at `CLOCK_PERIOD` 20ns and, separately, 35ns, under run tags `RUN_2026-08-27_03-50-42` and `riscv_relaxed`.

### Results Summary

| Metric | 20ns (50MHz) | 35ns (28.6MHz) |
|---|---|---|
| Worst setup slack (WNS) | **−4.7874 ns — FAILED** | **+8.9032 ns — PASSED** |
| Max slew violations | 16,712 | 16,777 |
| Max cap violations | 110 | 108 |
| Max fanout violations | 446 | 448 |
| Die area | 762,310 µm² | 762,310 µm² |
| Utilization | 74.21% | 74.21% |
| DRC / LVS / Antenna | DRC passed | All three passed |

Both runs completed all 80 flow stages with zero flow errors. Die area and utilization are identical between runs, as expected — only the timing constraint changed, not the netlist.

### Root Cause: Why the 20ns Run Failed

Both memories in the design are declared as:
```systemverilog
logic [31:0] mem [0:255];
```
256 words × 32 bits = 8,192 bits per memory, implemented as ordinary flip-flops rather than a dedicated SRAM macro (none was targeted in this flow). Yosys synthesized each 32-bit memory as four 8-bit byte-lanes, each requiring one control signal to reach all 256 flip-flops in that lane: 256 × 8 = **2,048** — matching the four large-fanout nets flagged by the flow (`_09020_`, `_09026_`, `_09029_`, `_09033_`), corresponding to the two memories' two control signals each.

A driver gate straining to drive 2,048 downstream loads produces a physically slow voltage transition (a **slew violation**) and excessive load capacitance (a **cap violation**) — independent of clock speed. At the worst-case PVT corner (`max_ss_100C_1v60` — slow silicon, 100°C, 1.60V), this physical strain pushed the critical path past the 20ns budget, producing the setup timing failure.

### The Real Finding: Relaxing the Clock Fixed Timing, Not the Underlying Problem

Comparing the two runs directly separates two categories of result that are easy to conflate:

- **Setup timing (WNS)** measures whether a signal arrives before the clock edge that samples it — a *time-budget* question. Relaxing the clock from 20→35ns gave every path more time to arrive, which is why WNS flipped from failing to passing.
- **Slew and capacitance violations** measure whether a driving gate is electrically strong enough for its physical load — independent of how much time is available. These counts stayed within noise across the two runs (16,712→16,777 slew, 110→108 cap, 446→448 fanout) despite a 75% increase in clock period and a ~13.7ns swing in WNS.

**Relaxing the clock period closes setup timing but does not, and structurally cannot, resolve the underlying signal-integrity violations, since those stem from physical fanout loading rather than available time.** Fixing them would require reducing the actual load on the driving gates — real SRAM macros in place of flip-flop-based memory, buffer insertion, or fanout splitting — independent of clock speed entirely.

### Clock Tree Delay Breakdown (Verified)

Worst path in the 20ns run: `_37941_` → `_37919_`, at corner `max_ss_100C_1v60`.

| Segment | Delay |
|---|---|
| Pad entry | 0.783 ns |
| `clkbuf_0_clk` (size 16) | 0.799 ns |
| `clkbuf_2_3_0_clk` (size 8) | 0.850 ns |
| `clkbuf_6_55_0_clk` (size 8) | 0.555 ns |
| *Cell delay subtotal* | *2.987 ns* |
| `clknet_0` | 0.036 ns |
| `clknet_2_3_0` | 0.052 ns |
| `clknet_6_55_0` | 0.003 ns |
| *Net delay subtotal* | *0.091 ns* |
| **Total to 4th buffer's input pin** | **3.078 ns ≈ 3.079 ns reported** |

Nearly 3ns of the worst path is spent purely distributing the clock — a direct consequence of the same dense, unmacroed memory grid discussed above: greater physical congestion means longer wires, which means more clock tree delay to reach every flip-flop.

## Repository Structure

```
librelane/runs/
├── riscv_20ns/          # Failing run — signoff artifacts trimmed to portfolio-relevant files
│   ├── metrics.json / metrics.csv
│   ├── render/riscv_core.png
│   ├── sdc/, lef/, lib/, json_h/, vh/
│   └── (no GDS — see note below)
└── riscv_35ns/           # Passing run
    ├── metrics.json / metrics.csv
    ├── gds/riscv_core.gds   # Full physical layout
    ├── render/riscv_core.png
    └── sdc/, lef/, lib/, json_h/, vh/
```

Each run originally produced ~700MB of signoff data (`.sdf`, `.spef`, `.odb`, `.mag`, redundant GDS copies from three different tools). This was trimmed to the files that actually matter for review — metrics, constraints, physical abstracts, and one canonical GDS — rather than committing multi-corner timing/parasitic data nobody would open on GitHub. GDS was kept only for the 35ns (passing) run, since it's the stronger "here's a working chip" artifact; the 20ns run's story lives in its metrics and the analysis above.

## How to Reproduce

```bash
git clone https://github.com/librelane/librelane/ ~/librelane
nix-shell ~/librelane/shell.nix
librelane ~/my_designs/riscv_core/config.json
```

`scripts/parse_timing.py` extends the earlier single-report parser (written for the Python gate condition) to accept two run directories and print a side-by-side comparison table with automated sanity checks (die area and utilization should remain constant across a pure constraint change):

```bash
python3 scripts/parse_timing.py librelane/runs/riscv_20ns openlane/runs/riscv_35ns
```

## Future Work

Mapping both memories to real Sky130 SRAM macros (instead of flip-flop arrays) would directly address the fanout root cause identified above — this was deliberately not attempted here, since it requires macro blackboxing and LEF/GDS integration beyond this run's scope, and risked the project timeline for a result that isn't required to demonstrate the core RTL-to-GDS competency this run set out to show.

## Portfolio Statement

*Ran the RISC-V pipeline through the full LibreLane RTL-to-GDS flow on the Sky130 PDK at two clock constraints, diagnosed a hard timing failure to its physical root cause — flip-flop-based memory arrays driving 2,048-terminal fanout nets — and demonstrated quantitatively that relaxing the clock period closes setup timing without resolving the underlying signal-integrity violations, which remain unaffected by clock speed.*
