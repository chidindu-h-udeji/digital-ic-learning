import random

from device import build_cgra
from checker import check_mapping
from mapper import VARIANTS, find_vertex_model, map_dfg


def make_dfg(kinds, edges):
    succ = [[] for _ in kinds]
    pred = [[] for _ in kinds]
    for a, b in edges:
        succ[a].append(b)
        pred[b].append(a)
    return dict(kind=kinds, succ=succ, pred=pred)


tree = make_dfg(["io"] * 4 + ["alu"] * 3 + ["io"],
                [(0, 4), (1, 4), (2, 5), (3, 5), (4, 6), (5, 6), (6, 7)])
G3 = build_cgra(3, 3)

# ---------------------------------------------------------------- layers
print("V0 layers (rand_best, pathfinder, sort):")
for name, flags in VARIANTS.items():
    print(f"     {name:<16} {flags}")

# ------------------------------------------------- RAND_BEST: the coin flips
# device: route vertex 0 feeds three identical ALUs 1, 2, 3 -> a 3-way tie
Gt = dict(kind=["route", "alu", "alu", "alu"],
          succ=[[1, 2, 3], [], [], []], pred=[[], [0], [0], [0]])
Ht = make_dfg(["alu", "alu"], [(0, 1)])
phi = [{0}, set()]
w = [1, 1, 1, 1]


def pick(rand_best, seed):
    m = find_vertex_model(1, Ht, Gt, phi, w, random.Random(seed), rand_best=rand_best)
    return max(m)          # the root (the ALU id)


base = [pick(False, s) for s in range(4000)]
rb = [pick(True, s) for s in range(4000)]
print("V1 BASELINE always takes the first tie (id 1):", set(base) == {1})
share = {r: round(rb.count(r) / 4000, 2) for r in (1, 2, 3)}
print(f"V2 RAND_BEST picks all three, NOT uniformly: {share}  (theory: 0.25 / 0.25 / 0.5)")

# ---------------------------------------------------- PATHFINDER: P and H
log = []
ok, _, _ = map_dfg(tree, G3, "PATHFINDER", 0, log=log)
print(f"V3 PATHFINDER run (seed 0): {len(log)} passes, success={ok}")
P_ok = all(abs(e["P"] - 1.1 ** (e["it"] - 1)) < 1e-9 for e in log)
print("   P used each pass:", [round(e["P"], 3) for e in log], "-> multiplies by 1.1:", P_ok)
prev = [0] * len(log[0]["hist"])
H_ok, H_rows = True, []
for e in log:
    # after pass `it` (unless it was the last, successful one) hist grew by 1
    # exactly on that pass's overused vertices, and nowhere else
    final_ok_pass = (e is log[-1] and ok)
    expected = list(prev)
    if not final_ok_pass:
        for v in e["overused"]:
            expected[v] += 1
    H_ok &= (e["hist"] == expected)
    H_rows.append((e["it"], e["overused"], sum(e["hist"])))
    prev = e["hist"]
print("   (pass, overused vertices, total history):", H_rows)
print("V4 H grows by 1 only on overused vertices:", H_ok)

# ------------------------------------------------------------------- SORT
log = []
map_dfg(tree, G3, "PATHFINDER_SORT", 0, log=log)
sorted_ok = True
for prev_e, e in zip(log, log[1:]):
    sizes = [prev_e["sizes"][x] for x in e["order"]]
    sorted_ok &= all(a >= b for a, b in zip(sizes, sizes[1:]))
print(f"V5 SORT: every pass orders nodes by previous model size, largest first: {sorted_ok}"
      f"  ({len(log)} passes)")

changed = 0
for s in range(30):
    lg = []
    map_dfg(tree, G3, "PATHFINDER_SORT", s, log=lg)
    if len(lg) >= 2 and lg[1]["order"] != lg[0]["order"]:
        changed += 1
print(f"V6 SORT changes the order after pass 1 in {changed}/30 runs")

lg = []
map_dfg(tree, G3, "PATHFINDER", 0, log=lg)
print("V7 without SORT the order never changes:", all(e["order"] == lg[0]["order"] for e in lg))

# ----------------------------------------- every variant: legal + repeatable
for name in VARIANTS:
    runs = [map_dfg(tree, G3, name, s) for s in range(50)]
    legal = all(check_mapping(tree, G3, r[1])[0] for r in runs if r[0])
    again = [map_dfg(tree, G3, name, s) for s in range(50)]
    print(f"V8 {name:<16} {sum(r[0] for r in runs):>2}/50 succeed | "
          f"all successes legal: {legal} | same seed repeats: {runs == again}")