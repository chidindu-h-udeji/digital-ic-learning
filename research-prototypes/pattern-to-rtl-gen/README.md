# Flat vs. decomposed pattern matching: a learning exercise

*Built with AI assistance; see the [research-prototypes README](../README.md) for the project-wide disclosure.*

A learning exercise to understand Garg & Boutros's parser generator ([arXiv:2607.16058](https://arxiv.org/abs/2607.16058)). I wrote a small matcher generator and verified it by simulation, then ran the authors' open-source backend on synthetic patterns and compared flat and decomposed designs with Yosys (the Section VI experiment, at reduced scale). It tests the paper's flat-vs-decomposed claim at reduced scale with a different tool; it does not reproduce the paper's absolute numbers.

## Implementation and attribution

- **`gen_parser.py`:** My generator for the paper's Fig. 2 single-stage matcher, verified by simulation (`tests/`). It emits cascaded ternary operators instead of the paper's `if/else-if` `always_comb` block; both implement first-listed-wins priority (paper, Section III-A).
- **`make_synth.py`, `run_sweep.py`, `plot_results.py`:** My Python experiment harness for pattern generation, synthesis, data collection, and visualization.
- **`check_cfg.py`, `check_flat.py`:** Configuration and synthesis checks used to investigate discrepancies in the results.
- **RTL backend:** The authors' MIT-licensed backend, at commit `23c7c1a29008677637764c2bdf07ebcd505b0e42`, generates the flat and decomposed RTL.

## Setup

| Parameter | Setting |
|---|---|
| Pattern count and width | N = 256, 80 bits |
| Uniqueness (`u`) | 32, 64, 128, giving repetition factors of 8×, 4×, 2× |
| Structural groups (`ug`) | 1, 2, 3, 4 |
| Design configurations | Authors' `synthetic/one_group.json` and `synthetic/multi_group.json` |
| RTL generation flags | `--rtl --tree1 --tree2` |
| Synthesis | `synth -top <top> -nofsm -flatten -lut 6` |
| Synthesis tool | Yosys 0.33 (`yosys-abc` 0.33) |
| Simulation | Icarus Verilog 12.0 |
| Metrics | LUT and flip-flop (FF) counts; no timing measurements |
| Pattern seeds | 1, 2, 3 |
| Paper's setting (reference only) | N = 4096, `u` ∈ {256, 512, 1024}, Vivado 2025.2 on AMD Versal (xcvc1902) |

FSM extraction is disabled to keep the netlist comparison simple. The experiments use three distinct pattern seeds per configuration.

## Reproducing

The synthesis harness expects the authors' repository at `~/patterns-to-parsers`. `check_cfg.py` and `check_flat.py` reuse `sweep_work/u32_ug1_s1.pir`, so run `run_sweep.py` first. Pattern generation is not fully reproducible between runs (see Limitations), so a fresh sweep reproduces the counts to within about 0.5% per point, not exactly.

Run the sweep:

```bash
python3 run_sweep.py
```

The sweep writes `results_seeded.csv` and resumes previously completed configurations.

Generate the table and chart:

```bash
python3 plot_results.py
```

Simulation evidence for `gen_parser.py`, including successful tests, a deliberately introduced failure, and overlapping-pattern priority, is documented in [`tests/README.md`](tests/README.md).

## Results

The table reports mean LUT counts across three pattern seeds. The ratio is **Flat LUTs / Decomposed LUTs**; values above 1 favour the decomposed design.

**Data provenance:** All 72 rows in `results_seeded.csv` were produced by the committed `run_sweep.py`, in two runs: the decomposed rows first, then the flat rows. An earlier sweep used `col_per_file=1` for the decomposed design and extra `data_width`/`max_width` keys; it is kept as `results_seeded_colperfile1.csv`. Re-running the 36 flat points with the committed harness changed individual flat counts by at most 13 LUTs (0.5%) and the table's flat means by at most 5 LUTs, and no ratio changed at two decimals. The earlier flat rows are kept in `results_seeded_before_flat_rerun.csv`. Because the two halves came from separate runs, the flat and decomposed rows for a given seed use slightly different pattern sets (see Limitations).

| Repetition | Uniqueness (`u`) | Groups (`ug`) | Flat LUTs (mean) | Decomposed LUTs (mean) | Ratio | Decomposed FFs |
|---|---:|---:|---:|---:|---:|---:|
| **8×** | 32 | 1 | 2497 | 3732 | 0.67 | 129 |
| **8×** | 32 | 2 | 2305 | 2929 | 0.79 | 126 |
| **8×** | 32 | 3 | 2171 | 2086 | 1.04 | 123 |
| **8×** | 32 | 4 | 1954 | 1462 | 1.34 | 120 |
| **4×** | 64 | 1 | 2547 | 3757 | 0.68 | 130 |
| **4×** | 64 | 2 | 2433 | 3212 | 0.76 | 128 |
| **4×** | 64 | 3 | 2361 | 2490 | 0.95 | 126 |
| **4×** | 64 | 4 | 2174 | 2068 | 1.05 | 124 |
| **2×** | 128 | 1 | 2613 | 3861 | 0.68 | 131 |
| **2×** | 128 | 2 | 2573 | 3490 | 0.74 | 130 |
| **2×** | 128 | 3 | 2544 | 3112 | 0.82 | 129 |
| **2×** | 128 | 4 | 2445 | 2704 | 0.90 | 128 |

![LUT ratio chart](lut_ratio_chart.png)

The flat design uses exactly 105 FFs in every run. LUT counts across the three seeds vary by at most approximately 1.6% relative to the mean (largest for decomposed at `u=64`, `ug=4`; the flat design stays below 1%).

## Observations

- **Crossover point:** The decomposed design uses fewer LUTs only when repetition and structural grouping are sufficient. The ratio crosses 1 between `ug=2` and `ug=3` at 8× repetition, between `ug=3` and `ug=4` at 4× repetition, and does not cross 1 at 2× repetition. The best case is a ratio of 1.34 at `u=32`, `ug=4`. At the crossover points, the ratio exceeds 1 for all three seeds, but the margins are only about 4–5%, with just three seeds and one synthesis tool.
- **Possible fixed overhead:** At `ug=1`, the decomposed design uses approximately 1.47–1.49× as many LUTs as the flat design. This ratio changes little with `u`, suggesting a structural overhead (such as the extra stage or group structure) as one possible explanation. This is a hypothesis, not a demonstrated mechanism.
- **Flat-design sensitivity:** At `u=32`, the flat design's LUT count falls by approximately 22% as `ug` increases from 1 to 4 (2497 → 1954). The paper reports that flat LUT counts are largely insensitive to repetition when using Vivado (a slight drop from `ug=1` to `ug=2`, then a plateau). The difference may reflect Yosys/ABC optimizing shared combinatorial logic, but the cause has not been isolated.
- **Flip-flops:** The flat design uses a constant 105 FFs, which agrees with the paper's finding that flat FF counts do not depend on repetition. The decomposed design uses 120–131 FFs, approximately 14–25% more than flat in every configuration. This is the opposite ordering to the paper, which reports flat designs at about 9.3–10.4K FFs and decomposed designs with far fewer, falling from about 5.1K at `ug=1` to 715 at `u=256`, `ug=4` (Vivado 2025.2, N=4096, FFs marked `DONT_TOUCH`). The direction of the trend matches, since decomposed FFs fall as `ug` and repetition rise, but my drop is small (131 → 120, about 8%) compared with the paper's. My absolute counts are also much smaller: about 90–100× for flat and about 40× for decomposed at `ug=1`, but only about 6× for decomposed at `ug=4` (120 vs. 715, at different `u`). I did not investigate why.
- **Configuration sensitivity:** An earlier sweep using `col_per_file=1` for the decomposed design produced 3.5–13.5% fewer LUTs and roughly half the FFs (62–73), with a best-case ratio of 1.53 instead of 1.34. For `u=32`, `ug=1`, seed 1, changing this setting changed the result from 3609 to 3743 LUTs and from 71 to 129 FFs. Adding `data_width` and `max_width` did not change that result. This indicates that `col_per_file` changes the generated design, not merely its file layout.
- **`ug=1` discrepancy:** The paper reports fewer LUTs for the decomposed design even at `ug=1` (about 2.3× fewer). Here, ratios of 0.67–0.68 indicate that the flat design uses fewer LUTs. Possible explanations include Yosys/ABC versus Vivado, the smaller pattern count, and differences in pattern generation. These factors have not been separated. For context, my flat designs use approximately 7.6–10.2 LUTs per pattern, compared with about 70 per pattern in the paper's flat design at N=4096 (about 285K LUTs at `u=256`, `ug=2–4`, Vivado). No conclusion about the cause can be drawn from this comparison alone.

## Limitations

- The experiment uses Yosys only and includes no timing or place-and-route measurements. The paper reports higher Fmax for decomposed designs using Vivado: 230–282 MHz versus 166–192 MHz for flat designs.
- N=256 is substantially smaller than the paper's N=4096, and my `u` values (32–128) and repetition factors (2×–8×) differ from the paper's (`u` of 256–1024, 4×–16×), so the sweeps are not directly comparable.
- The generated patterns are synthetic and contain repeated substrings; they do not represent a broad set of real-world pattern-matching workloads.
- A control attempt to synthesize the authors' N=4096 flat design (`artifact_out/fig9/flat_u256_ug1`) with the same Yosys flow was killed by the out-of-memory killer at approximately 2.5 GB on a 3.8 GB WSL machine. The decomposed control design was not attempted.
- Pattern generation in `make_synth.py` builds each column from a Python `set` of strings before shuffling, so the pattern files differ between runs even with the same seed. I confirmed this: `make_patterns(256, 32, 1, seed=1)` produces different output under different `PYTHONHASHSEED` values. This is the likely cause of the flat-count differences between the two runs (up to 13 LUTs, 0.5%), though I did not isolate it further. The flat and decomposed rows for the same seed therefore came from separate runs and use slightly different pattern sets. Sorting the sets before shuffling would make generation deterministic; I did not change the generator because that would require rerunning all 72 points. The effect is far smaller than the 4–5% crossover margins.

## Appendix: Configuration and flag verification

### Authors' synthesis command

The authors' Makefile, lines 461–463, uses the same RTL-generation command for both designs:

```bash
PYTHONPATH=engine python3 engine/tools/build_rtl_countluts.py \
    -c <config.json> -m <patterns> -o <output> \
    --rtl --tree1 --tree2
```

### Design configurations

| Setting | Flat (`one_group.json`) | Decomposed (`multi_group.json`) |
|---|---:|---:|
| `num_cols` | 1 | 4 |
| `char_per_col` | 20 | 5 |
| `col_per_file` | 1 | 4 |
| `custom` | `[]` | `[]` |

These are the authors' original configurations.

### Harness configuration

`run_sweep.py` uses the same settings and flags:

```python
FLAGS = ["--rtl", "--tree1", "--tree2"]

CFG = {
    "flat":       dict(num_cols=1, char_per_col=20, col_per_file=1),
    "decomposed": dict(num_cols=4, char_per_col=5,  col_per_file=4)
}
```

The harness serializes each configuration as JSON with `"custom": []`.

### Provenance of `results_seeded.csv`

All rows come from the committed `run_sweep.py`: the decomposed rows from one run and the flat rows from a second run, with `data_width` and `max_width` absent from both (the backend then skips `parser_top` generation).

`check_flat.py` ran the authors' exact `one_group.json` for `u=32`, `ug=1`, seed 1 and returned 2496 LUTs and 105 FFs. The earlier sweep (which also set `data_width=80, max_width=80`) recorded 2496 for that point, and the rerun recorded 2503. The 7-LUT difference is within the run-to-run variation described under Limitations, so the extra config keys do not explain it.

The separate configuration checks are in `check_cfg.py` and `check_flat.py`. The earlier decomposed results using `col_per_file=1` are retained in `results_seeded_colperfile1.csv`, and the earlier flat rows in `results_seeded_before_flat_rerun.csv`.