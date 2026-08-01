`timescale 1ns/1ps

module tb_if_stage;
  logic        clk = 0, reset;
  logic        stall, branch_taken; 
  logic [31:0] branch_target, pc_out, instruction;
  
  integer errors = 0; // Error counter
  
  if_stage dut (
    .clk(clk), 
    .reset(reset),
    .stall(stall), 
    .branch_taken(branch_taken), 
    .branch_target(branch_target), 
    .pc_out(pc_out),
    .instruction(instruction)
  );
  
  always #5 clk = ~clk; // 10ns clock
  
  initial begin
    $dumpfile("tb_if_stage.vcd");
    $dumpvars(0, tb_if_stage);
    
    reset = 1;
    stall = 0;
    branch_taken = 0;
    branch_target = 0;
    
    // SCENARIO 1: Reset
    @(negedge clk); 
    #1;
    if (pc_out !== 0) begin
      $display("ERROR (Scen 1, pc_out): Expected reset output (0), got %h", pc_out);
      errors = errors + 1;
    end
    if (instruction !== 32'hFACED007) begin
      $display("ERROR (Scen 1, instruction): Expected FACED007, got %h", instruction);
      errors = errors + 1;
    end
    reset = 0;
    
    // SCENARIO 2: Normal Fetch
    @(negedge clk); 
    #1;
    if (pc_out !== 4) begin
      $display("ERROR (Scen 2, pc_out): Expected output (4), got %h", pc_out);
      errors = errors + 1;
    end
    if (instruction !== 32'hDEAD7A1E) begin
      $display("ERROR (Scen 2, instruction): Expected DEAD7A1E, got %h", instruction);
      errors = errors + 1;
    end
    
    // SCENARIO 3: Stall
    stall = 1;
    @(negedge clk); 
    #1;
    if (pc_out !== 4) begin
      $display("ERROR (Scen 3, pc_out): Expected output (4), got %h", pc_out);
      errors = errors + 1;
    end
    if (instruction !== 32'hDEAD7A1E) begin
      $display("ERROR (Scen 3, instruction): Expected DEAD7A1E, got %h", instruction);
      errors = errors + 1;
    end
    
    // SCENARIO 4: Branch
    @(negedge clk);
    stall = 0; 
    branch_taken = 1; 
    branch_target = 12;
    @(negedge clk); 
    #1;
    if (pc_out !== 12) begin
      $display("ERROR (Scen 4, pc_out): Expected output (12), got %h", pc_out);
      errors = errors + 1;
    end
    if (instruction !== 32'h70D01157) begin
      $display("ERROR (Scen 4, instruction): Expected 70D01157, got %h", instruction);
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