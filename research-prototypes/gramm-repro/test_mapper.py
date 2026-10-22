from device import build_cgra
from checker import check_mapping
from mapper import map_dfg


def make_dfg(kinds, edges):
    succ = [[] for _ in kinds]
    pred = [[] for _ in kinds]
    for a, b in edges:
        succ[a].append(b)
        pred[b].append(a)
    return dict(kind=kinds, succ=succ, pred=pred)


chain = make_dfg(["io", "alu", "io"], [(0, 1), (1, 2)])
# binary tree: 4 inputs -> 2 adders -> 1 adder -> output
tree = make_dfg(["io"] * 4 + ["alu"] * 3 + ["io"],
                [(0, 4), (1, 4), (2, 5), (3, 5), (4, 6), (5, 6), (6, 7)])

# 1. chain on 3x3
G3 = build_cgra(3, 3)
runs = [map_dfg(chain, G3, "BASELINE", seed) for seed in range(20)]
n_ok = sum(r[0] for r in runs)
all_legal = all(check_mapping(chain, G3, r[1])[0] for r in runs if r[0])
print(f"chain on 3x3 : {n_ok}/20 seeds succeed, iterations used: "
      f"{sorted(set(r[2] for r in runs if r[0]))}, all successes pass checker: {all_legal}")

# 2. tree on 5x5
G5 = build_cgra(5, 5)
runs = [map_dfg(tree, G5, "BASELINE", seed) for seed in range(20)]
n_ok = sum(r[0] for r in runs)
all_legal = all(check_mapping(tree, G5, r[1])[0] for r in runs if r[0])
print(f"tree  on 5x5 : {n_ok}/20 seeds succeed, all successes pass checker: {all_legal}")

# 3. determinism: same seed -> identical result; different seeds -> usually differ
a = map_dfg(tree, G5, "BASELINE", 7)
b = map_dfg(tree, G5, "BASELINE", 7)
c = map_dfg(tree, G5, "BASELINE", 8)
print("same seed identical  :", a == b)
print("different seed differs:", a != c)