#!/bin/bash
iverilog -g2012 -o sim_id_ex_reg.vvp id_ex_reg.sv tb_id_ex_reg.sv
vvp sim_id_ex_reg.vvp
