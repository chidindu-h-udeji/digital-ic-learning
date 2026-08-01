#!/bin/bash
iverilog -g2012 -o imem_sim.out instruction_memory.sv tb_instruction_memory.sv
vvp imem_sim.out
