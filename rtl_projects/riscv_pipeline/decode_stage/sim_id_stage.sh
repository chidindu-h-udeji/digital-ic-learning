#!/bin/bash
iverilog -g2012 -o id_stage_sim.out imm_gen.sv control_unit.sv id_stage.sv tb_id_stage.sv
vvp id_stage_sim.out
