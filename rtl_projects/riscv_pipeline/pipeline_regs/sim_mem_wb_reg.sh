#!/bin/bash
iverilog -g2012 -o sim_mem_wb_reg.vvp mem_wb_reg.sv tb_mem_wb_reg.sv
vvp sim_mem_wb_reg.vvp
