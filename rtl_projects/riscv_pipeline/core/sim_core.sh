#!/bin/bash

# Compile only the design files and the top-level testbench
iverilog -g2012 -o sim_core.vvp \
  riscv_core.sv \
  tb_riscv_core.sv \
  ../fetch_stage/pc_logic.sv \
  ../fetch_stage/instruction_memory.sv \
  ../fetch_stage/if_stage.sv \
  ../decode_stage/if_id_register.sv \
  ../decode_stage/control_unit.sv \
  ../decode_stage/imm_gen.sv \
  ../decode_stage/id_stage.sv \
  ../register_file/register_file.sv \
  ../pipeline_regs/id_ex_reg.sv \
  ../execute/ex_stage.sv \
  ../pipeline_regs/ex_mem_reg.sv \
  ../mem_stage/data_memory.sv \
  ../mem_stage/mem_stage.sv \
  ../pipeline_regs/mem_wb_reg.sv \
  ../wb_stage/wb_stage.sv \
  ../hazard_unit/hazard_unit.sv \
  ../forwarding_unit/forwarding_unit.sv

# Run the simulation
vvp sim_core.vvp