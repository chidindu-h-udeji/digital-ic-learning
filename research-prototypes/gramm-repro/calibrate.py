"""Choose the grid size using ONLY the BASELINE variant.

Calibration seeds (10000+) are disjoint from the experiment seeds (0..N-1),
so the grid is not tuned on the runs we report.
Writes calibration.csv and prints a table: success % per benchmark per size.
"""
import csv
import time

from benchmarks import BENCHMARKS, describe
from device import build_cgra
from mapper import map_dfg

SIZES = [4, 5, 6, 7, 8, 9]
N_SEEDS = 40
SEED0 = 10000


def fits(dfg, n):
    _, n_io, n_alu, _, _ = describe(dfg)
    return n_alu <= n * n and n_io <= 2 * n      # enough ALUs and io pads


if __name__ == "__main__":
    t0 = time.time()
    table = {}                                   # (bench, size) -> percent or None
    for n in SIZES:
        G = build_cgra(n, n)
        for name, dfg in BENCHMARKS.items():
            if not fits(dfg, n):
                table[(name, n)] = None          # cannot fit at all
                continue
            wins = sum(map_dfg(dfg, G, "BASELINE", SEED0 + s)[0] for s in range(N_SEEDS))
            table[(name, n)] = round(100 * wins / N_SEEDS)
        print(f"  ... finished {n}x{n}  ({time.time() - t0:.0f}s)", flush=True)

    with open("calibration.csv", "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["benchmark", "grid", "baseline_success_percent"])
        for (name, n), pct in table.items():
            wr.writerow([name, f"{n}x{n}", "" if pct is None else pct])

    print()
    print(f"{'benchmark':<12}" + "".join(f"{n}x{n:<4}".rjust(7) for n in SIZES))
    for name in BENCHMARKS:
        row = "".join(("   -   " if table[(name, n)] is None else f"{table[(name, n)]:>6}%") for n in SIZES)
        print(f"{name:<12}{row}")
    print("-" * (12 + 7 * len(SIZES)))
    print(f"{'#fit':<12}" + "".join(f"{sum(table[(b, n)] is not None for b in BENCHMARKS):>7}" for n in SIZES))
    avg = []
    for n in SIZES:
        vals = [table[(b, n)] for b in BENCHMARKS if table[(b, n)] is not None]
        avg.append(f"{sum(vals) / len(vals):>6.0f}%")
    print(f"{'avg (fit)':<12}" + "".join(avg))
    allfit = []
    for n in SIZES:
        if all(table[(b, n)] is not None for b in BENCHMARKS):
            allfit.append(f"{sum(table[(b, n)] for b in BENCHMARKS) / len(BENCHMARKS):>6.0f}%")
        else:
            allfit.append("   n/a ")
    print(f"{'avg (all14)':<12}" + "".join(allfit))