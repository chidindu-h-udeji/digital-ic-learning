#!/bin/bash
iverilog -g2012 -o sim_ex_mem.vvp ex_mem_reg.sv tb_ex_mem_reg.sv
vvp sim_ex_mem.vvp