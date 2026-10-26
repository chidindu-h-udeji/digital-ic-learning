# Design notes

Detail behind the README: how the paper was read, every modelling choice, and how each check works. All RTL and testbenches were written with AI assistance (see [../README.md](../README.md)).

## Sources

- Paper: Hildebrand & Dubach, *Sirop: A Small IR for HLS with Parallel Patterns*, LCTES '26, [doi:10.1145/3814943.3816175](https://doi.org/10.1145/3814943.3816175). CC BY 4.0 ([licence](https://creativecommons.org/licenses/by/4.0/)).
- Artifact: [doi:10.5281/zenodo.20090976](https://doi.org/10.5281/zenodo.20090976), record version LCTES-2026-AEC-submission (compiler 1.2.0-2d9abb64, loaded from the record's `docker-image.tar`, image ID 3cb9ed42edf5). CC BY 4.0. Used only for the comparison with the authors' compiler. A newer record version (LCTES-2026-AEC-revision, doi:10.5281/zenodo.20297546) exists; Zenodo lists a different checksum for its outer `paper61.zip`, and I did not download it. The Docker Hub image `louishildebrand/sirop-lctes26-artifact:latest` (pulled Oct 26, 2026) reports compiler `1.2.0-e1a9c2fd`, a different build from the submission's `1.2.0-2d9abb64`, yet generates a `dot` design and testbench with no differences from the ones used here (6 files; IDs, full digest, version strings and `diff -rq` results in `tests/hub_image_diff.txt`). The two builds agree on this program; I have not checked anything beyond it, or shown that this image is the revision's.

## How Algorithm 1 maps to RTL

Each `sbuild` is one module with the same skeleton (`[A1:n]` = Algorithm 1, line n):

- `send = out_valid & out_ready` [A1:3]
- `arpv` = AND over producers of `(!ready_expr || valid)` [A1:4-6]
- `can_step = arpv & (send | ~out_valid)` [A1:7]
- Output data and valid registers update on `can_step | send`; valid loads `valid_expr & arpv` [A1:9-14].
- Accumulators update on `can_step` only [A1:16-18].
- Producer ready is `ready_expr & can_step` [A1:21-22]; each consumer's ready drives its producer [A1:23].

Choices the paper leaves open:

- Synchronous, active-high reset clears the valid registers and accumulators. Data registers have no reset (Algorithm 1: data `init = None`).
- Ready is combinational from the sink back to the inputs, as Algorithm 1 implies. There are no skid buffers.

## Modules

| File | Implements |
|---|---|
| `sb_zip.sv` | StmZip, Fig. 10 lowering |
| `sb_map.sv` | StmMap stage of Fig. 7 |
| `sb_reduce.sv` | StmReduce stage of Fig. 7 |
| `dot_unfused.sv` | Fig. 7 dot product as the three-stage pipeline of Fig. 8 |
| `sb_zipmap.sv` | zip and map fused by the Fig. 13 rule |
| `dot_fused.sv` | Fig. 14, right: zipmap, then reduce |
| `sb_rowsum11.sv` | Expression (1) as first lowered, Fig. 11 |
| `sb_rowsum12.sv` | The same after simplification, Fig. 12 |
| `sb_concat.sv` | StmConcat, Fig. 10 lowering |
| `letstm2.sv` | letstm buffer with two consumers (Secs. 3-4) |
| `letstm_concat.sv` | `letstm[K] x = s in StmConcat(x, x)` (Sec. 3) |

## Modelling decisions

1. **Reduce follows Fig. 7** (`sum` starts at 0, no `first` flag), not Fig. 10. The compiler's output for `dot` mixes the two (see the README); both give the same results.
2. **Widths.** Data is u16 throughout (`W = 16`). The Fig. 7 counter `i` is u16 in `sb_reduce`; the row-sum `i` is u4 (Figs. 11-12); the concat counter has ⌈log2(n+1)⌉ bits (Fig. 10).
3. **Arithmetic wraps mod 2^16.** Map keeps the low 16 bits of the 32-bit product, and sums use 16-bit adders. This matches the compiler's `*%` and `+%` (`truncate(I0 * I1, 16)` in the generated VHDL). `golden.py` rejects overflow, so no test depends on wrapping.
4. **One result per reset.** `sb_reduce` never clears `i`, matching a length-1 output stream. Testbenches reset between dot products.
5. **Fig. 12** writes `sdata(s)` where the producer is named `p`; read here as `sdata(p)`.
6. **Fig. 11's RESET condition** is implemented as printed, with `LAST = R - 1` in place of the literal 2.
7. **`letstm2`** is a circular buffer written from the description in Secs. 3-4: one read pointer per consumer, and a new element is accepted only if no consumer is K elements behind. It is not the authors' VHDL entity.

## Fusion worked through manually (Fig. 13)

- Producer zip: `d_p = (sdata(p0), sdata(p1))`, `v_p = true`, no accumulators, producers `p0`, `p1` with `ready: true`.
- Consumer map: `d_c = sdata(x).0 * sdata(x).1`, `v_c = true`, no accumulators, one producer `x` with `r_c = true`.

Applying the rule:

- `d_f = [d_p/sdata(x)] d_c = (sdata(p0), sdata(p1)).0 * (sdata(p0), sdata(p1)).1`, which tuple projection (partial evaluation, Sec. 6.1) reduces to `sdata(p0) * sdata(p1)`.
- `v_f = ([d_p/sdata(x)] v_c) ∧ (r_c ⇒ v_p) = true ∧ (true ⇒ true) = true`.
- Accumulators: none on either side.
- Producers `p0`, `p1`: `ready = if (v_p ⇒ r_c) then true else false = true`.

Result: `sbuild(4)(sdata(p0) * sdata(p1), true) {} {p0: ready true, p1: ready true}`, implemented in `sb_zipmap.sv`. The generated `sbuild_1.vhd` for `dot` has the same expression with `*%`. Both guards are constant true for this pair, so this fusion does not exercise the guard parts of the rule.

Cost model (Sec. 6.3), assuming a leaf cost of 0 (the paper does not give one): zip + map costs 0 + 100 = 100, within the limit of 100, so it is fused. Map + reduce would cost 33 + 100 = 133, so it is not.

## Expected values and where they come from

- **Results:** 70, with products 5, 12, 21, 32 and running sums 5, 17, 38 (Fig. 7); 6, 36, 66 (Fig. 11). `golden.py` recomputes the results and generates all random cases.
- **Latency** (hand trace of Algorithm 1, no stalls): 6 unfused and 5 fused at N = 4; N + 2 and N + 1 in general. A one-tick input gap adds one cycle.
- **Back-pressure:** while `out_valid = 1` and `out_ready = 0`, `send = can_step = 0`, so no register changes.
- **letstm:** derived from the buffer rule above. `StmConcat(x, x)` stalls once the buffer holds K elements the second consumer has not read, so it should stop after K outputs for K < n and complete for K ≥ n.
- **Hand-counted flip-flops:** dot unfused 99 (zip 33, map 17, reduce 49), fused 66; row sum Fig. 11 102, Fig. 12 38.
- **Fig. 11 ≡ Fig. 12 (induction).** Invariant: `in_cnt == i` and `out_cnt == 0`. It holds after reset. All accumulators update on the same condition (`can_step`). Assuming the invariant, the first RESET disjunct (`... out_cnt == 1`) is false, and the second (`in_cnt == 2 && out_cnt == 0 && i == 2`) equals `i == 2`, so RESET is exactly Fig. 12's condition `i == 2`. Then `i` and `in_cnt` both reset or both increment, so they stay equal, and `out_cnt` is reset when `i == 2` and otherwise keeps its value 0. So the invariant is preserved, and `sum`, `first`, `i`, data and valid follow the same expressions as in Fig. 12 on every step.

## Testbenches

- Stimulus changes on the falling edge and the monitor samples on the rising edge, to avoid races.
- **Latency:** the edge accepting the first input pair is edge 1; L is the edge after which `out_valid` first reads 1. The authors' generated testbench counts rising edges from the start of the test, offers the first value on each input at the first falling edge (so it is accepted on edge 1), and reads the count at the first falling edge with `valid = 1`. The two definitions agree.
- **Random tests:** sources hold valid until accepted, as an `sbuild` producer does. `$random` seeds are fixed (1 for dot, 2 for row sum, 3 for the row-wise test).
- **`tb_dot`** also checks each product handed to reduce and reduce's sum just before each addition (0, 5, 17, 38), against Fig. 7.
- **`tb_stream`** runs zip, map and the Fig. 12 row sum (or zipmap and the row sum) on rows of 3. The row sum emits every 3 inputs, so with a random sink its output fills mid-stream and the upstream stages must stall. A `stall_check` instance on each link counts stalls and checks that data and valid do not change during them.
- **`tb_rowsum`** compares Fig. 11 and Fig. 12 on every edge, and reads `in_cnt`, `i` and `out_cnt` from inside the Fig. 11 instance.
- **Break-it and mutants.** `sed` edits one line of a copy of one module, and a testbench must fail: `can_step = arpv` in zip, map or zipmap; accumulators updating on `can_step | send`; output registers updating on `can_step` only; a producer ready without `& can_step`. Results are in `tests/mutants.txt`, survivors included.
- **`tb_letstm`** keeps the sink always ready, so `sb_concat` and `letstm2` are not tested under back-pressure.

## Comparison with the authors' compiler

- Generated with `./docker_run.py 'python3 -u ./sirop_generate.py dot'`, using the artifact's stored `dot.sirop` (N = 840).
- Simulated with GHDL 4.1, `--std=08`; the authors' script uses `vcom -2002`.
- **Generated testbench** (`test/test_top.vhd`). Each input process (I0 from line 78, I1 from line 4292) waits for the test to start, offers a value at the next falling edge (first offers at lines 86 and 4300), and offers the next value as soon as it is accepted. The output `ready` is `'Z'` until the result is valid (line 8513), then `'1'` (line 8520), then `'Z'` again (line 8531). A low `ready` cannot stall `dot` before the end: `can_update_acc` (`sbuild_2.vhd`, line 73) is `(not valid_internal or sl2bool(ready)) and all_required_producers_valid`, and reduce's `valid_internal` is false until the last input.
- **Ready path in the generated VHDL.** Every step is a concurrent assignment, so ready passes combinationally from the top-level `ready` to `I0_ready`. In `top.vhd`: line 87 `s_76_ready <= ready`; line 79 `sbuild_2`'s `ready` input is `s_76_ready`; line 82 `sbuild_2`'s `s_75_ready` output drives the signal `s_75_ready`; line 72 that signal is `sbuild_1`'s `ready` input. Inside the stages:

  ```vhdl
  s_75_ready_internal <= (true) and (not valid_internal or sl2bool(ready)) and arpv_except_s_75;  -- sbuild_2.vhd
  I0_ready_internal <= (true) and (not valid_internal or sl2bool(ready)) and arpv_except_I0;   -- sbuild_1.vhd
  arpv_except_I0 <= (not (true) or (I1_valid_internal));                                      -- sbuild_1.vhd
  ```

- **Why `arpv_except` changes no transfer in `dot`.** Algorithm 1 gives `I0_ready = ready_expr ∧ arpv ∧ (¬valid ∨ ready)` with `arpv = I0_valid ∧ I1_valid`. The generated version drops `I0_valid` from that product. A transfer on I0 needs `I0_valid ∧ I0_ready`; with `I0_valid = 1` the two expressions are equal, and with `I0_valid = 0` there is no transfer either way. When `ready_expr` is false, both readies are 0.
- **`first_step` test.** A copy of the generated design with one line of `sbuild_2.vhd` changed (`tests/first_step_removed.diff`): `ite_83`, the next value of `acc_82`, becomes `acc_82 + sdata` instead of `if first_step_79 then sdata else acc_82 + sdata`. It runs with the authors' unchanged testbench. In `sbuild_2.vhd`, `first_step_79` appears only at its declaration (line 58), its one use in `ite_83` (line 76), its reset to true (line 103) and its update to false (line 105). `acc_82` is declared with initial value 0 (line 57), resets to 0 (line 98) and updates only on `can_update_acc` (lines 99-100), the same condition as `first_step_79`. So `acc_82 = 0` whenever `first_step_79` is true, and, because 0 is the identity of `+`, the if/else always equals `acc_82 + sdata`.
- **Negative control.** The same copy with `ite_83` set to `acc_82 + sdata + 1` is reported by the authors' testbench as `Wrong data at t = 841` (`tests/first_step_negative_control.txt`), so the testbench does check the value.

## Yosys

Yosys 0.33, `synth -top <top> -nofsm -flatten -lut 6`, with each design reading only its own files. Flip-flop counts are exact and match the hand counts. LUT counts depend on Yosys's input: reading every file in `rtl/` gives 303 LUTs for `dot_unfused` and 295 for `dot_fused`, against 289 and 293 when each reads only its own files, with flip-flops unchanged. `run_tests.sh` prints both. LUT differences of a few percent are therefore not meaningful here.