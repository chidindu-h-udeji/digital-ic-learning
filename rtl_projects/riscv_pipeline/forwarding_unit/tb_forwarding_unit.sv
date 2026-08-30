`timescale 1ns/1ps

module tb_forwarding_unit;
  logic       ex_mem_reg_write, mem_wb_reg_write;
  logic [1:0] forward_a, forward_b;
  logic [4:0] ex_rs1_addr, ex_rs2_addr, ex_mem_rd_addr, mem_wb_rd_addr;

  integer errors = 0; // Error counter

  forwarding_unit dut (
    .ex_rs1_addr(ex_rs1_addr),
    .ex_rs2_addr(ex_rs2_addr),
    .ex_mem_reg_write(ex_mem_reg_write),
    .ex_mem_rd_addr(ex_mem_rd_addr),
    .mem_wb_reg_write(mem_wb_reg_write),
    .mem_wb_rd_addr(mem_wb_rd_addr),
    .forward_a(forward_a),
    .forward_b(forward_b)
  );

  initial begin
    $dumpfile("tb_forwarding_unit.vcd");
    $dumpvars(0, tb_forwarding_unit);

    // SCENARIO 1: No Forwarding (The Baseline)
    ex_rs1_addr = 1; ex_rs2_addr = 2;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 3;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 4;
    #1;
    if (forward_a !== 2'b00 || forward_b !== 2'b00) begin
      $display("ERROR (Scen 1): Baseline failed. Expected A=00, B=00. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // SCENARIO 2: EX/MEM Hazard on A (Priority 1 on A)
    ex_rs1_addr = 5; ex_rs2_addr = 2;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 5;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 4;
    #1;
    if (forward_a !== 2'b10 || forward_b !== 2'b00) begin
      $display("ERROR (Scen 2): EX/MEM hazard missed on A. Expected A=10, B=00. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // SCENARIO 3: EX/MEM Hazard on B (Priority 1 on B)
    ex_rs1_addr = 1; ex_rs2_addr = 5;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 5;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 4;
    #1;
    if (forward_a !== 2'b00 || forward_b !== 2'b10) begin
      $display("ERROR (Scen 3): EX/MEM hazard missed on B. Expected A=00, B=10. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // SCENARIO 4: MEM/WB Hazard on A (Priority 2 on A)
    ex_rs1_addr = 6; ex_rs2_addr = 2;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 3;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 6;
    #1;
    if (forward_a !== 2'b01 || forward_b !== 2'b00) begin
      $display("ERROR (Scen 4): MEM/WB hazard missed on A. Expected A=01, B=00. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // SCENARIO 5: MEM/WB Hazard on B (Priority 2 on B)
    ex_rs1_addr = 1; ex_rs2_addr = 6;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 3;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 6;
    #1;
    if (forward_a !== 2'b00 || forward_b !== 2'b01) begin
      $display("ERROR (Scen 5): MEM/WB hazard missed on B. Expected A=00, B=01. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // SCENARIO 6: The Double Data Hazard (EX/MEM wins on A)
    ex_rs1_addr = 7; ex_rs2_addr = 2;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 7;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 7;
    #1;
    if (forward_a !== 2'b10 || forward_b !== 2'b00) begin
      $display("ERROR (Scen 6): Priority routing failed on A! Expected A=10, B=00. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // SCENARIO 7: The Double Data Hazard (EX/MEM wins on B)
    ex_rs1_addr = 2; ex_rs2_addr = 7;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 7;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 7;
    #1;
    if (forward_a !== 2'b00 || forward_b !== 2'b10) begin
      $display("ERROR (Scen 7): Priority routing failed on B! Expected A=00, B=10. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // SCENARIO 8: The x0 Trap (The Performance Saver)
    ex_rs1_addr = 0; ex_rs2_addr = 0;
    ex_mem_reg_write = 1; ex_mem_rd_addr = 0;
    mem_wb_reg_write = 1; mem_wb_rd_addr = 0;
    #1;
    if (forward_a !== 2'b00 || forward_b !== 2'b00) begin
      $display("ERROR (Scen 8): Forwarded to x0! Expected A=00, B=00. Got A=%b, B=%b", forward_a, forward_b);
      errors = errors + 1;
    end

    // FINAL VERIFICATION
    if (errors == 0)
      $display("VERIFICATION PASSED! Errors: 0");
    else
      $display("VERIFICATION FAILED! Errors: %0d", errors);

    $finish;
  end
endmodule