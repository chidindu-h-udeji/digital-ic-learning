#!/bin/bash
iverilog -g2012 -o if_sim.out pc_logic.sv instruction_memory.sv if_stage.sv tb_if_stage.sv
vvp if_sim.out
