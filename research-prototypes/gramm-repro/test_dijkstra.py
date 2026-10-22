from device import build_cgra, bfs_distances
from dijkstra import dijkstra, trace


def tiny(kinds, edges):
    n = len(kinds)
    succ = [[] for _ in range(n)]
    pred = [[] for _ in range(n)]
    for a, b in edges:
        succ[a].append(b)
        pred[b].append(a)
    return dict(kind=kinds, succ=succ, pred=pred)


# 1. uniform weights == hop counts (all-route graph: 3x3 two-way grid)
def grid_graph(n=3):
    edges = []
    for r in range(n):
        for c in range(n):
            for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                rr, cc = r + dr, c + dc
                if 0 <= rr < n and 0 <= cc < n:
                    edges.append((r * n + c, rr * n + cc))
    return tiny(["route"] * (n * n), edges)


g = grid_graph()
w = [1] * 9
ok = True
for s in range(9):
    dist, _ = dijkstra(g, w, [s])
    hops = bfs_distances(g["succ"], s)
    ok &= (dist == hops)
# multi-source: distance = min over sources
dist, _ = dijkstra(g, w, [0, 8])
hops0, hops8 = bfs_distances(g["succ"], 0), bfs_distances(g["succ"], 8)
ok &= all(dist[v] == min(hops0[v], hops8[v]) for v in range(9))
print("PASS" if ok else "FAIL", " uniform weights equal hop counts (single + multi source)")

# 2. cannot pass THROUGH an alu:  a(route) -> b(alu) -> c(route)
g = tiny(["route", "alu", "route"], [(0, 1), (1, 2)])
dist, _ = dijkstra(g, [1, 1, 1], [0])
ok = (1 in dist) and (2 not in dist)
print("PASS" if ok else "FAIL", " alu is reachable but not traversable (c unreachable)")

# ...but an alu that is itself a SOURCE may expand
dist, _ = dijkstra(g, [1, 1, 1], [1])
ok = (2 in dist)
print("PASS" if ok else "FAIL", " an alu used as a source does expand")

# 3. on the real chip, no path ever has a typed vertex in the middle
G = build_cgra(5, 5)
w = [1] * len(G["kind"])
bad = 0
for s in range(len(G["kind"])):
    dist, parent = dijkstra(G, w, [s])
    for v in dist:
        middle = trace(parent, v)[1:-1]
        bad += sum(1 for m in middle if G["kind"][m] != "route")
print("PASS" if bad == 0 else "FAIL", f" real chip: {bad} paths pass through a typed vertex")

# 4. weights steer the path: diamond a->b->d and a->c->d, b is expensive
g = tiny(["route"] * 4, [(0, 1), (0, 2), (1, 3), (2, 3)])
dist, parent = dijkstra(g, [1, 10, 1, 1], [0])
ok = dist[3] == 2 and trace(parent, 3) == [3, 2, 0]
print("PASS" if ok else "FAIL", " expensive vertex is avoided (path goes through c)")

# 5. reverse search agrees with forward search (uniform weights, all pairs)
n = len(G["kind"])
mismatch = 0
for t in range(n):
    rdist, _ = dijkstra(G, w, [t], reverse=True)
    for v in range(n):
        fdist, _ = dijkstra(G, w, [v])
        if rdist.get(v) != fdist.get(t):
            mismatch += 1
print("PASS" if mismatch == 0 else "FAIL", f" reverse == forward on all {n*n} pairs ({mismatch} mismatches)")