#!/bin/bash
iverilog -g2012 -o sim_hazard.vvp hazard_unit.sv tb_hazard_unit.sv
vvp sim_hazard.vvp