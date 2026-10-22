import random

def make_patterns(n, u, ug, groups=4, nib=5, seed=1):
    H = "0123456789abcdef"
    def rand(r): return ''.join(r.choice(H) for _ in range(nib))
    for attempt in range(200):
        r = random.Random(seed + attempt)
        cols = []
        for g in range(groups):
            if g < ug:                       # controlled group: u distinct values, repeated evenly
                pool = set()
                while len(pool) < u: pool.add(rand(r))
                pool = list(pool); r.shuffle(pool)
                col = [pool[k % u] for k in range(n)]
            else:                            # uncontrolled group: all distinct
                s = set()
                while len(s) < n: s.add(rand(r))
                col = list(s)
            r.shuffle(col)
            cols.append(col)
        pats = [''.join(cols[g][k] for g in range(groups)) for k in range(n)]
        if len(set(pats)) == n:
            return pats
    raise RuntimeError("could not build unique patterns")

def write_pir(pats, path):
    idw = len(pats).bit_length()
    with open(path, "w") as f:
        for k, p in enumerate(pats, 1):
            f.write(f"{p}   {idw}'d{k}\n")
