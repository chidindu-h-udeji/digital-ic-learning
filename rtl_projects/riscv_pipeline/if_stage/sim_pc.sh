#!/bin/bash
iverilog -g2012 -o sim_pc.vvp pc_logic.sv tb_pc_logic.sv
vvp sim_pc.vvp
