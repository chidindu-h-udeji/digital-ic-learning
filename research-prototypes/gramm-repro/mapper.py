import random

from checker import check_mapping
from device import diameter
from dijkstra import dijkstra, trace


# ----------------------------------------------------------------------
# Piece 1: find a territory (vertex model) for ONE DFG node  (Algorithm 1)
# ----------------------------------------------------------------------
def find_vertex_model(x, H, G, phi, w, rng, fanin=True, audit=None,
                      rand_best=False):
    """Return a new vertex model (a set) for DFG node x.

    phi[x] must already be EMPTY (x's old model removed) when this is called.
    fanin : enforce the fan-in rule (paths from different producers into x
            must not share routing vertices)
    audit : optional list; if given, (x, [fan-in paths]) is appended to it,
            so tests can inspect the paths that were actually used
    rand_best : RAND_BEST - when a root TIES the best cost so far, flip a coin
            and take it with probability 1/2 (not uniform sampling!)
    """
    producers = [p for p in H["pred"][x] if phi[p]]   # feed x   (fan-in side)
    consumers = [c for c in H["succ"][x] if phi[c]]   # x feeds  (fan-out side)
    wanted = H["kind"][x]
    roots = [v for v in range(len(G["kind"])) if G["kind"][v] == wanted]

    # Algorithm 1, lines 1-2: no neighbour has a model yet -> random root
    if not producers and not consumers:
        return {rng.choice(roots)}

    # One Dijkstra per neighbour model gives the cost to EVERY candidate root
    prod_search, cons_search = [], []   # (neighbour model, dist, parent)
    for p in producers:
        dist, parent = dijkstra(G, w, phi[p], reverse=False)
        prod_search.append((phi[p], dist, parent))
    for c in consumers:
        dist, parent = dijkstra(G, w, phi[c], reverse=True)
        cons_search.append((phi[c], dist, parent))
    searches = prod_search + cons_search
    k = len(searches)

    # Algorithm 1, lines 4-13: score every root (in vertex-id order)
    scored = []
    for g in roots:
        total, reachable = 0, True
        for model, dist, _ in searches:
            if g in model:
                total += w[g]                  # line 7-8: g already inside it
            elif g in dist:
                total += dist[g]               # includes w[g] (entering g)
            else:
                reachable = False              # no directed path: skip root
                break
        if reachable:
            # root's weight counted once; round so float ties compare equal
            scored.append((round(total - (k - 1) * w[g], 9), g))

    # Pick the primary root by streaming through the candidates:
    #   BASELINE  : keep the FIRST minimum
    #   RAND_BEST : on a tie, replace the current best with probability 1/2
    best = None
    for cost, g in scored:
        if best is None or cost < best[0]:
            best = (cost, g)
        elif rand_best and cost == best[0] and rng.random() < 0.5:
            best = (cost, g)
    # if the primary root cannot host all inputs, fall back to the others,
    # cheapest first (ties: lowest id)
    candidates = []
    if best is not None:
        candidates = [best[1]] + [g for _, g in sorted(scored) if g != best[1]]

    # Try roots from cheapest to dearest until the fan-in paths can be routed
    for g in candidates:
        fanin_paths = route_fanin(g, G, w, prod_search, fanin)
        if fanin_paths is None:
            continue                            # this root cannot host all inputs
        model = {g}
        for path in fanin_paths:                # line 14: root + paths in
            model.update(path[:-1])             # drop the producer's own vertex
        for nbr_model, dist, parent in cons_search:   # ... and paths out (may merge)
            if g in nbr_model:
                continue
            model.update(trace(parent, g)[:-1])
        if audit is not None:
            audit.append((x, fanin_paths))
        return model

    return {rng.choice(roots)}                  # nothing works: random root


def route_fanin(g, G, w, prod_search, fanin):
    """Choose one path from each producer's model into root g.

    With fanin=True the paths are found one at a time, and the routing
    vertices of every finished path are blocked for the next one, so no two
    inputs share a wire. Returns a list of paths [g, ..., vertex-in-producer],
    or None if the inputs cannot be routed disjointly.
    """
    paths, used = [], set()
    for nbr_model, dist, parent in prod_search:
        if g in nbr_model:
            continue                            # overlap case: no path needed
        if not used or not fanin:
            path = trace(parent, g)             # unblocked search is enough
        else:
            d2, p2 = dijkstra(G, w, nbr_model, blocked=used)
            if g not in d2:
                return None                     # blocked everywhere: give up
            path = trace(p2, g)
        paths.append(path)
        used.update(path[1:-1])                 # block this path's routing vertices
    return paths


# ----------------------------------------------------------------------
# Piece 2: bookkeeping helpers
# ----------------------------------------------------------------------
def total_overlap(phi, n_dev):
    """How many 'extra' owners exist: sum over vertices of max(0, owners-1)."""
    cnt = [0] * n_dev
    for model in phi:
        for v in model:
            cnt[v] += 1
    return sum(c - 1 for c in cnt if c > 1)


# ----------------------------------------------------------------------
# Piece 3: the outer loop  (Algorithm 2)
# ----------------------------------------------------------------------
VARIANTS = {   # name: (rand_best, pathfinder, sort)   -- each layer adds to the last
    "BASELINE":        (False, False, False),
    "RAND_BEST":       (True,  False, False),
    "PATHFINDER":      (True,  True,  False),
    "PATHFINDER_SORT": (True,  True,  True),
}


def map_dfg(H, G, variant="BASELINE", seed=0, patience=10, max_iters=100,
            fanin=True, log=None):
    """returns (success, phi, iterations)

    log : optional list; one dict per finished pass is appended (for tests)
    """
    rand_best, pathfinder, sort_nodes = VARIANTS[variant]

    rng = random.Random(seed)
    n, n_dev = len(H["kind"]), len(G["kind"])
    if "D" not in G:
        G["D"] = diameter(G)
    D = G["D"]

    order = list(range(n))
    rng.shuffle(order)                          # Algorithm 2, line 1
    phi = [set() for _ in range(n)]             # line 2
    count = [0] * n_dev                         # count[v] = |S(v)|
    P = 1.0                                     # PathFinder: present penalty
    hist = [0] * n_dev                          # PathFinder: history H(g)

    best_measure, stale = None, 0
    for it in range(1, max_iters + 1):          # line 3
        if sort_nodes and it > 1:               # SORT: biggest models first,
            keys = {x: (-len(phi[x]), rng.random()) for x in range(n)}
            order = sorted(range(n), key=lambda x: keys[x])   # random tie-break
        P_used = P
        for x in order:                         # line 4
            for v in phi[x]:                    # DECISION: remove x's old model
                count[v] -= 1                   #   before counting S(g)
            phi[x] = set()
            if pathfinder:                      # eqn (2)
                w = [(1 + count[v]) * P * (1 + hist[v]) for v in range(n_dev)]
            else:                               # eqn (1)
                w = [D ** c for c in count]
            phi[x] = find_vertex_model(x, H, G, phi, w, rng, fanin,
                                       rand_best=rand_best)       # line 8
            for v in phi[x]:
                count[v] += 1

        overlap = total_overlap(phi, n_dev)     # lines 10-12
        overused = [v for v in range(n_dev) if count[v] > 1]
        if overlap == 0:
            ok, _ = check_mapping(H, G, phi)
            if ok:
                if log is not None:
                    log.append(dict(it=it, P=P_used, order=list(order),
                                    sizes=[len(m) for m in phi],
                                    overused=overused, hist=list(hist)))
                return True, phi, it
            measure = 1        # no overlap but still illegal: count as 1 problem
        else:
            measure = overlap

        if pathfinder:                          # after each pass: P *= 1.1,
            P *= 1.1                            #   H += 1 on overused vertices
            for v in overused:
                hist[v] += 1
        if log is not None:
            log.append(dict(it=it, P=P_used, order=list(order),
                            sizes=[len(m) for m in phi],
                            overused=overused, hist=list(hist)))

        if best_measure is None or measure < best_measure:
            best_measure, stale = measure, 0
        else:
            stale += 1
            if stale >= patience:
                break
    return False, phi, it