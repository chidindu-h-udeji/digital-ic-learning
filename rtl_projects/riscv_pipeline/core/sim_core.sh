#!/bin/bash
set -e

# Resolve paths and set working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SRAM_MODEL="${SKY130_SRAM_PATH:-$SCRIPT_DIR/../../../sky130_sram_macros/sky130_sram_1kbyte_1rw1r_32x256_8/sky130_sram_1kbyte_1rw1r_32x256_8.v}"

echo "=== 1. Behavioral Pipeline Test ==="
iverilog -g2012 -o sim_core_behav.vvp \
  riscv_core.sv \
  tb_riscv_core.sv \
  ../if_stage/pc_logic.sv \
  ../if_stage/instruction_memory.sv \
  ../if_stage/if_stage.sv \
  ../pipeline_regs/if_id_reg.sv \
  ../id_stage/control_unit.sv \
  ../id_stage/imm_gen.sv \
  ../id_stage/id_stage.sv \
  ../register_file/register_file.sv \
  ../pipeline_regs/id_ex_reg.sv \
  ../ex_stage/ex_stage.sv \
  ../pipeline_regs/ex_mem_reg.sv \
  ../mem_stage/data_memory.sv \
  ../mem_stage/mem_stage.sv \
  ../pipeline_regs/mem_wb_reg.sv \
  ../wb_stage/wb_stage.sv \
  ../hazard_unit/hazard_unit.sv \
  ../forwarding_unit/forwarding_unit.sv

# Capture output with timeout and fail CI if errors are present
output_behav=$(timeout 120 vvp sim_core_behav.vvp 2>&1)
echo "$output_behav"
if echo "$output_behav" | grep -q "ERROR"; then
  echo "Runner FAIL: Behavioral simulation encountered errors."
  exit 1
fi

echo ""
echo "=== 2. Hardened Macro Pipeline Test (__pnr__) ==="
if [ ! -f "$SRAM_MODEL" ]; then
    echo "ERROR: SRAM simulation model not found at $SRAM_MODEL"
    exit 1
fi

iverilog -g2012 -gno-specify -D__pnr__ -o sim_core_macro.vvp \
  riscv_core.sv \
  tb_riscv_core.sv \
  ../if_stage/pc_logic.sv \
  ../if_stage/instruction_memory.sv \
  ../if_stage/if_stage.sv \
  ../pipeline_regs/if_id_reg.sv \
  ../id_stage/control_unit.sv \
  ../id_stage/imm_gen.sv \
  ../id_stage/id_stage.sv \
  ../register_file/register_file.sv \
  ../pipeline_regs/id_ex_reg.sv \
  ../ex_stage/ex_stage.sv \
  ../pipeline_regs/ex_mem_reg.sv \
  ../mem_stage/data_memory.sv \
  ../mem_stage/mem_stage.sv \
  ../pipeline_regs/mem_wb_reg.sv \
  ../wb_stage/wb_stage.sv \
  ../hazard_unit/hazard_unit.sv \
  ../forwarding_unit/forwarding_unit.sv \
  "$SRAM_MODEL"

# Capture output with timeout and fail CI if errors are present
output_macro=$(timeout 120 vvp sim_core_macro.vvp 2>&1)
echo "$output_macro"
if echo "$output_macro" | grep -q "ERROR"; then
  echo "Runner FAIL: Macro simulation encountered errors."
  exit 1
fi