from collections import deque


def build_cgra(rows=5, cols=5):
    """Directed device graph. kind[v] in {'alu','route','io'}."""
    kind, name2id, succ = [], {}, []

    def add(name, k):
        name2id[name] = len(kind)
        kind.append(k)
        succ.append([])

    def edge(a, b):
        succ[name2id[a]].append(name2id[b])

    # 1) create the vertices
    for r in range(rows):
        for c in range(cols):
            add(f"alu_{r}_{c}", "alu")
            add(f"out_{r}_{c}", "route")
    for r in range(rows):
        for c in (0, cols - 1):
            add(f"io_{r}_{c}", "io")

    # 2) create the edges (one-way arrows)
    for r in range(rows):
        for c in range(cols):
            edge(f"alu_{r}_{c}", f"out_{r}_{c}")
            for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = f"{(r + dr) % rows}_{(c + dc) % cols}"
                edge(f"out_{q}", f"alu_{r}_{c}")   # neighbour's result feeds my ALU
                edge(f"out_{q}", f"out_{r}_{c}")   # route-through; my ALU stays idle
    for r in range(rows):
        for c in (0, cols - 1):
            edge(f"io_{r}_{c}", f"out_{r}_{c}")
            edge(f"out_{r}_{c}", f"io_{r}_{c}")

    # 3) predecessor lists (who points INTO each vertex)
    pred = [[] for _ in kind]
    for u, vs in enumerate(succ):
        for v in vs:
            pred[v].append(u)

    return dict(kind=kind, succ=succ, pred=pred, names=name2id)


def bfs_distances(succ, start):
    """Hop count from `start` to every reachable vertex."""
    dist = {start: 0}
    queue = deque([start])
    while queue:
        u = queue.popleft()
        for v in succ[u]:
            if v not in dist:
                dist[v] = dist[u] + 1
                queue.append(v)
    return dist


def diameter(G):
    """Longest of all shortest paths between reachable vertex pairs."""
    n = len(G["kind"])
    best = 0
    for s in range(n):
        d = bfs_distances(G["succ"], s)
        if len(d) < n:
            print(f"warning: vertex {s} cannot reach everything")
        best = max(best, max(d.values()))
    return best


if __name__ == "__main__":
    for size in (3, 5):
        G = build_cgra(size, size)
        n_vertices = len(G["kind"])
        n_edges = sum(len(s) for s in G["succ"])
        print(f"{size}x{size}: vertices={n_vertices}, edges={n_edges}, diameter D={diameter(G)}")