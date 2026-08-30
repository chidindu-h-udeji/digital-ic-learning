#!/bin/bash
iverilog -g2012 -o sim_if_id_reg.vvp if_id_register.sv tb_if_id_register.sv
vvp sim_if_id_reg.vvp
