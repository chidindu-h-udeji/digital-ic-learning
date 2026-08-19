#!/bin/bash
iverilog -g2012 -o sim_forwarding.vvp forwarding_unit.sv tb_forwarding_unit.sv
vvp sim_forwarding.vvp