from collections import deque


def check_mapping(H, G, phi):
    """Judge a mapping. Returns (ok, reason).

    H   : DFG, dict with 'kind' (list), 'succ' (list of lists), 'pred'
    G   : device graph from build_cgra
    phi : list; phi[x] is the SET of device vertices owned by DFG node x
    """
    n = len(H["kind"])

    # Rule 1a: every territory is non-empty
    for x in range(n):
        if not phi[x]:
            return False, f"rule 1: model of node {x} is empty"

    # Rule 1b: territories are pairwise disjoint (no vertex owned twice)
    owner = {}
    for x in range(n):
        for v in phi[x]:
            if v in owner:
                return False, (f"rule 1: device vertex {v} is used by both "
                               f"node {owner[v]} and node {x}")
            owner[v] = x

    # Rule 2: exactly one non-route vertex, of the node's kind; rest are route
    for x in range(n):
        typed = [v for v in phi[x] if G["kind"][v] != "route"]
        if len(typed) != 1:
            return False, (f"rule 2: node {x} has {len(typed)} compute "
                           f"vertices, needs exactly 1")
        if G["kind"][typed[0]] != H["kind"][x]:
            return False, (f"rule 2: node {x} needs a {H['kind'][x]} vertex "
                           f"but got {G['kind'][typed[0]]}")

    # Rule 3: each territory is weakly connected (ignore arrow direction,
    # use only edges whose both ends are inside the territory)
    for x in range(n):
        members = phi[x]
        start = next(iter(members))
        seen = {start}
        queue = deque([start])
        while queue:
            u = queue.popleft()
            for v in G["succ"][u] + G["pred"][u]:
                if v in members and v not in seen:
                    seen.add(v)
                    queue.append(v)
        if seen != members:
            return False, f"rule 3: model of node {x} is not connected"

    # Rule 4: for every DFG edge x->y there is a device edge u->v
    # with u in phi[x] and v in phi[y]. Direction matters.
    for x in range(n):
        for y in H["succ"][x]:
            if not any(v in phi[y] for u in phi[x] for v in G["succ"][u]):
                return False, (f"rule 4: DFG edge {x}->{y} has no device "
                               f"edge from model {x} into model {y}")

    return True, "ok"