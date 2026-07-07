#!/bin/bash

echo "Starting Compilation..."
iverilog -g2012 -o sim.out safety_monitor.sv tb_safety_monitor.sv

if [ $? -eq 0 ]; then
    echo "Compilation Successful! Running Simulation..."
    vvp sim.out
    
    echo "Opening GTKWave..."
    gtkwave tb_safety_monitor.vcd &
else
    echo "Compilation Failed. Check syntax errors."
fi