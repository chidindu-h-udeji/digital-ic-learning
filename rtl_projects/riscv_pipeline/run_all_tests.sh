#!/bin/bash
# ==============================================================================
# RISC-V Pipeline Regression Suite
# Runs all stage-level testbenches to ensure no logic is broken.
# ==============================================================================

echo "========================================"
echo " Starting RISC-V Pipeline Regression"
echo "========================================"

# Array of all simulation scripts in pipeline order
declare -a scripts=(
    # 1. Fetch Stage
    "fetch_stage/sim_pc.sh"
    "fetch_stage/sim_imem.sh"
    "fetch_stage/sim_if.sh"
    
    # 2. Decode Stage & Reg File
    "decode_stage/sim_if_id.sh"
    "decode_stage/sim_control_unit.sh"
    "decode_stage/sim_imm_gen.sh"
    "register_file/sim_run.sh"
    "decode_stage/sim_id_stage.sh"
    
    # 3. Execute Stage
    "pipeline_regs/sim_id_ex_reg.sh"
    "execute/sim_ex_stage.sh"
    
    # 4. Memory Stage
    "pipeline_regs/sim_ex_mem.sh"
    "mem_stage/sim_data_memory.sh"
    "mem_stage/sim_mem_stage.sh"
    
    # 5. Writeback Stage
    "pipeline_regs/sim_mem_wb.sh"
    "wb_stage/sim_wb_stage.sh"

    # 6. Hazard & Forwarding Units
    "hazard_unit/sim_hazard.sh"
    "forwarding_unit/sim_forwarding.sh"

    # 7. Top-Level Integration
    "core/sim_core.sh"
)

errors=0
total=${#scripts[@]}

for script in "${scripts[@]}"; do
    dir=$(dirname "$script")
    cmd=$(basename "$script")
    
    if [ -f "$script" ]; then
        echo "Running $cmd in $dir..."
        cd "$dir" || exit
        
        # Run the script and capture the output
        output=$(./"$cmd" 2>&1)
        
        # Check if the output contains failure keywords
        if echo "$output" | grep -qiE "failed|error[^s]|errors: [1-9]"; then
            echo "❌ FAILED: $script"
            errors=$((errors + 1))
        else
            echo "✅ PASSED: $script"
        fi
        
        # Return to the root directory silently
        cd - > /dev/null || exit
    else
        echo "⚠️  WARNING: Could not find $script"
        errors=$((errors + 1))
    fi
done

echo "========================================"
if [ $errors -eq 0 ]; then
    echo "🎉 ALL $total TESTS PASSED! Safe to commit."
else
    echo "💥 REGRESSION FAILED: $errors out of $total test(s) failed."
fi
echo "========================================"