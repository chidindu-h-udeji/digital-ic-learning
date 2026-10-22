from benchmarks import BENCHMARKS, GRID_ROWS, GRID_COLS
from device import build_cgra
from mapper import map_dfg

G = build_cgra(GRID_ROWS, GRID_COLS)
name = {i: n for n, i in G["names"].items()}
H = BENCHMARKS["bcast2"]

for seed in range(100, 130):
    ok, phi, _ = map_dfg(H, G, "PATHFINDER", seed)
    if ok:
        continue
    owners = {}
    for x, model in enumerate(phi):
        for v in model:
            owners.setdefault(v, []).append(x)
    for v, xs in owners.items():
        if len(xs) > 1:
            prods = {p for x in xs for p in H["pred"][x]}
            held = {p: sorted(name[u] for u in phi[p]) for p in prods}
            print(f"seed {seed}: {name[v]} owned by {xs}; producers hold {held}")