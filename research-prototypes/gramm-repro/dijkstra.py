import heapq

INF = float("inf")


def dijkstra(G, w, sources, reverse=False, blocked=frozenset()):
    """Multi-source Dijkstra on a VERTEX-weighted directed graph.

    G       : device graph (needs 'kind', 'succ', 'pred')
    w       : list, w[v] = cost of entering vertex v
    sources : iterable of vertex ids; they start at distance 0
    blocked : vertices that may not be entered at all (used by the fan-in rule)
    reverse : False -> follow arrows forward  (sources produce, we look for
                       vertices that can RECEIVE from them: fan-in side)
              True  -> follow arrows backwards (sources consume, we look for
                       vertices that can SEND to them: fan-out side)

    Rules:
      * entering a vertex costs w[v]; sources cost 0
      * a typed vertex (alu/io) can be REACHED but never passed THROUGH,
        unless it is itself a source

    Returns (dist, parent). Unreached vertices are simply absent from dist.
    """
    adj = G["pred"] if reverse else G["succ"]
    kind = G["kind"]
    src = set(sources)

    dist = {s: 0 for s in src}
    parent = {s: None for s in src}
    heap = [(0, s) for s in src]
    heapq.heapify(heap)

    while heap:
        d, u = heapq.heappop(heap)
        if d > dist[u]:
            continue                      # stale heap entry
        if kind[u] != "route" and u not in src:
            continue                      # typed vertex: reached, not expanded
        for v in adj[u]:
            if v in src or v in blocked:
                continue                  # already at cost 0 / forbidden
            nd = d + w[v]
            if nd < dist.get(v, INF):
                dist[v] = nd
                parent[v] = u
                heapq.heappush(heap, (nd, v))
    return dist, parent


def trace(parent, v):
    """Follow parents from v back to a source: [v, ..., source]."""
    path = []
    while v is not None:
        path.append(v)
        v = parent[v]
    return path