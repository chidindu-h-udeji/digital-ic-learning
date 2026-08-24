`timescale 1ns/1ps

module tb_imm_gen;
  logic [31:0] instruction, imm_ext;
  
  integer errors = 0; // Error counter
  
  imm_gen dut (
    .instruction(instruction),
    .imm_ext(imm_ext)
  );
  
  initial begin
    $dumpfile("tb_imm_gen.vcd");
    $dumpvars(0, tb_imm_gen);
    
    // SCENARIO 1: I-Type (Positive)
    instruction = 32'h00A00293; // addi x5, x0, 10
    #10;
    if (imm_ext !== 32'h0000000A) begin
      $display("ERROR (Scen 1): Expected (10), got %h", imm_ext);
      errors = errors + 1;
    end
    
    // SCENARIO 2: I-Type (Negative)
    instruction = 32'hFF600293; // addi x5, x0, -10
    #10;
    if (imm_ext !== 32'hFFFFFFF6) begin
      $display("ERROR (Scen 2): Expected (-10), got %h", imm_ext);
      errors = errors + 1;
    end
    
    // SCENARIO 3: S-Type (Positive)
    instruction = 32'h00502623; // sw x5, 12(x0)
    #10;
    if (imm_ext !== 32'h0000000C) begin
      $display("ERROR (Scen 3): Expected (12), got %h", imm_ext);
      errors = errors + 1;
    end
    
    // SCENARIO 4: S-Type (Negative)
    instruction = 32'hFE502A23; // sw x5, -12(x0)
    #10;
    if (imm_ext !== 32'hFFFFFFF4) begin
      $display("ERROR (Scen 4): Expected (-12), got %h", imm_ext);
      errors = errors + 1;
    end
    
    // SCENARIO 5: B-Type (Positive)
    instruction = 32'h00500863; // beq x0, x5, 16
    #10;
    if (imm_ext !== 32'h00000010) begin
      $display("ERROR (Scen 5): Expected (16), got %h", imm_ext);
      errors = errors + 1;
    end
    
    // SCENARIO 6: B-Type (Negative)
    instruction = 32'hFE5008E3; // beq x0, x5, -16
    #10;
    if (imm_ext !== 32'hFFFFFFF0) begin
      $display("ERROR (Scen 6): Expected (-16), got %h", imm_ext);
      errors = errors + 1;
    end
    
    // SCENARIO 7: Default (R-Type, no immediate)
    instruction = 32'h003100B3; // add x1, x2, x3
    #10;
    if (imm_ext !== 32'h00000000) begin
      $display("ERROR (Scen 7): Expected (0), got %h", imm_ext);
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