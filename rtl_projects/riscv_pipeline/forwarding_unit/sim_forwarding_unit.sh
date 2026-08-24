#!/bin/bash
iverilog -g2012 -o sim_forwarding_unit.vvp forwarding_unit.sv tb_forwarding_unit.sv
vvp sim_forwarding_unit.vvp