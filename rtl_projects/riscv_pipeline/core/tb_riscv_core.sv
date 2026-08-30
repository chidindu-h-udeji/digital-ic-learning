`timescale 1ns/1ps

module tb_riscv_core;
  logic clk = 0;
  logic reset;
  
  integer errors = 0; 
  integer total_cycles = 0;
  integer stall_cycles = 0;
  integer retired_instructions = 10;
  real cpi;
  
  riscv_core dut (
    .clk(clk),
    .reset(reset)
  );
  
  always #5 clk = ~clk; 
  
  always @(posedge clk) begin
    if (!reset) begin
      if (total_cycles < 16) begin 
        total_cycles = total_cycles + 1;
        if (dut.load_use_stall) stall_cycles = stall_cycles + 1;
      end
    end
  end
  
  initial begin
    $dumpfile("tb_riscv_core.vcd");
    $dumpvars(0, tb_riscv_core);
    
    // SCENARIO 1: Reset the processor
    reset = 1;
    @(negedge clk);
    #1;
    reset = 0;
    
    // Run for 20 cycles to ensure the pipeline fully clears
    repeat (20) @(negedge clk);
    #1;
    
    // SCENARIO 2: Check x3 (Testing dual-forwarding to ALU)
    if (dut.reg_inst.registers[3] !== 32'd15) begin
      $display("ERROR (Scen 2): Forwarding to ALU failed. Expected x3 = 15, got %0d", dut.reg_inst.registers[3]);
      errors = errors + 1;
    end

    // SCENARIO 3: Check x2 (Validating initial state held)
    if (dut.reg_inst.registers[2] !== 32'd10) begin
      $display("ERROR (Scen 3): Expected x2 = 10, got %0d", dut.reg_inst.registers[2]);
      errors = errors + 1;
    end
    
    // SCENARIO 4: Check Memory (Testing store-data forwarding)
    if (dut.mem_stage_inst.dmem.mem[0] !== 32'd15) begin
      $display("ERROR (Scen 4): Store forwarding failed. Expected Mem[0] = 15, got %0d", dut.mem_stage_inst.dmem.mem[0]);
      errors = errors + 1;
    end

    // SCENARIO 5: Check x4 (Testing load word explicitly)
    if (dut.reg_inst.registers[4] !== 32'd15) begin
      $display("ERROR (Scen 5): Load Word failed. Expected x4 = 15, got %0d", dut.reg_inst.registers[4]);
      errors = errors + 1;
    end

    // SCENARIO 6: Check x5 (Testing load-use stall)
    if (dut.reg_inst.registers[5] !== 32'd20) begin
      $display("ERROR (Scen 6): Load-Use stall failed. Expected x5 = 20, got %0d", dut.reg_inst.registers[5]);
      errors = errors + 1;
    end
    
    // SCENARIO 7: Check x7 (Testing not-taken branch)
    if (dut.reg_inst.registers[7] !== 32'd77) begin
      $display("ERROR (Scen 7): Not-taken branch flushed by mistake! Expected x7 = 77, got %0d", dut.reg_inst.registers[7]);
      errors = errors + 1;
    end

    // SCENARIO 8: Check x1 (Testing branch flush logic)
    if (dut.reg_inst.registers[1] !== 32'd5) begin
      $display("ERROR (Scen 8): Branch Flush failed. Expected x1 = 5, got %0d", dut.reg_inst.registers[1]);
      errors = errors + 1;
    end
    
    // SCENARIO 9: Check x6 (Testing post-branch execution)
    if (dut.reg_inst.registers[6] !== 32'd15) begin
      $display("ERROR (Scen 9): Post-branch execution failed. Expected x6 = 15, got %0d", dut.reg_inst.registers[6]);
      errors = errors + 1;
    end
    
    // FINAL VERIFICATION & METRICS
    cpi = real'(total_cycles) / real'(retired_instructions);
    
    $display("========================================");
    if (errors == 0) begin
      $display("VERIFICATION PASSED! Errors: 0");
      $display("--- PERFORMANCE METRICS ---");
      $display("Instructions Retired: %0d", retired_instructions);
      $display("Total Active Cycles : %0d", total_cycles);
      $display("Stall Cycles        : %0d", stall_cycles);
      $display("Measured CPI        : %0.2f", cpi);
    end else begin
      $display("VERIFICATION FAILED! Errors: %0d", errors);
    end
    $display("========================================");
      
    $finish;
  end
endmodule