#!/bin/bash
cd "$(dirname "$0")" || exit 1
echo "========================================"
echo " Starting RISC-V Pipeline Regression"
echo "========================================"
declare -a scripts=("if_stage/sim_pc.sh" "if_stage/sim_imem.sh" "if_stage/sim_if_stage.sh" "pipeline_regs/sim_if_id_reg.sh" "id_stage/sim_control_unit.sh" "id_stage/sim_imm_gen.sh" "register_file/sim_register_file.sh" "id_stage/sim_id_stage.sh" "pipeline_regs/sim_id_ex_reg.sh" "ex_stage/sim_ex_stage.sh" "pipeline_regs/sim_ex_mem_reg.sh" "mem_stage/sim_data_memory.sh" "mem_stage/sim_mem_stage.sh" "pipeline_regs/sim_mem_wb_reg.sh" "wb_stage/sim_wb_stage.sh" "hazard_unit/sim_hazard_unit.sh" "forwarding_unit/sim_forwarding_unit.sh" "core/sim_core.sh")
errors=0
total=${#scripts[@]}
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        dir=$(dirname "$script")
        cmd=$(basename "$script")
        cd "$dir" || exit 1
        output=$(./"$cmd" 2>&1)
        code=$?
        cd - > /dev/null || exit 1
        
        zero_count=$(echo "$output" | grep -c "Errors: 0")
        expected=1
        if [[ "$script" == *"sim_core.sh"* ]]; then expected=2; fi
        if [[ "$script" == *"sim_data_memory.sh"* ]]; then expected=2; fi
        
        fail=0
        if [ $code -ne 0 ]; then fail=1; fi
        if echo "$output" | grep -qE "Errors: [1-9]"; then fail=1; fi
        if [ "$zero_count" -ne "$expected" ]; then fail=1; fi
        
        if [ $fail -eq 1 ]; then
            echo "❌ FAILED: $script"
            errors=$((errors + 1))
        else
            echo "✅ PASSED: $script"
        fi
    else
        echo "⚠  WARNING: Could not find $script"
        errors=$((errors + 1))
    fi
done
echo "========================================"
if [ $errors -eq 0 ]; then
    echo "🎉 ALL $total TESTS PASSED! Safe to commit."
    exit 0
else
    echo "💥 REGRESSION FAILED: $errors out of $total test(s) failed."
    exit 1
fi
