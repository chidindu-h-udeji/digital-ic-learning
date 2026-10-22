import random

import mapper
from device import build_cgra
from checker import check_mapping
from mapper import find_vertex_model, map_dfg


def make_dfg(kinds, edges):
    succ = [[] for _ in kinds]
    pred = [[] for _ in kinds]
    for a, b in edges:
        succ[a].append(b)
        pred[b].append(a)
    return dict(kind=kinds, succ=succ, pred=pred)


def tiny_graph(kinds, edges):
    return make_dfg(kinds, edges)   # same shape: kind / succ / pred


# ---------- Test A: hand-built case --------------------------------------
# Device:  0 -> 2 -> 4(alu)      two producers P1=0, P2=1 both want the
#          1 -> 2                 short wire 2.  P2 also has a longer way:
#          1 -> 3 -> 4            1 -> 3 -> 4.
G = tiny_graph(["route", "route", "route", "route", "alu"],
               [(0, 2), (1, 2), (2, 4), (1, 3), (3, 4)])
H = make_dfg(["alu", "alu", "alu"], [(0, 2), (1, 2)])   # node 2 has two inputs
phi = [{0}, {1}, set()]
w = [1] * 5

off = find_vertex_model(2, H, G, phi, w, random.Random(0), fanin=False)
on = find_vertex_model(2, H, G, phi, w, random.Random(0), fanin=True)
print("A1 rule OFF merges both inputs onto wire 2 :", off == {4, 2},  sorted(off))
print("A2 rule ON  sends the 2nd input the long way:", on == {4, 2, 3}, sorted(on))

# remove the long way: disjoint routing is impossible
G2 = tiny_graph(["route", "route", "route", "route", "alu"],
                [(0, 2), (1, 2), (2, 4)])
on2 = find_vertex_model(2, H, G2, phi, w, random.Random(0), fanin=True)
print("A3 impossible case -> no fake routing (only a bare root):", on2 == {4}, sorted(on2))

# ---------- Test B: watch every real run ---------------------------------
real = build_cgra(3, 3)
tree = make_dfg(["io"] * 4 + ["alu"] * 3 + ["io"],
                [(0, 4), (1, 4), (2, 5), (3, 5), (4, 6), (5, 6), (6, 7)])

original = mapper.find_vertex_model


def violations(fanin):
    audit, bad, checked = [], 0, 0
    mapper.find_vertex_model = lambda *a, **k: original(*a, **k, audit=audit)
    try:
        successes = 0
        for seed in range(40):
            audit.clear()
            ok, phi_, _ = map_dfg(tree, real, "BASELINE", seed, fanin=fanin)
            successes += ok
            # inspect every fan-in routing decision made in this run
            for x, paths in audit:
                if len(paths) >= 2:
                    checked += 1
                    seen = set()
                    for p in paths:
                        mids = set(p[1:-1])
                        if seen & mids:
                            bad += 1
                            break
                        seen |= mids
    finally:
        mapper.find_vertex_model = original
    return bad, checked, successes


bad_on, n_on, s_on = violations(True)
bad_off, n_off, s_off = violations(False)
print(f"B1 rule ON : {bad_on} shared-wire decisions out of {n_on} two-input decisions "
      f"({s_on}/40 seeds succeed)")
print(f"B2 rule OFF: {bad_off} shared-wire decisions out of {n_off} two-input decisions "
      f"({s_off}/40 seeds succeed)")
print("B3 monitor can fail (rule OFF shows violations):", bad_off > 0)
print("B4 rule ON never shares:", bad_on == 0)