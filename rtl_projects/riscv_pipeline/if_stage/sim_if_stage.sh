#!/bin/bash
iverilog -g2012 -o sim_if_stage.vvp pc_logic.sv instruction_memory.sv if_stage.sv tb_if_stage.sv
vvp sim_if_stage.vvp
