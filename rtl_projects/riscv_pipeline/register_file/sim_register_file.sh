#!/bin/bash
# Compile the SystemVerilog files
iverilog -g2012 -o sim_register_file.vvp register_file.sv tb_register_file.sv

# Run the compiled simulation
vvp sim_register_file.vvp