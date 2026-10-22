"""Milestone 8: run all 4 variants on all 14 benchmarks, many seeds.

    python3 run_experiment.py --time     time a few runs and project the total
    python3 run_experiment.py            full sweep (100 seeds, like the paper)

Grid (6x6) and the benchmark set are FROZEN in benchmarks.py.
Experiment seeds are 0..N-1; calibration used 10000+, so nothing is reused.
Writes results.csv and results_chart.png, prints a Table-I-style summary.
"""
import argparse
import csv
import multiprocessing as mp
import time

from benchmarks import BENCHMARKS, BASELINE_SOLVABLE, GRID_ROWS, GRID_COLS
from checker import check_mapping
from device import build_cgra
from mapper import VARIANTS, map_dfg

N_SEEDS = 100
PROCESSES = 2

_G = None


def _init_worker():
    global _G
    _G = build_cgra(GRID_ROWS, GRID_COLS)        # each process builds its own chip


def run_one(task):
    bench, variant, seed = task
    H = BENCHMARKS[bench]
    t0 = time.perf_counter()
    ok, phi, iters = map_dfg(H, _G, variant, seed)
    secs = time.perf_counter() - t0
    if ok:                                       # belt and braces: re-judge it
        ok = check_mapping(H, _G, phi)[0]
    return bench, variant, seed, int(ok), iters, round(secs, 4)


def make_tasks(n_seeds):
    return [(b, v, s) for b in BENCHMARKS for v in VARIANTS for s in range(n_seeds)]


def table(rows, n_seeds):
    wins = {(b, v): 0 for b in BENCHMARKS for v in VARIANTS}
    for b, v, s, ok, it, sec in rows:
        wins[(b, v)] += ok
    names = list(VARIANTS)
    W = 30                                            # width of the label column
    head = f"{'benchmark':<{W}}" + "".join(f"{n:>17}" for n in names)
    lines = [f"successes out of {n_seeds} runs, 6x6 chip", head, "-" * len(head)]
    for b in BENCHMARKS:
        mark = "" if b in BASELINE_SOLVABLE else " *"
        lines.append(f"{b + mark:<{W}}" + "".join(f"{wins[(b, v)]:>17}" for v in names))
    lines.append("-" * len(head))
    views = {"AVERAGE, all 14": list(BENCHMARKS),
             "AVERAGE, 8 baseline-solvable": BASELINE_SOLVABLE}
    avgs = {}
    for label, members in views.items():
        a = [sum(wins[(b, v)] for b in members) / (len(members) * n_seeds) * 100 for v in names]
        avgs[label] = a
        lines.append(f"{label:<{W}}" + "".join(f"{x:>16.0f}%" for x in a))
    lines.append("(* = not among the 8 baseline-solvable benchmarks)")
    return "\n".join(lines), wins, avgs


def chart(wins, avgs, n_seeds, path="results_chart.png"):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    names = list(VARIANTS)
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 4.8),
                                   gridspec_kw={"width_ratios": [1, 2.4]})
    w = 0.2
    x = range(len(names))
    ax1.bar([i - 0.2 for i in x], avgs["AVERAGE, all 14"], 0.4, label="all 14")
    ax1.bar([i + 0.2 for i in x], avgs["AVERAGE, 8 baseline-solvable"], 0.4, label="8 baseline-solvable")
    ax1.set_xticks(list(x)); ax1.set_xticklabels([n.replace("_", "\n") for n in names], fontsize=8)
    ax1.set_ylabel("success rate (%)"); ax1.set_ylim(0, 100); ax1.legend(); ax1.set_title("Averages")
    bl = list(BENCHMARKS)
    for j, v in enumerate(names):
        ax2.bar([i + (j - 1.5) * w for i in range(len(bl))],
                [100 * wins[(b, v)] / n_seeds for b in bl], w, label=v)
    ax2.set_xticks(range(len(bl))); ax2.set_xticklabels(bl, rotation=45, ha="right", fontsize=8)
    ax2.set_ylim(0, 100); ax2.set_title(f"Per benchmark ({n_seeds} seeds, 6x6 chip)"); ax2.legend(fontsize=7)
    fig.tight_layout(); fig.savefig(path, dpi=140); plt.close(fig)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--time", action="store_true")
    ap.add_argument("--seeds", type=int, default=N_SEEDS)
    args = ap.parse_args()

    if args.time:
        _init_worker()
        tot = 0.0
        for b in ("rand_d", "mac4"):
            for v in VARIANTS:
                r = run_one((b, v, 0)); tot += r[5]
                print(f"{b:<8}{v:<17} success={r[3]} iters={r[4]:>3}  {r[5]:.2f}s")
        per_run = tot / 8
        n_runs = len(make_tasks(args.seeds))
        print(f"\nmean {per_run:.2f}s/run  x {n_runs} runs = {per_run * n_runs / 60:.1f} min "
              f"on 1 core, about {per_run * n_runs / 60 / PROCESSES:.1f} min on {PROCESSES}")
        raise SystemExit

    tasks = make_tasks(args.seeds)
    t0 = time.time()
    with mp.Pool(PROCESSES, initializer=_init_worker) as pool:
        rows = []
        for i, r in enumerate(pool.imap_unordered(run_one, tasks, chunksize=10), 1):
            rows.append(r)
            if i % 500 == 0:
                print(f"  {i}/{len(tasks)} runs  ({time.time() - t0:.0f}s)", flush=True)

    order_b = {b: i for i, b in enumerate(BENCHMARKS)}
    order_v = {v: i for i, v in enumerate(VARIANTS)}
    rows.sort(key=lambda r: (order_b[r[0]], order_v[r[1]], r[2]))     # stable file
    with open("results.csv", "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["benchmark", "variant", "seed", "success", "iters", "seconds"])
        wr.writerows(rows)

    text, wins, avgs = table(rows, args.seeds)
    print("\n" + text)
    chart(wins, avgs, args.seeds)
    print(f"\n{len(rows)} rows written to results.csv, chart to results_chart.png "
          f"({time.time() - t0:.0f}s total)")