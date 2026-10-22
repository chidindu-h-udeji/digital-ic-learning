# gramm-repro: learning GRAMM by re-implementing it

*Built with AI assistance; see [../README.md](../README.md).*

A learning exercise. To understand GRAMM (Zhou, Stojilović, and Anderson), I re-implemented its graph-minor mapper from the paper's pseudocode and compared the paper's four variants on a toy CGRA using 14 small dataflow graphs. The aim was to understand why each variant helps, not to match the paper's numbers.

**What I found.** The general improvement from BASELINE through RAND_BEST to PATHFINDER reproduces, but the size of the PathFinder improvement does not. Average success over 100 seeds for BASELINE, RAND_BEST, PATHFINDER, and PATHFINDER_SORT was **26% → 34% → 44% → 44%**, compared with **29% → 36% → 97% → 98%** in the paper. SORT showed no measurable overall benefit in this implementation.

## What I built

A directed 6×6 toroidal device graph, with an ALU vertex and an output-multiplexer vertex per processing element (PE), and I/O vertices on two edge columns. The implementation includes an independent legality checker, vertex-weighted Dijkstra, the paper's Algorithms 1–2 with a fan-in routing rule, and all four mapping variants.

The grid size was chosen using BASELINE only, with calibration seeds that were never reused in the main experiment. The grid and benchmark set were frozen before the main experiment.

See [DESIGN.md](DESIGN.md) for the modelling decisions, implementation details, calibration procedure, and known limitations.

## Results

Successes out of 100 runs per benchmark and variant, using a 6×6 chip. An asterisk (`*`) marks a benchmark that BASELINE did not solve during calibration.

| Benchmark | BASELINE | RAND_BEST | PATHFINDER | PF_SORT |
|---|---:|---:|---:|---:|
| chain8 | 97 | 98 | 100 | 100 |
| chain20 | 23 | 67 | 96 | 92 |
| reduce4 | 97 | 96 | 100 | 100 |
| reduce8 | 32 | 59 | 80 | 78 |
| bcast2 | 25 | 31 | 30 | 30 |
| bcast3 * | 0 | 1 | 6 | 2 |
| mac_const6 | 20 | 46 | 83 | 91 |
| mac4 | 41 | 47 | 83 | 78 |
| diamonds4 | 25 | 30 | 32 | 32 |
| diamonds7 * | 0 | 2 | 4 | 6 |
| rand_a * | 0 | 0 | 2 | 1 |
| rand_b * | 0 | 0 | 0 | 0 |
| rand_c * | 0 | 0 | 0 | 0 |
| rand_d * | 0 | 0 | 0 | 0 |
| **Average, all 14** | **26%** | **34%** | **44%** | **44%** |
| Average, 8 baseline-solvable | 45% | 59% | 76% | 75% |

![Success rate per variant and benchmark](results_chart.png)

The full experiment contains 5,600 runs: 14 benchmarks × 4 variants × 100 seeds. Each successful mapping was checked again with the independent checker. Every variant uses the same set of experiment seeds, allowing paired comparisons.

With 100 runs, the approximate binomial standard error near an 80% success rate is 4 percentage points. Small differences in an individual benchmark should therefore be interpreted cautiously; this simple estimate is not a full uncertainty analysis of the paired comparisons.

## Against the paper

- **What reproduces:** RAND_BEST improves on BASELINE overall, and PATHFINDER improves further. RAND_BEST gains 8 percentage points here, close to the paper's 7-point gain. PATHFINDER also turns several difficult benchmarks into mostly successful ones: `chain20` improves from 23% to 96%, `mac_const6` from 20% to 83%, and `reduce8` from 32% to 80%.
- **What does not reproduce:** The PathFinder jump is much smaller. The paper improves from 36% to 97%, while this implementation improves from 34% to 44% across all 14 benchmarks, or from 59% to 76% across the eight baseline-solvable benchmarks. SORT's reported gain also does not reproduce: the rounded overall averages remain 44%, while the eight-benchmark average decreases from 76% to 75%.
- **Why the results may differ:** The toy device is more restrictive than the paper's ADRES architecture, and six benchmarks remain nearly unmappable for every variant. Two other benchmarks, `bcast2` and `diamonds4`, plateau near 30% on the reported seeds.

### Investigating the plateau

An additional diagnostic (`diagnose.py`, seeds 100–129, outside the reported experiment range) found that 18 of the 19 failed `bcast2` runs ended with exactly one overused vertex. In these cases, the output-multiplexer (`out`) vertex of a producer was claimed by two sibling consumers while the producer's own model held only its ALU or I/O vertex. Seed 106 showed a different overlap pattern.

This suggests an **exit-door problem**: two consumers can compete for a producer's output vertex, and increasing routing costs cannot resolve the conflict if neither consumer has another feasible route.

A second diagnostic (`diagnose_order.py`, seeds 100–299) found that the initial processing order was associated with mapping success. For `bcast2`, PATHFINDER succeeded in 41/48 runs when no producer appeared before all its consumers in the initial order, compared with 46/152 runs when at least one producer did. For `diamonds4`, the corresponding results were 38/44 and 32/156.

These results indicate a strong tendency, not a deterministic rule: `bcast2` still succeeded in 46 of 152 runs that had a bad producer. The plateau is also seed-sensitive: `bcast2` achieved 30% under PATHFINDER on the reported seeds and 44% on diagnostic seeds 100–299.

`diagnose_order.py` also prints a rough (2/3)^k figure, where k is the number of fan-out producers. This is the chance that a random order has no bad producer (a producer with two consumers comes first of its three nodes with probability 1/3), not a predicted success rate. For `bcast2` (k=3) and `diamonds4` (k=4) it gives about 30% and 20%, against observed success of 44% (87/200) and 35% (70/200). For `bcast3` and `diamonds7` (k=7 for both) it gives about 6%, close to their observed 6% and 4%, but only 5 and 11 of the 200 seeds had no bad producer there, and those succeeded in just 1/5 and 2/11 runs. The agreement on the two larger benchmarks is therefore partly coincidence, and these samples are too small to support more.

The results suggest a possible issue with how fan-out ownership is handled in this implementation, which may understate the benefit of PATHFINDER on these benchmarks. This explanation is a hypothesis, not a proven cause. The code was not changed after the main experiment; any fix should be evaluated in a separately labelled experiment.

## Limitations

- The device is a toy CGRA model without registers, memory ports, or scheduling, and the benchmarks are synthetic. Absolute success rates are therefore not directly comparable with the paper's ADRES results.
- Each model has one typed root vertex. The paper allows the root to be any device vertex, so this implementation makes a simplifying assumption.
- The fan-in routing rule is an approximation and is not verified by the independent checker's four rules. It was separately monitored during testing.
- Output paths are not blocked against input paths, so a vertex could carry incoming and outgoing data within the same territory.
- The stopping rule—10 passes without improvement or a maximum of 100 passes—is an implementation choice, not the paper's stopping rule.
- Only one grid size was used in the main experiment. The study does not compare resource usage or runtime against the paper's ILP mapper.
- The six near-unmappable benchmarks remain in the primary all-14 average rather than being removed after observing the main results.

## Running the project

Python 3 is required. Python 3.14.7 reproduces the recorded results for the seeds I spot-checked (`chain8`, BASELINE, seeds 0–11); the version used for the full sweep was not recorded. The standard library is sufficient for the mapper and experiments; `matplotlib` is required to generate the chart.

Run the tests:

```bash
for t in test_*.py; do python3 "$t"; done
```

Run the baseline-only calibration:

```bash
python3 calibrate.py
```

Run the main experiment (100 seeds per benchmark and variant by default):

```bash
python3 run_experiment.py
```

The experiment writes `results.csv` and `results_chart.png`.

### Optional diagnostics

To inspect the exit-door problem:

```bash
python3 diagnose.py
```

To investigate the relationship between initial processing order and mapping success:

```bash
python3 diagnose_order.py
```

The diagnostic scripts use seeds outside the main reported experiment range. They help investigate the observed limitations but do not modify the main experiment results.

The reported experiment uses seeds 0–99, while calibration uses seeds 10000–10039. Results are reproducible for a fixed environment and code version; measured runtimes will vary between machines.