#!/usr/bin/env python3
"""gen_parser.py - pattern table -> SystemVerilog matcher + self-checking testbench."""
import argparse, random, sys
from pathlib import Path

def read_patterns(path):
    """Parse and validate patterns from the input text file."""
    pats = []
    for no, raw in enumerate(Path(path).read_text().splitlines(), 1):
        line = raw.split('#')[0].strip()
        if not line:
            continue
            
        parts = line.split()
        if len(parts) != 2:
            sys.exit(f"line {no}: expected '<pattern> <id>', got {raw!r}")
            
        pat, ident = parts[0].upper(), parts[1]
        
        # Ensure pattern contains valid hex characters or 'X' (don't care)
        if any(c not in "0123456789ABCDEFX" for c in pat):
            sys.exit(f"line {no}: bad character in pattern {pat!r}")
            
        # Ensure ID is a valid integer (0 is reserved for no match)
        if not ident.isdigit() or int(ident) < 1:
            sys.exit(f"line {no}: id must be an integer >= 1 (0 means no match)")
            
        pats.append((pat, int(ident)))
        
    if not pats:
        sys.exit("no patterns found")
    if len({len(p) for p, _ in pats}) != 1:
        sys.exit("all patterns must have the same length")
        
    return pats

def fixed_runs(pattern):
    """Group consecutive non-wildcard hex characters, skipping 'X' regions."""
    runs, i, n = [], 0, len(pattern)
    while i < n:
        if pattern[i] == 'X':
            i += 1
            continue
        j = i
        while j < n and pattern[j] != 'X':
            j += 1
        runs.append((i, pattern[i:j]))
        i = j
    return runs

def condition(pattern):
    """Generate SystemVerilog logical AND conditions for matching fixed nibbles."""
    width = 4 * len(pattern)
    terms = []
    for start, digits in fixed_runs(pattern):
        high = width - 1 - 4 * start
        low = width - 4 * (start + len(digits))
        terms.append(f"(data[{high}:{low}] == {4 * len(digits)}'h{digits})")
    return " && ".join(terms) if terms else "1'b1"

def emit_rtl(patterns):
    """Generate continuous assign logic (ternary operators) for the pattern matcher."""
    width = 4 * len(patterns[0][0])
    id_w = max(1, max(i for _, i in patterns).bit_length())
    
    o = ["module pattern_matching (",
         f"    input  logic [{width-1}:0] data,",
         f"    output logic [{id_w-1}:0] out_id",
         ");",
         f"    assign out_id = "]
         
    # Cascade ternary operators for each pattern (priority encoding)
    for pat, ident in patterns:
        o.append(f"        ({condition(pat)}) ? {id_w}'d{ident} :")
        
    # Default output is 0 if no match is found
    o.append(f"        {id_w}'d0;")
    o.append("endmodule")
    
    return "\n".join(o) + "\n", width, id_w

def matches(pat, data):
    """Software equivalent function to check if a specific pattern matches the data."""
    n = len(pat)
    for i, ch in enumerate(pat):
        if ch != 'X' and ((data >> (4 * (n - 1 - i))) & 0xF) != int(ch, 16):
            return False
    return True

def golden(patterns, data):
    """Software reference model: returns the expected ID for a given data vector."""
    for pat, ident in patterns:
        if matches(pat, data):
            return ident
    return 0

def make_vectors(patterns, seed=1, per_pattern=200, n_random=2000):
    """Generate a robust set of test vectors for the simulation."""
    rng = random.Random(seed)
    n = len(patterns[0][0])
    
    def fill(pat):
        v = 0
        for ch in pat:
            v = (v << 4) | (rng.randrange(16) if ch == 'X' else int(ch, 16))
        return v
        
    vecs = []
    for pat, _ in patterns:
        fixed = [i for i, c in enumerate(pat) if c != 'X']
        for _ in range(per_pattern):
            good = fill(pat)
            vecs.append(good)
            
            # Create a near-miss vector by corrupting one valid nibble
            if fixed:
                i = rng.choice(fixed)
                vecs.append(good ^ (rng.randrange(1, 16) << (4 * (n - 1 - i))))
                
    # Append fully random vectors to catch edge cases
    vecs += [rng.getrandbits(4 * n) for _ in range(n_random)]
    return vecs

TB = """`timescale 1ns/1ps
module tb_pattern_matching;
    localparam int W = __W__;
    localparam int ID_W = __IDW__;
    localparam int N = __N__;
    
    logic [W-1:0] data;
    logic [ID_W-1:0] out_id, expected;
    logic [W+ID_W-1:0] vec [0:N-1];
    logic [W+ID_W-1:0] v;
    int mismatches;
    
    pattern_matching dut (.data(data), .out_id(out_id));
    
    initial begin
        $readmemh("__MEM_PATH__", vec);
        mismatches = 0;
        
        for (int i = 0; i < N; i++) begin
            v = vec[i];
            data = v[W+ID_W-1:ID_W];
            expected = v[ID_W-1:0];
            #1;
            
            // Verify DUT output matches the software-generated expected value
            if (out_id !== expected) begin
                mismatches++;
                $display("MISMATCH vec %0d: data=%h got=%0d expected=%0d", i, data, out_id, expected);
            end
        end
        
        if (mismatches == 0) $display("PASS: %0d vectors, 0 mismatches", N);
        else $display("FAIL: %0d mismatches out of %0d", mismatches, N);
        $finish;
    end
endmodule
"""

def main():
    """Parse inputs, write the RTL module, and generate the testbench/vectors."""
    ap = argparse.ArgumentParser()
    ap.add_argument("patterns")
    ap.add_argument("-o", "--outdir", default="build")
    a = ap.parse_args()
    
    pats = read_patterns(a.patterns)
    out = Path(a.outdir)
    out.mkdir(parents=True, exist_ok=True)
    
    # 1. Output the RTL file
    rtl, width, id_w = emit_rtl(pats)
    (out / "pattern_matching.sv").write_text(rtl)
    
    # 2. Generate test vectors
    vecs = make_vectors(pats)
    digits = (width + id_w + 3) // 4
    with open(out / "vectors.mem", "w") as f:
        for d in vecs:
            f.write(f"{((d << id_w) | golden(pats, d)):0{digits}x}\n")
            
    # 3. Output the Testbench with the dynamically injected memory file path
    mem_path = str(out / "vectors.mem")
    tb = (TB.replace("__W__", str(width))
            .replace("__IDW__", str(id_w))
            .replace("__N__", str(len(vecs)))
            .replace("__MEM_PATH__", mem_path))
            
    (out / "tb_pattern_matching.sv").write_text(tb)
    print(f"wrote {out}/ : {len(pats)} patterns, {width} bits, {len(vecs)} vectors")

if __name__ == "__main__":
    main()