#!/bin/bash
iverilog -g2012 -o sim_imem.vvp instruction_memory.sv tb_instruction_memory.sv
vvp sim_imem.vvp
