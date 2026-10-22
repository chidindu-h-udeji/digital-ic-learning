# Simulation Evidence
The SystemVerilog output of `gen_parser.py` was simulated with Icarus Verilog 12.0 (Ubuntu package `iverilog 12.0-2build2`) against a directed and random testbench (2,800 vectors: 2 patterns × 200 × (one matching vector + one near-miss) = 800, plus 2,000 random).

### 1. Successful Pass (Golden Match)
Ran on `patterns.txt`:
```text
x08xxx6 1
1FxxAxx 2
```
These are the two patterns from the paper's Fig. 2 example (Section III-A).
```text
PASS: 2800 vectors, 0 mismatches
build/tb_pattern_matching.sv:34: $finish called at 2800000 (1ps)
```

### 2. The "Break-It" Test
To prove the testbench catches logic failures, one bit of the expected ID for the first vector in `vectors.mem` was flipped. The testbench caught it:
```text
MISMATCH vec 0: data=4082836 got=1 expected=0
FAIL: 1 mismatches out of 2800
build/tb_pattern_matching.sv:34: $finish called at 2800000 (1ps)
```

### 3. Overlap Priority
Ran on `patterns_overlap.txt`, where the second pattern is fully covered by the first:
```text
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXA 1
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXAA 2
```
The generated cascaded-ternary logic and the Python reference model both resolve overlaps to the first listed pattern, and they agree on all vectors:
```text
PASS: 2800 vectors, 0 mismatches
build_overlap/tb_pattern_matching.sv:34: $finish called at 2800000 (1ps)
```
This checks that the RTL and the reference model share one priority rule (first listed wins), which is also the rule the paper specifies in Section III-A: patterns are prioritized by specification order and only the first match is output.