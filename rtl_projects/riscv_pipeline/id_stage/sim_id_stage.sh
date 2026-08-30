#!/bin/bash
iverilog -g2012 -o sim_id_stage.vvp imm_gen.sv control_unit.sv id_stage.sv tb_id_stage.sv
vvp sim_id_stage.vvp
