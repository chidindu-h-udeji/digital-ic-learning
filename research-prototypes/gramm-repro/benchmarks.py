"""Benchmark DFGs. Node kinds: 'io' (input/output pad) and 'alu' (operation).

Every DFG is a dict with 'kind', 'succ', 'pred' (same shape as the checker
expects). Random DAGs use FIXED seeds, so the benchmark set never changes.
"""
import random


class _Builder:
    def __init__(self):
        self.kind, self.edges = [], []

    def node(self, k):
        self.kind.append(k)
        return len(self.kind) - 1

    def edge(self, a, b):
        self.edges.append((a, b))

    def build(self):
        n = len(self.kind)
        succ = [[] for _ in range(n)]
        pred = [[] for _ in range(n)]
        for a, b in self.edges:
            succ[a].append(b)
            pred[b].append(a)
        return dict(kind=self.kind, succ=succ, pred=pred)


def chain(n_alu):
    """in -> alu -> alu -> ... -> out"""
    b = _Builder()
    prev = b.node("io")
    for _ in range(n_alu):
        a = b.node("alu"); b.edge(prev, a); prev = a
    o = b.node("io"); b.edge(prev, o)
    return b.build()


def reduction_tree(n_in):
    """n_in inputs summed pairwise by a balanced tree of adders -> one output"""
    b = _Builder()
    level = [b.node("io") for _ in range(n_in)]
    while len(level) > 1:
        nxt = []
        for i in range(0, len(level) - 1, 2):
            a = b.node("alu"); b.edge(level[i], a); b.edge(level[i + 1], a)
            nxt.append(a)
        if len(level) % 2:
            nxt.append(level[-1])
        level = nxt
    o = b.node("io"); b.edge(level[0], o)
    return b.build()


def broadcast_tree(depth):
    """one input fans out through a binary tree of ops to 2**depth outputs"""
    b = _Builder()
    root = b.node("io")
    level = [root]
    for _ in range(depth):
        nxt = []
        for p in level:
            for _ in range(2):
                a = b.node("alu"); b.edge(p, a); nxt.append(a)
        level = nxt
    for p in level:
        o = b.node("io"); b.edge(p, o)
    return b.build()


def mac(n_terms, const_weights):
    """multiply-accumulate: sum_i x_i * w_i, accumulated in a chain.
    const_weights=True: weights are constants (one unary multiply per input);
    False: weights come from inputs too (two inputs per multiply)."""
    b = _Builder()
    prods = []
    for _ in range(n_terms):
        x = b.node("io")
        m = b.node("alu"); b.edge(x, m)
        if not const_weights:
            wgt = b.node("io"); b.edge(wgt, m)
        prods.append(m)
    acc = prods[0]
    for p in prods[1:]:
        a = b.node("alu"); b.edge(acc, a); b.edge(p, a); acc = a
    o = b.node("io"); b.edge(acc, o)
    return b.build()


def diamonds(n):
    """stack of n diamonds: split into two ops, then join (reconvergent fan-out)"""
    b = _Builder()
    prev = b.node("io")
    for _ in range(n):
        l, r = b.node("alu"), b.node("alu")
        j = b.node("alu")
        b.edge(prev, l); b.edge(prev, r); b.edge(l, j); b.edge(r, j)
        prev = j
    o = b.node("io"); b.edge(prev, o)
    return b.build()


def random_dag(n_in, n_alu, max_out, seed):
    """Random DAG, every ALU has fan-in 1 or 2, every input is used, and
    leftover sinks are merged until at most max_out outputs remain."""
    rng = random.Random(seed)
    b = _Builder()
    ins = [b.node("io") for _ in range(n_in)]
    pool, unused_in = list(ins), list(ins)
    alus = []
    for _ in range(n_alu):
        a = b.node("alu")
        fan = 1 if rng.random() < 0.25 else 2
        preds = []
        while unused_in and len(preds) < fan:            # use every input early
            preds.append(unused_in.pop(rng.randrange(len(unused_in))))
        recent = pool[-6:]                               # prefer recent nodes
        while len(preds) < fan:
            c = rng.choice(recent if rng.random() < 0.7 else pool)
            if c not in preds:
                preds.append(c)
        for p in preds:
            b.edge(p, a)
        pool.append(a); alus.append(a)
    has_succ = {a for a, _ in b.edges}
    sinks = [a for a in alus if a not in has_succ]
    while len(sinks) > max_out:                          # merge two sinks
        x, y = sinks.pop(), sinks.pop()
        m = b.node("alu"); b.edge(x, m); b.edge(y, m); sinks.append(m)
    for s in sinks:
        o = b.node("io"); b.edge(s, o)
    return b.build()


# name -> DFG.  Sizes are 8..40 nodes, as in the paper's 6..43.
BENCHMARKS = {
    "chain8":       chain(6),
    "chain20":      chain(18),
    "reduce4":      reduction_tree(4),
    "reduce8":      reduction_tree(8),
    "bcast2":       broadcast_tree(2),
    "bcast3":       broadcast_tree(3),
    "mac_const6":   mac(6, True),
    "mac4":         mac(4, False),
    "diamonds4":    diamonds(4),
    "diamonds7":    diamonds(7),
    "rand_a":       random_dag(3, 10, 3, seed=11),
    "rand_b":       random_dag(4, 16, 3, seed=22),
    "rand_c":       random_dag(5, 22, 4, seed=33),
    "rand_d":       random_dag(5, 25, 4, seed=44),
}


# ---------------------------------------------------------------------------
# FROZEN after calibration (calibrate.py, BASELINE only, seeds 10000-10039).
# Rule: the smallest square grid on which all 14 benchmarks fit (enough ALUs
# and io pads). On it the baseline averages 28%: not 0%, not 100%.
# Do NOT change these after seeing PathFinder results.
# ---------------------------------------------------------------------------
GRID_ROWS = GRID_COLS = 6

# Declared BEFORE the experiment, from baseline calibration only: the benchmarks
# where the baseline succeeded at least once on 6x6. Reported as a secondary
# view; the primary view always uses all 14.
BASELINE_SOLVABLE = ["chain8", "chain20", "reduce4", "reduce8",
                     "bcast2", "mac_const6", "mac4", "diamonds4"]


def validate():
    """Raise if any benchmark breaks the size / fan-in / acyclic rules."""
    for name, d in BENCHMARKS.items():
        n, _, _, fan_in, _ = describe(d)
        assert 8 <= n <= 40, f"{name}: {n} nodes is outside 8..40"
        assert fan_in <= 2, f"{name}: fan-in {fan_in} > 2"
        assert is_acyclic(d), f"{name}: has a cycle"
    return True


def describe(dfg):
    n = len(dfg["kind"])
    n_io = dfg["kind"].count("io")
    fan_in = max((len(p) for p in dfg["pred"]), default=0)
    fan_out = max((len(s) for s in dfg["succ"]), default=0)
    return n, n_io, n - n_io, fan_in, fan_out


def is_acyclic(dfg):
    indeg = [len(p) for p in dfg["pred"]]
    stack = [v for v, d in enumerate(indeg) if d == 0]
    seen = 0
    while stack:
        u = stack.pop(); seen += 1
        for v in dfg["succ"][u]:
            indeg[v] -= 1
            if indeg[v] == 0:
                stack.append(v)
    return seen == len(indeg)


if __name__ == "__main__":
    validate()
    print(f"{'benchmark':<12}{'nodes':>6}{'io':>5}{'alu':>5}{'max fan-in':>12}{'max fan-out':>13}{'acyclic':>9}")
    for name, d in BENCHMARKS.items():
        n, n_io, n_alu, fi, fo = describe(d)
        print(f"{name:<12}{n:>6}{n_io:>5}{n_alu:>5}{fi:>12}{fo:>13}{str(is_acyclic(d)):>9}")