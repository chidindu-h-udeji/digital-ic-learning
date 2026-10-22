# Design notes and decisions

Detail behind the README. Everything here is a modelling or experimental choice
made while building the project.

## Device graph (`device.py`)

1. Each PE has an `alu` vertex and an `out` (output-multiplexer) vertex. `io`
   vertices sit on the first and last column. The grid wraps around (toroidal),
   as in the paper's ADRES description.
2. Edges: `alu → out` (own result), neighbour `out → my alu` (input), neighbour
   `out → my out` (route-through; my ALU stays idle), and `io ↔ out` at the edge
   columns. A 5×5 chip has 60 vertices and 245 edges (checked by hand and by
   code); the diameter D is 6 for 5×5 and 4 for 3×3.
3. No registers, memory ports or scheduling in time. This is a pure
   place-and-route toy.

## Fixed modelling choices (from the plan)

1. **Device model:** as above.
2. **Compute vertex:** every vertex model has exactly one non-route vertex, of
   the same kind as its DFG node, and the root is that vertex. The paper lets
   the root be any vertex, so this is a simplification.
3. **No pass-through:** `alu` and `io` vertices are never traversed, only
   `route` vertices. A search may start at a source model and end at a typed
   vertex.
4. **Cost of a root `g`:** the weight of `g` plus the weights of the
   intermediate route vertices on each path. Implemented as the sum of Dijkstra
   distances, which include `w[g]` once per path, minus `(k-1)·w[g]` for `k`
   neighbours. The paper's wording is brief; this is my reading of it.
5. **Variants are layered** as in the paper's Table I: BASELINE, then
   +RAND_BEST, then +PATHFINDER, then +SORT.

## Decisions documented while building

- **Old model removed first.** When recomputing node *x*, its old model is
  removed before `S(g)` is counted. The paper's pseudocode doesn't say.
- **Weights recomputed before every node** (Algorithm 2, line 6), not once per
  pass.
- **Stopping rule (identical for all four variants):** stop after 10 passes with
  no improvement in total overlap, or after 100 passes. The paper gives no
  numbers. A side check on three hard benchmarks showed that tripling the
  patience barely changed success.
- **Success** means no vertex is in two models *and* the independent checker
  (`checker.py`) accepts the mapping. If overlap reaches zero but the checker
  still rejects, that counts as "1 problem" for the stopping rule.
- **Fallback root:** if no candidate root is reachable, or no root can host all
  its inputs disjointly, a random root of the right kind is used. It is a bare
  root, which fails the checker, so it can never produce a false success.
- **Fan-in rule (approximate).** Paths from different producers into one node
  must not share routing vertices; a producer's paths to several consumers may
  merge. Implementation: pick the cheapest root, route the input paths one at a
  time, and block each finished path's routing vertices for the next one. If the
  inputs can't be routed disjointly, try the next-cheapest root. Inputs are
  routed in DFG order. Only input paths are blocked against each other; output
  paths are not blocked against input paths. **The checker does not verify this
  rule.** It is guaranteed by how paths are built and was checked with a monitor
  on 40 real runs (0 violations with the rule on, 48 with it off, so the monitor
  can fail).
- **RAND_BEST** is the paper's "flip a coin on each new minimum", implemented as
  a streaming 1/2 replace-on-tie. This is **not uniform sampling**: with three
  tied roots the picks are about 25% / 25% / 50% (verified in
  `test_variants.py`).
- **PATHFINDER:** `w(g) = (1 + |S(g)|) · P · (1 + H(g))`. `P` starts at 1 and is
  multiplied by 1.1 after each pass. `H(g)` starts at 0 and increases by 1 for
  every overused vertex after each pass. Costs are rounded to 9 digits before
  comparison so floating-point ties stay ties.
- **SORT:** from the second pass on, nodes are ordered by the size of their
  previous model, largest first, with random tie-breaks.
- All randomness comes from `random.Random(seed)`.

## Benchmarks and calibration

- 14 DFGs of 8–38 nodes with fan-in ≤ 2, built in `benchmarks.py`: chains,
  reduction trees, broadcast trees, multiply-accumulate (two forms), stacked
  diamonds, and four random DAGs with fixed seeds. (The paper's DFGs have 6–43
  nodes.) One random DAG was shrunk from 43 to 38 nodes purely to satisfy the
  size rule, before any calibration.
- **Grid size 6×6**, chosen with the **BASELINE variant only**, on calibration
  seeds 10000–10039. Rule: the smallest square grid on which all 14 benchmarks
  fit. There the baseline averages 28%: not 0%, not 100%. Larger grids barely
  change that (28% → 36% at 9×9). The full table is in `calibration.csv`.
- The grid and benchmark set were **frozen before the experiment**.
- **Two reporting views declared in advance** (from baseline calibration only):
  the primary view uses all 14 benchmarks; the secondary view uses the 8
  benchmarks where the baseline succeeded at least once on 6×6 (`chain8`,
  `chain20`, `reduce4`, `reduce8`, `bcast2`, `mac_const6`, `mac4`, `diamonds4`).
- **Seeds:** experiment 0–99 (all variants share them, so comparisons are
  paired); calibration 10000–10039; a feasibility check 20000+; the exit-door
  diagnostics 100–299. No range is reused for a different purpose.

## Additional limitations

- The 14 benchmarks are synthetic, not the paper's 16 CGRA-ME and hand-built
  circuits.
- Output paths are not blocked against input paths, so one vertex could carry
  both incoming and outgoing data in the same territory.
- The calibration covered 4×4 to 9×9 for the baseline only; the experiment used
  one size.
- Success is the only metric; neither resource use nor runtime was compared
  with the paper's ILP mapper.

## Files

| File | Purpose |
|---|---|
| `device.py` | Device graph and BFS diameter |
| `checker.py` | Independent legality checker (4 rules) |
| `dijkstra.py` | Vertex-weighted multi-source Dijkstra (forward/reverse, blocked set) |
| `mapper.py` | Algorithms 1 and 2, fan-in rule, the four variants |
| `benchmarks.py` | 14 DFGs; frozen grid size and benchmark views |
| `calibrate.py`, `calibration.csv` | Baseline-only grid calibration |
| `run_experiment.py` | The sweep; writes `results.csv`, `results_chart.png` |
| `diagnose.py`, `diagnose_order.py` | Exit-door diagnostics (seeds outside the reported range) |
| `test_*.py` | Tests for each milestone, including deliberate failure cases |