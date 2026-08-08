#!/bin/bash
iverilog -g2012 -o id_ex_reg_sim.out id_ex_reg.sv tb_id_ex_reg.sv
vvp id_ex_reg_sim.out
