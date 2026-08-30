`timescale 1ns/1ps

module tb_hazard_unit;
  logic       id_ex_mem_read, stall; 
  logic [4:0] id_ex_rd_addr, id_rs1_addr, id_rs2_addr;
  
  integer errors = 0; // Error counter
  
  hazard_unit dut (
    .id_ex_mem_read(id_ex_mem_read), 
    .id_ex_rd_addr(id_ex_rd_addr),
    .id_rs1_addr(id_rs1_addr), 
    .id_rs2_addr(id_rs2_addr), 
    .stall(stall)
  );
  
  initial begin
    $dumpfile("tb_hazard_unit.vcd");
    $dumpvars(0, tb_hazard_unit);
    
    // SCENARIO 1: Independent Instruction (No Hazard)
    id_ex_mem_read = 1; id_ex_rd_addr = 5; id_rs1_addr = 6; id_rs2_addr = 7;
    #1;
    if (stall !== 0) begin
      $display("ERROR (Scen 1): False positive on independent instructions. Expected stall=0, got %b", stall);
      errors = errors + 1;
    end

    // SCENARIO 2: Genuine Load-Use Hazard on rs1
    id_ex_mem_read = 1; id_ex_rd_addr = 5; id_rs1_addr = 5; id_rs2_addr = 10;
    #1;
    if (stall !== 1) begin
      $display("ERROR (Scen 2): Load-use hazard missed on rs1! Expected stall=1, got %b", stall);
      errors = errors + 1;
    end

    // SCENARIO 3: Genuine Load-Use Hazard on rs2
    id_ex_mem_read = 1; id_ex_rd_addr = 5; id_rs1_addr = 10; id_rs2_addr = 5;
    #1;
    if (stall !== 1) begin
      $display("ERROR (Scen 3): Load-use hazard missed on rs2! Expected stall=1, got %b", stall);
      errors = errors + 1;
    end
    
    // SCENARIO 4: Non-Load Instruction in EX (Matching Addresses)
    id_ex_mem_read = 0; id_ex_rd_addr = 8; id_rs1_addr = 8; id_rs2_addr = 2;
    #1;
    if (stall !== 0) begin
      $display("ERROR (Scen 4): Stalled on non-load instruction (mem_read=0). Expected stall=0, got %b", stall);
      errors = errors + 1;
    end
    
    // SCENARIO 5: The x0 Trap (The Performance Saver)
    id_ex_mem_read = 1; id_ex_rd_addr = 0; id_rs1_addr = 0; id_rs2_addr = 9;
    #1;
    if (stall !== 0) begin
      $display("ERROR (Scen 5): Performance bug! Falsely stalled on x0. Expected stall=0, got %b", stall);
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