#!/bin/bash
iverilog -g2012 -o if_id_sim.out if_id_register.sv tb_if_id_register.sv
vvp if_id_sim.out
