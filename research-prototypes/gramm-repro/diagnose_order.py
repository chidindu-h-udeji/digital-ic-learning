"""Does initial node order explain the ~30% plateau? (seeds 100-299, outside the
reported range 0-99). 'Bad' producer = comes BEFORE all of its consumers."""
import random

from benchmarks import BENCHMARKS, GRID_ROWS, GRID_COLS
from device import build_cgra
from mapper import map_dfg

G = build_cgra(GRID_ROWS, GRID_COLS)
SEEDS = range(100, 300)


def initial_pos(H, seed):
    order = list(range(len(H["kind"])))
    random.Random(seed).shuffle(order)          # same first draw map_dfg makes
    return {x: i for i, x in enumerate(order)}


print(f"{'benchmark':<11}{'k':>3}{'(2/3)^k':>9}{'observed':>10}"
      f"{'no bad producer':>18}{'some bad producer':>20}")
for b in ["bcast2", "diamonds4", "bcast3", "diamonds7"]:
    H = BENCHMARKS[b]
    fan = [x for x in range(len(H["kind"])) if len(H["succ"][x]) >= 2]
    results = []
    for s in SEEDS:
        pos = initial_pos(H, s)
        n_bad = sum(pos[x] < min(pos[c] for c in H["succ"][x]) for x in fan)
        results.append((n_bad, map_dfg(H, G, "PATHFINDER", s)[0]))
    none = [ok for n, ok in results if n == 0]
    some = [ok for n, ok in results if n > 0]
    frac = lambda v: f"{sum(v)}/{len(v)}"
    print(f"{b:<11}{len(fan):>3}{(2/3) ** len(fan):>9.0%}"
          f"{sum(ok for _, ok in results) / len(results):>10.0%}"
          f"{frac(none):>18}{frac(some):>20}")