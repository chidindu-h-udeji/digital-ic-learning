#!/bin/bash
iverilog -g2012 -o pc_sim.out pc_logic.sv tb_pc_logic.sv
vvp pc_sim.out
