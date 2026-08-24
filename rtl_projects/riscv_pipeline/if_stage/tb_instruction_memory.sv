`timescale 1ns/1ps

module tb_instruction_memory; 
  logic [31:0] addr, instruction;
  
  integer errors = 0; // Error counter
  
  instruction_memory dut (
    .addr(addr), 
    .instruction(instruction)
  );
  
  initial begin
    $dumpfile("tb_instruction_memory.vcd");
    $dumpvars(0, tb_instruction_memory);
    
    // SCENARIO 1
    addr = 0;
    #1;
    if (instruction !== 32'hFACED007) begin
      $display("ERROR (Scen 1): Expected FACED007, got %h", instruction);
      errors = errors + 1;
    end
    
    // SCENARIO 2
    addr = 4;
    #1;
    if (instruction !== 32'hDEAD7A1E) begin
      $display("ERROR (Scen 2): Expected DEAD7A1E, got %h", instruction);
      errors = errors + 1;
    end
    
    // SCENARIO 3
    addr = 8;
    #1;
    if (instruction !== 32'h01234567) begin
      $display("ERROR (Scen 3): Expected 01234567, got %h", instruction);
      errors = errors + 1;
    end
    
    // SCENARIO 4
    addr = 12;
    #1;
    if (instruction !== 32'h70D01157) begin
      $display("ERROR (Scen 4): Expected 70D01157, got %h", instruction);
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