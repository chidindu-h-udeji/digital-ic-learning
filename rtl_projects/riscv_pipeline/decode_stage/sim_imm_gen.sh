#!/bin/bash
iverilog -g2012 -o imm_gen_sim.out imm_gen.sv tb_imm_gen.sv
vvp imm_gen_sim.out
