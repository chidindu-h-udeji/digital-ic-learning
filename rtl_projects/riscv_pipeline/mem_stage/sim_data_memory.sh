#!/bin/bash
set -e

# Automatically find the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the path relative to the script location (3 levels up to digital-ic-learning)
SRAM_MODEL="${SKY130_SRAM_PATH:-$SCRIPT_DIR/../../../sky130_sram_macros/sky130_sram_1kbyte_1rw1r_32x256_8/sky130_sram_1kbyte_1rw1r_32x256_8.v}"

echo "=== 1. Behavioral Model Test ==="
cd "$SCRIPT_DIR"
iverilog -g2012 -o sim_behav.vvp data_memory.sv tb_data_memory.sv
vvp sim_behav.vvp

echo ""
echo "=== 2. Hardened Macro Test (__pnr__) ==="
if [ ! -f "$SRAM_MODEL" ]; then
    echo "ERROR: SRAM simulation model not found at $SRAM_MODEL"
    echo "Set SKY130_SRAM_PATH or check your folder structure."
    exit 1
fi

iverilog -g2012 -gno-specify -D__pnr__ -o sim_macro.vvp \
  data_memory.sv \
  tb_data_memory.sv \
  "$SRAM_MODEL"
vvp sim_macro.vvp