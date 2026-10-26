# sirop-repro: Sirop's sbuild hardware and stream fusion in RTL, checked against the authors' compiler

*Built with AI assistance; see [../README.md](../README.md).*

A learning exercise on *Sirop: A Small IR for HLS with Parallel Patterns* (Hildebrand & Dubach, [LCTES '26](https://doi.org/10.1145/3814943.3816175)). The paper's dot-product example was written in RTL with AI assistance, following Algorithm 1 rather than using the Sirop compiler, and the Fig. 13 fusion rule was applied manually, with AI assistance ([DESIGN.md](DESIGN.md)). The results were compared with what the authors' compiler generates for the same program. The Sec. 6.2 row-sum simplification and the Sec. 3 `letstm` example were also tested in RTL.

**What I found.** The fused RTL design and the compiler's generated design have the same structure (zip and map fused into one `sbuild`, then reduce) and the same latency, 841 cycles at N = 840. The Sec. 6.2 simplification and the `letstm` claim reproduce in RTL. In the generated reduce for `dot` (a sum), the `first_step` flag appears redundant: the accumulator already starts at 0, the identity of `+`, so the flag never changes the result. With its only use replaced, the design still passes the authors' own testbench, which does reject a deliberately wrong variant. Fig. 10's general lowering starts the accumulator at `_`, where the flag is needed, so this looks like a missed simplification for reduce functions whose identity is the initial value, not an error. The paper's ALM, BRAM and DSP results need Quartus Prime Pro and were not reproduced.

## Implementation and attribution

- **Authors'** (paper and artifact, CC BY 4.0, [licence](https://creativecommons.org/licenses/by/4.0/)): the paper, the Zenodo artifact and the VHDL its compiler generates. None is included, except 7 lines of the generated `sbuild_2.vhd` (Hildebrand & Dubach, [doi:10.5281/zenodo.20090976](https://doi.org/10.5281/zenodo.20090976)), one of them changed, in `tests/first_step_removed.diff`, and a few lines quoted with line numbers in `DESIGN.md`.
- **Written with AI assistance** (see [../README.md](../README.md)): `rtl/`, `tb/`, `golden.py` (reference model and test vectors), `run_tests.sh`, and [`DESIGN.md`](DESIGN.md) (modelling decisions, the fusion derivation, how each check works).
- **`tests/`:** the break-it log, the mutant results, the `first_step` diff, log and negative control, and the Docker Hub image comparison.

## Setup

| Item | Setting |
|---|---|
| Machine | WSL2, Ubuntu 24.04 |
| Simulation | Icarus Verilog 12.0 (RTL); GHDL 4.1.0, `--std=08` (generated VHDL) |
| Synthesis | Yosys 0.33 (git sha1 2584903a060), `synth -nofsm -flatten -lut 6` |
| Python | 3.14.7 |
| Artifact | [doi:10.5281/zenodo.20090976](https://doi.org/10.5281/zenodo.20090976), record version LCTES-2026-AEC-submission; compiler 1.2.0-2d9abb64 from the record's `docker-image.tar` (image ID 3cb9ed42edf5). A newer record version (LCTES-2026-AEC-revision) lists a different checksum and was not downloaded; the current Docker Hub image, a different build (compiler `1.2.0-e1a9c2fd`), generates an identical `dot` (`tests/hub_image_diff.txt`) |
| Paper's setting (reference only) | Quartus Prime 19.2 Pro, Arria 10 GX, 175 MHz |

## Results

| Claim | Where | Result | Status |
|---|---|---|---|
| Dot product of 1-4 and 5-8: products 5, 12, 21, 32, running sums 5, 17, 38, result 70 | Fig. 7 | All checked, unfused and fused, with and without stalls | Reproduced (RTL) |
| `sbuild` handshake | Algorithm 1 | Dot: 3 directed tests and 200 random cases (input gaps, random sink at the final output). Row-wise dot products: 100 rows with mid-stream back-pressure; every link held its data while stalled. Break-it caught; 7 of 9 mutant runs caught (`tests/mutants.txt`) | Implemented; tested as stated |
| Zip and map fuse into one `sbuild` | Figs. 13-14 | Same results on every test; latency 6 → 5 at N = 4; flip-flops 99 → 66; no LUT difference beyond Yosys's own spread | Consistent (RTL) |
| Compiler output for `dot` | Sec. 6.3 | Two `sbuild`s: `sdata(I0) *% sdata(I1)` (the expression obtained by applying the rule manually), then reduce. Map and reduce stay separate, as the cost model predicts (100 + 33 > 100, leaf cost 0 assumed) | Matches |
| Latency of the generated `dot` | Comparison; latency defined in Sec. 7.1 | 841 cycles at N = 840 in the authors' testbench and in mine (842 unfused); definitions checked to agree | Matches |
| Fig. 11's extra counters are redundant | Sec. 6.2 | Same outputs on every edge over 470 checks (100 rows, random stalls); `in_cnt == i` and `out_cnt == 0` throughout; flip-flops 102 → 38 (the two u32 counters account for 64), LUTs 170 → 60 | Reproduced (RTL; simulation plus an induction argument in `DESIGN.md`) |
| `letstm[1] x = s in StmConcat(x, x)` gets stuck; `letstm[n]` works | Sec. 3 | n = 4: stuck after K outputs for K = 1, 2, 3; complete for K = 4, 5. Checks the paper's deduction from its capacity rule, using a buffer written from the description, not the authors' hardware | Reproduced (RTL buffer) |
| Meaning of `*%` and `+%` | Appendix A, artifact | Wrap mod 2^16: `truncate(I0 * I1, 16)` in `sbuild_1`; the 16-bit unsigned add in `sbuild_2` | Determined from the artifact |
| ALM, BRAM, DSP results; comparison with Intel HLS, SHIR, Aetherling | Figs. 17-19 | Needs Quartus Prime Pro and Intel HLS | Not attempted |
| Compiler output for the row sum and `letstm` | | | Not attempted |

Flip-flop and LUT counts are Yosys counts, compared only with each other.

## Against the paper

- **Fig. 7 vs Fig. 10.** Fig. 7 shows the reduce with `sum` starting at 0 and no `first` flag. The compiler's output for `dot` keeps Fig. 10's `first_step` flag but also starts the accumulator at 0.
- **Ready is combinational end to end.** The paper registers each stage's data and valid "to avoid long combinational paths"; ready still passes combinationally from the sink to the inputs, in Algorithm 1 and in the generated VHDL (`DESIGN.md`). This is an observation, not a fault.
- **Generated ready uses `arpv_except`.** The VHDL computes each producer's ready from the other producers' valid signals, while Algorithm 1 uses all of them. Transfers happen on the same cycles in `dot` (`DESIGN.md`), so this is a harmless variation.

## Findings

- **`first_step` appears redundant in the generated reduce for `dot`.** The argument uses that 0 is the identity of `+`. Reset sets `acc = 0` and `first_step = true` together, and both update on the same condition, so `acc` is 0 whenever `first_step` is true and `if first_step then s else acc + s` always equals `acc + s`. With that one expression replaced by `acc + s` (`tests/first_step_removed.diff`), `first_step` drives nothing, and the design still passes the authors' unchanged testbench in 841 cycles; the same testbench reports `Wrong data` for a variant computing `acc + s + 1`. By inspection this would save one flip-flop and one 16-bit multiplexer; neither VHDL version was synthesized, so I do not know whether Quartus already removes them. None of the three Sec. 6.2 simplifications as described covers this case; the compiler may have other passes I did not read.
- **Sec. 6.2 in isolation vs across benchmarks.** On the row sum alone the simplification removes 64 of 102 flip-flops, and Yosys does not find it by itself. Sec. 7.2 reports little effect across the paper's benchmarks; the two measure different things, and I have not investigated the gap.

## Limitations

- Small scale: the dot product (N = 4 and 840), one row sum, one row-wise dot product, one `letstm` example.
- In the dot tests, reduce emits only after its last input, so zip and map never stall there; the row-wise test covers mid-stream stalls. Two mutant runs survive: M1a against the dot tests alone (caught by the row-wise test), and M2b (reduce accumulators also update on send), which I believe is equivalent for a one-result reduce, since nothing is read after the send; the same edit in the row sum (M2a) is caught.
- `sb_concat` and the `letstm` example were run only with an always-ready sink.
- Yosys is not Quartus, and LUT counts shift by a few percent with Yosys's input (`DESIGN.md`), so small LUT differences are not meaningful.
- The Fig. 11 = Fig. 12 induction argument is a hand proof, not a machine-checked one.
- The authors' testbench offers an input every cycle and keeps the sink's ready low until the result is valid, which cannot stall this design; it runs one `dot` case, so the `first_step` test does too. The argument covers all runs.
- The compiler was run only on the stored `dot` (N = 840) from the record version above, and checked on the Docker Hub build for `dot` only; the interpreter was not used.
- Generated VHDL was simulated with GHDL `--std=08`; the authors use ModelSim with `vcom -2002`.

## Reproducing

The RTL tests need Python 3, Icarus Verilog and Yosys:

```bash
./run_tests.sh
```

The artifact checks at the end also need GHDL and the generated `dot`. Download the artifact, unzip its inner `sirop-lctes26-artifact.zip` into `./artifact/`, then:

```bash
sudo docker load -i artifact/sirop-lctes26-artifact/docker-image.tar
cd artifact/sirop-lctes26-artifact/sirop/src/test/python
./docker_run.py 'python3 -u ./sirop_generate.py dot'
```

## Appendix: artifact notes

- **Sealed sources.** `docker_run.py` mounts only `src/test/vhdl`, `src/test/verilog` and `results`; the container compiles its own copy of `/sirop`, so host edits to `.sirop` files have no effect.
- **`dot.sirop`** uses `Stm[u16, 840]`, `*%`/`+%` and a tuple-argument reduce lambda (Fig. 4: length 4, `*`/`+`, two arguments).
- **Interpreter.** The Sec. 7.5 interpreter appears to be `mhir/eval/Evaluator.scala` (tracing in `mhir/debug/`), which the artifact README does not mention. `mhir/main/bf/Interpreter.scala` is a Brainfuck interpreter written as a Sirop program.
- **Generated testbench.** Expected values are computed by the tool (55800 for the stored `dot` inputs); it reports `LATENCY: <n> cycles` and asserts `Wrong data` on a mismatch.