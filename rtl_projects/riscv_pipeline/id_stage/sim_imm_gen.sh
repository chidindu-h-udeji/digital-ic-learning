#!/bin/bash
iverilog -g2012 -o sim_imm_gen.vvp imm_gen.sv tb_imm_gen.sv
vvp sim_imm_gen.vvp
