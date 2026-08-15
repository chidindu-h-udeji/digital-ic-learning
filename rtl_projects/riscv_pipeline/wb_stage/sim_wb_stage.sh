#!/bin/bash
iverilog -g2012 -o sim_wb_stage.vvp wb_stage.sv tb_wb_stage.sv
vvp sim_wb_stage.vvp