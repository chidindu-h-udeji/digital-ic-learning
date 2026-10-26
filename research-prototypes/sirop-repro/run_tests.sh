#!/usr/bin/env bash
# run_tests.sh - rebuild the test vectors and rerun every result in this folder.
# Needs Python 3, Icarus Verilog 12 and Yosys 0.33. The last checks need GHDL 4.1
# and the authors' generated dot design (see README, "Reproducing"); they are
# skipped if either is missing.
set -euo pipefail
cd "$(dirname "$0")"
B=build; mkdir -p "$B"

sim() { iverilog -g2012 "$@" -o "$B/sim.vvp" && vvp -n "$B/sim.vvp" | grep -v '\$finish'; }

echo "== golden model"
python3 golden.py

echo "== dot, directed tests (unfused, then fused)"
sim tb/tb_dot.sv rtl/*.sv
sim -DFUSED tb/tb_dot.sv rtl/*.sv

echo "== dot, 200 random cases with input gaps and a random sink (unfused, then fused)"
sim tb/tb_dot_random.sv rtl/*.sv
sim -DFUSED tb/tb_dot_random.sv rtl/*.sv

echo "== dot, latency at N = 4 and N = 840"
for n in 4 840; do
    exp=$(python3 -c "from golden import dot; n=$n; print(dot([k%7+1 for k in range(n)], [k%5+1 for k in range(n)]))")
    sim -Ptb_dot_latency.N=$n -Ptb_dot_latency.EXPECT=$exp tb/tb_dot_latency.sv rtl/*.sv
    sim -DFUSED -Ptb_dot_latency.N=$n -Ptb_dot_latency.EXPECT=$exp tb/tb_dot_latency.sv rtl/*.sv
done

echo "== row-wise dot products with mid-stream stalls (unfused, then fused)"
sim tb/tb_stream.sv rtl/*.sv
sim -DFUSED tb/tb_stream.sv rtl/*.sv

echo "== row sum, Fig. 11 vs Fig. 12 side by side"
sim tb/tb_rowsum.sv rtl/*.sv

echo "== letstm[K] x = s in StmConcat(x, x), K = 1..5"
for k in 1 2 3 4 5; do sim -Ptb_letstm.K=$k tb/tb_letstm.sv rtl/*.sv; done

echo "== break-it: zip ready without '& can_step' (expected to FAIL)"
sed 's/assign p1_ready = READY_EXPR_P1 & can_step;/assign p1_ready = READY_EXPR_P1;/' \
    rtl/sb_zip.sv > "$B/sb_zip_mut.sv"
grep -q "assign p1_ready = READY_EXPR_P1;" "$B/sb_zip_mut.sv" || { echo "mutation not applied"; exit 1; }
sim tb/tb_dot_random.sv "$B/sb_zip_mut.sv" rtl/sb_map.sv rtl/sb_reduce.sv rtl/dot_unfused.sv | tail -1

# One mutant: copy rtl/, apply one sed edit to one file, run one testbench.
# $1 label, $2 file, $3 sed expression, $4 testbench, $5 extra iverilog flags (may be empty)
mutant() {
    rm -rf "$B/mut"; cp -r rtl "$B/mut"
    sed -i "$3" "$B/mut/$2"
    if cmp -s "rtl/$2" "$B/mut/$2"; then echo "$1: MUTATION NOT APPLIED"; return; fi
    local res
    res=$( { iverilog -g2012 $5 -o "$B/mut.vvp" "$4" "$B"/mut/*.sv && vvp -n "$B/mut.vvp"; } \
           | grep -E "^(PASS|FAIL)" | tail -1 || true )
    case "$res" in
        FAIL*) echo "$1: caught ($res)" ;;
        *)     echo "$1: SURVIVED ($res)" ;;
    esac
}
CS='s/assign can_step = arpv \& (send | ~out_valid);/assign can_step = arpv;/'
ACC='s/end else if (can_step) begin/end else if (can_step | send) begin/'
OUT='s/else if (can_step | send) begin/else if (can_step) begin/'
RDY='s/assign p_ready = READY_EXPR_P \& can_step;/assign p_ready = READY_EXPR_P;/'

echo "== mutants (each should be caught; survivors are listed, not hidden)"
{
    mutant "M1a zip: can_step = arpv (dot tests only)" sb_zip.sv "$CS" tb/tb_dot_random.sv ""
    mutant "M1a zip: can_step = arpv"                  sb_zip.sv "$CS" tb/tb_stream.sv ""
    mutant "M1b map: can_step = arpv"                  sb_map.sv "$CS" tb/tb_stream.sv ""
    mutant "M1c zipmap: can_step = arpv"               sb_zipmap.sv "$CS" tb/tb_stream.sv "-DFUSED"
    mutant "M2a rowsum12: accumulators on can_step | send" sb_rowsum12.sv "$ACC" tb/tb_stream.sv ""
    mutant "M2b reduce: accumulators on can_step | send"   sb_reduce.sv "$ACC" tb/tb_dot_random.sv ""
    mutant "M3a map: output registers on can_step only"    sb_map.sv "$OUT" tb/tb_stream.sv ""
    mutant "M3b rowsum12: output registers on can_step only" sb_rowsum12.sv "$OUT" tb/tb_stream.sv ""
    mutant "M4 rowsum12: p_ready without & can_step"       sb_rowsum12.sv "$RDY" tb/tb_stream.sv ""
} | tee tests/mutants.txt

yosys_count() {   # $1 top, $2 files to read
    yosys -q -p "read_verilog -sv $2; synth -top $1 -nofsm -flatten -lut 6; tee -q -o $B/yosys_$1.txt stat" > /dev/null
    local ff lut
    ff=$(grep -E '\$_.*DFF' "$B/yosys_$1.txt" | awk '{s += $2} END {print s}')
    lut=$(grep -E '\$lut' "$B/yosys_$1.txt" | awk '{print $2}')
    echo "$ff flip-flops, $lut LUTs"
}
echo "== Yosys counts (synth -nofsm -flatten -lut 6; each design reads only its own files)"
declare -A SRC=(
    [dot_unfused]="rtl/sb_zip.sv rtl/sb_map.sv rtl/sb_reduce.sv rtl/dot_unfused.sv"
    [dot_fused]="rtl/sb_zipmap.sv rtl/sb_reduce.sv rtl/dot_fused.sv"
    [sb_rowsum11]="rtl/sb_rowsum11.sv"
    [sb_rowsum12]="rtl/sb_rowsum12.sv"
)
for top in dot_unfused dot_fused sb_rowsum11 sb_rowsum12; do
    echo "$top: $(yosys_count $top "${SRC[$top]}")"
done
echo "== Yosys LUT spread: the same dot designs, reading every file in rtl/"
for top in dot_unfused dot_fused; do
    echo "$top (all of rtl/ read): $(yosys_count $top "rtl/*.sv")"
done

D=artifact/sirop-lctes26-artifact/sirop/src/test/vhdl/sirop/dot
if command -v ghdl > /dev/null && [ -d "$D/design" ]; then
    run_vhdl() {    # $1: folder holding the authors' design/ and test/
        local w="$PWD/$B/ghdl_$(basename "$1")"; mkdir -p "$w"
        (cd "$1" && ghdl -a --std=08 --workdir="$w" design/typedefs.vhd design/conversions.vhd \
            design/sbuild_1.vhd design/sbuild_2.vhd design/top.vhd test/test_top.vhd && \
         ghdl --elab-run --std=08 --workdir="$w" testbench --stop-time=10ms 2>&1) \
            | grep -E "LATENCY|Wrong|rror|Test done" || true
    }
    echo "== authors' generated dot (N = 840), authors' testbench"
    run_vhdl "$D"
    echo "== same design with first_step's only use replaced by acc + s (tests/first_step_removed.diff)"
    rm -rf "$B/dot_nofirst"; mkdir -p "$B/dot_nofirst"
    cp -r "$D/design" "$D/test" "$B/dot_nofirst/"
    patch -s "$B/dot_nofirst/design/sbuild_2.vhd" tests/first_step_removed.diff
    run_vhdl "$B/dot_nofirst" | tee tests/first_step_removed.txt
    echo "== negative control: acc + s + 1 (the authors' testbench should report Wrong data)"
    rm -rf "$B/dot_wrong"; mkdir -p "$B/dot_wrong"
    cp -r "$D/design" "$D/test" "$B/dot_wrong/"
    sed -i 's/ite_83 <= (s_75_data_internal) when (first_step_79) else ((acc_82) + (s_75_data_internal));/ite_83 <= (acc_82) + (s_75_data_internal) + 1;/' \
        "$B/dot_wrong/design/sbuild_2.vhd"
    grep -q "(acc_82) + (s_75_data_internal) + 1;" "$B/dot_wrong/design/sbuild_2.vhd" || { echo "control not applied"; exit 1; }
    run_vhdl "$B/dot_wrong" | tee tests/first_step_negative_control.txt
else
    echo "== artifact checks skipped (GHDL or generated dot design not found)"
fi