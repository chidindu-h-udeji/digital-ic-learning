"""golden.py - plain-Python reference model for sirop-repro.

Expected values come from the paper (Fig. 7, Fig. 11), not from any RTL.
Overflow: u16 wrapping (*%, +%) is not assumed here; check_no_overflow()
rejects any input that would overflow, so no test depends on it.
"""
import random
from pathlib import Path

U16_MAX = 0xFFFF


def check_no_overflow(*values):
    """Raise if any value does not fit in an unsigned 16-bit number."""
    for v in values:
        if not 0 <= v <= U16_MAX:
            raise ValueError(f"{v} does not fit in u16")


def dot(a, b):
    """Fig. 4: pair the two streams, multiply each pair, add the products."""
    if len(a) != len(b):
        raise ValueError("streams must be the same length")
    total = 0
    for x, y in zip(a, b):
        p = x * y
        total += p
        check_no_overflow(x, y, p, total)
    return total


def row_sums(rows):
    """Expression (1): add up each row of a 2-D stream."""
    out = []
    for row in rows:
        s = 0
        for x in row:
            s += x
            check_no_overflow(x, s)
        out.append(s)
    return out


def write_dot_vectors(path, count=200, n=4, seed=1, max_val=127):
    """Test cases for tb_dot_random: one hex line per case holding
    a[0..n-1], b[0..n-1] and the expected result, 16 bits each.
    The first case is Fig. 7. Values <= 127 keep every product and sum
    below 2^16 for n = 4."""
    rng = random.Random(seed)
    cases = [([1, 2, 3, 4], [5, 6, 7, 8])]
    while len(cases) < count:
        cases.append(([rng.randint(0, max_val) for _ in range(n)],
                      [rng.randint(0, max_val) for _ in range(n)]))
    lines = ["".join(f"{w:04x}" for w in a + b + [dot(a, b)]) for a, b in cases]
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text("\n".join(lines) + "\n")
    return len(lines)


def write_rowsum_vectors(in_path, out_path, rows=100, r=3, seed=2, max_val=255):
    """Test stream for tb_rowsum: the input values one per line, and the
    expected row sums one per line (16-bit hex). The first three rows are
    the paper's example (Fig. 11): sums 6, 36, 66."""
    rng = random.Random(seed)
    grid = [[1, 2, 3], [11, 12, 13], [21, 22, 23]]
    while len(grid) < rows:
        grid.append([rng.randint(0, max_val) for _ in range(r)])
    Path(in_path).parent.mkdir(parents=True, exist_ok=True)
    Path(in_path).write_text("".join(f"{x:04x}\n" for row in grid for x in row))
    Path(out_path).write_text("".join(f"{s:04x}\n" for s in row_sums(grid)))
    return len(grid)


def write_rowdot_vectors(in_path, out_path, rows=100, r=3, seed=3, max_val=127):
    """Test stream for tb_stream: row-wise dot products of two streams.
    Input: one line per element pair, {a, b} as 8 hex digits. Output: one
    expected dot product per row of r pairs (16-bit hex). Values <= 127 keep
    each product and row sum below 2^16 for r = 3."""
    rng = random.Random(seed)
    a = [rng.randint(0, max_val) for _ in range(rows * r)]
    b = [rng.randint(0, max_val) for _ in range(rows * r)]
    Path(in_path).parent.mkdir(parents=True, exist_ok=True)
    Path(in_path).write_text("".join(f"{x:04x}{y:04x}\n" for x, y in zip(a, b)))
    sums = [dot(a[i:i + r], b[i:i + r]) for i in range(0, rows * r, r)]
    Path(out_path).write_text("".join(f"{s:04x}\n" for s in sums))
    return rows


if __name__ == "__main__":
    assert dot([1, 2, 3, 4], [5, 6, 7, 8]) == 70                              # Fig. 7
    assert row_sums([[1, 2, 3], [11, 12, 13], [21, 22, 23]]) == [6, 36, 66]   # Fig. 11
    print("golden.py: paper values reproduced (70; 6, 36, 66)")
    n = write_dot_vectors("build/dot_vectors.mem")
    print(f"golden.py: wrote {n} cases to build/dot_vectors.mem")
    n = write_rowsum_vectors("build/rowsum_in.mem", "build/rowsum_out.mem")
    print(f"golden.py: wrote {n} rows to build/rowsum_in.mem and build/rowsum_out.mem")
    n = write_rowdot_vectors("build/rowdot_in.mem", "build/rowdot_out.mem")
    print(f"golden.py: wrote {n} rows to build/rowdot_in.mem and build/rowdot_out.mem")