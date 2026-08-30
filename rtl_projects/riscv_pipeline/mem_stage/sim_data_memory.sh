#!/bin/bash
iverilog -g2012 -o sim_data_memory.vvp data_memory.sv tb_data_memory.sv
vvp sim_data_memory.vvp