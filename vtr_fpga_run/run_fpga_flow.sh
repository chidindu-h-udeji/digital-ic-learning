#!/bin/bash
set -e

# Configuration: defaults to the merged RTL commit but allows overrides for negative testing
COMMIT="${COMMIT:-3cb4f903adfc1562b1d81e761eea5af3b471e4dc}"
WORK_DIR="/tmp/fpga_flow_run"
VTR_ROOT="$HOME/vtr-verilog-to-routing"
ARCH_FILE="$VTR_ROOT/vtr_flow/arch/timing/EArch.xml"

echo "=== VTR FPGA Flow Build Script ==="
echo "Commit: $COMMIT"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "1. Extracting RTL from commit..."
git archive --format=tar "$COMMIT" rtl_projects/riscv_pipeline | tar -x -C "$WORK_DIR"

MERGED_RTL="$WORK_DIR/riscv_core_merged.sv"
> "$MERGED_RTL"
for f in $(find "$WORK_DIR/rtl_projects/riscv_pipeline" -name "*.sv" -not -name "tb_*.sv"); do
    cat "$f" >> "$MERGED_RTL"
    echo "" >> "$MERGED_RTL"
done

echo "2. Applying literal-initialization & anti-specialization workaround..."
LITERAL_RTL="$WORK_DIR/riscv_core_literal.sv"
cp "$MERGED_RTL" "$LITERAL_RTL"

python3 - "$LITERAL_RTL" "$WORK_DIR/rtl_projects/riscv_pipeline/core" << 'PY_EOF'
import re, sys, os
rtl_file = sys.argv[1]
core_dir = sys.argv[2]
rtl = open(rtl_file).read()

for name in ('program.hex', 'data_mem_init.hex'):
    hex_path = os.path.join(core_dir, name)
    with open(hex_path) as f:
        vals = [l.split("//")[0].strip().replace("_", "") for l in f]
        vals = [v for v in vals if v]
    
    # Pad memory to 256 words
    while len(vals) < 256:
        vals.append("00000000")
        
    if name == 'program.hex':
        # Validate core program hex is loaded
        if vals[0] != "00500093":
            print(f"ERROR: Incorrect program.hex loaded. Expected 00500093, got {vals[0]}")
            sys.exit(1)
        # Inject dummy instruction to prevent constant-column logic sweeping
        vals[-1] = "FFFFFFFF"
    
    assigns = [f"    mem[{i}] = 32'h{val};" for i, val in enumerate(vals)]
    pat = re.compile(r'\$readmemh\("[^"]*'+re.escape(name)+r'",\s*mem\);')
    rtl, count = pat.subn("\n".join(assigns), rtl)
    
    if count == 0:
        print(f"ERROR: Could not find $readmemh for {name}")
        sys.exit(1)

open(rtl_file, "w").write(rtl)
PY_EOF

READMEMH_CNT=$(grep -c 'readmemh' "$LITERAL_RTL" || true)
LITERAL_CNT=$(grep -c -E "mem\[[0-9]+\] = 32'h" "$LITERAL_RTL" || true)

if [ "$READMEMH_CNT" -ne 0 ] || [ "$LITERAL_CNT" -ne 512 ]; then
    echo "ERROR: Literal check failed (readmemh: $READMEMH_CNT, literals: $LITERAL_CNT)"
    exit 1
fi
echo "Literal check passed: 0 readmemh, 512 literals."

echo "3. Running Testbench Gate..."
TB_FILE="$WORK_DIR/rtl_projects/riscv_pipeline/core/tb_riscv_core.sv"
if ! iverilog -g2012 -o "$WORK_DIR/tb_sim.vvp" "$LITERAL_RTL" "$TB_FILE" > "$WORK_DIR/tb_comp.log" 2>&1; then
    echo "ERROR: Compilation failed."
    tail -n 15 "$WORK_DIR/tb_comp.log"
    exit 1
fi

vvp "$WORK_DIR/tb_sim.vvp" > "$WORK_DIR/tb.log" 2>&1

# Verify exact cycle count and zero errors
if ! grep -q "VERIFICATION PASSED! Errors: 0" "$WORK_DIR/tb.log" || ! grep -q "Total Active Cycles : 17" "$WORK_DIR/tb.log"; then
    echo "ERROR: Testbench failed or did not match the 17-cycle baseline."
    tail -n 15 "$WORK_DIR/tb.log"
    exit 1
fi
echo "Testbench Gate PASSED."

echo "4. Running VTR Synthesis & Routing..."
python3 $VTR_ROOT/vtr_flow/scripts/run_vtr_flow.py "$LITERAL_RTL" "$ARCH_FILE" \
    -temp_dir "$WORK_DIR/vtr_out" \
    -top riscv_core \
    -parser slang \
    --route_chan_width 300 > "$WORK_DIR/vtr_flow.log" 2>&1

echo "VTR Run Complete. Key Metrics:"
grep -E "^ +(io|clb|fle|memory|mem_[0-9a-z_]+|lut4|lut5|lut6|ff|adder) +: [0-9]+" "$WORK_DIR/vtr_out/vpr_stdout.log" | head -20
grep -E "Final critical path delay|Fmax|Device Utilization|successfully routed|FPGA sized" "$WORK_DIR/vtr_out/vpr_stdout.log" | head -10
