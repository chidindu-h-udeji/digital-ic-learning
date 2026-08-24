#!/bin/bash

# Compile only the design files and the top-level testbench
iverilog -g2012 -o sim_core.vvp \
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

# Run the simulation
vvp sim_core.vvp