#!/bin/bash
iverilog -g2012 -o control_unit_sim.out control_unit.sv tb_control_unit.sv
vvp control_unit_sim.out
