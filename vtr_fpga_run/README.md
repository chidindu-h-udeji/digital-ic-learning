# FPGA Physical Design (VTR Flow)

This directory documents the Verilog-to-Routing (VTR) synthesis and routing flow for the 5-stage RISC-V core.

## Methodology & Design Caveats
* **Memory Mapping:** Because the Sky130 ASIC SRAM macros cannot be mapped onto an FPGA, this run uses the behavioral synchronous-read data memory from the `main` branch (commit `3cb4f903adfc1562b1d81e761eea5af3b471e4dc`). These FPGA metrics represent a different physical mapping than the ASIC runs and should not be used as a direct 1-to-1 comparison.
* **Literal Initialization:** In this VTR build, `$readmemh` contents were not loaded during synthesis, resulting in the entire design being swept as dead logic. The `run_fpga_flow.sh` script applies a literal-initialization workaround inside a temporary `/tmp` directory. A testbench gate runs the repo's directed 17-cycle program on the synthesis-input RTL. However, VPR's RAM blocks carry no initial contents, so the final routed netlist itself is not functionally verified. The metrics below describe the core's structural logic plus three RAM blocks, not a CPU executing a specific program.
* **Anti-Specialization Padding:** Synthesis tools aggressively fold logic if ROM columns are mathematically constant. An A/B test showed that the unmodified 11-instruction program (which leaves 14 ROM columns identically zero) yielded 612 LUTs at 124.49 MHz. Padding the unread end of the ROM with a `0xFFFFFFFF` dummy instruction stops this constant-column folding, resulting in the 914 LUTs at 103.18 MHz reported below.
* **Constraints:** No explicit SDC file was provided. VPR was run with its default "run as fast as possible" constraint.

## VTR Environment
* **Toolchain Hash:** `f3c7c118141257b7a916aa30f369deaf0c991738` (v9.0.0-candidate1-6662)
* **Architecture:** `EArch.xml` (VTR flagship timing architecture)
* **Execution:** Run from the repository root using flags: `-top riscv_core -parser slang --route_chan_width 300`

## Final Estimates
* **Fmax (VPR default constraint):** 103.18 MHz
* **Critical Path Delay:** 9.69 ns
* **Device Grid:** 14x14 (Auto-sized, 44% Utilization)
* **Fixed Channel Width:** 300
* **Resource Usage:**
  * **CLBs:** 64 (584 FLEs)
  * **LUT Primitives:** 914 (710 lut5 + 197 lut6 + 7 lut4)
  * **Flip-Flops:** 247
  * **Carry-Chain Adders:** 53
  * **Memory Blocks:** 3 (inferred: instruction ROM, data memory, register file mapping)
  * **I/O Pads:** 34
