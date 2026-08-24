#!/bin/bash
iverilog -g2012 -o sim_control_unit.vvp control_unit.sv tb_control_unit.sv
vvp sim_control_unit.vvp
