`timescale 1ns/1ps

module tb_pc_logic;
  logic        clk = 0, reset;
  logic        stall, branch_taken; 
  logic [31:0] branch_target, pc_out, pc_plus_4;
  
  integer errors = 0; // Error counter
  
  pc_logic dut (
    .clk(clk), 
    .reset(reset),
    .stall(stall), 
    .branch_taken(branch_taken), 
    .branch_target(branch_target), 
    .pc_out(pc_out),
    .pc_plus_4(pc_plus_4)
  );
  
  always #5 clk = ~clk; // 10ns clock
  
  initial begin
    $dumpfile("tb_pc_logic.vcd");
    $dumpvars(0, tb_pc_logic);
    
    reset = 1;
    stall = 0; branch_taken = 0; branch_target = 0;
    
    // SCENARIO 1: Verify Reset
    @(negedge clk); 
    #1;
    if (pc_out !== 0) begin
      $display("ERROR (Scen 1): Expected reset output (0), got %h", pc_out);
      errors = errors + 1;
    end
    reset = 0;
    
    // SCENARIO 2: Verify Normal Count (PC + 4)
    repeat (3) @(negedge clk);
    #1;
    if (pc_out !== 12) begin
      $display("ERROR (Scen 2): Expected output (12), got %d", pc_out);
      errors = errors + 1;
    end
    
    // SCENARIO 3: Verify Stall
    stall = 1;
    @(negedge clk); // Wait one clock cycle while stalled
    #1;
    if (pc_out !== 12) begin
      $display("ERROR (Scen 3): Expected output 12, got %d", pc_out);
      errors = errors + 1;
    end
    
    // SCENARIO 4: Verify Branch
    @(negedge clk);
    stall = 0; 
    branch_taken = 1; 
    branch_target = 32'hB0000000;
    @(negedge clk);
    #1;
    if (pc_out !== 32'hB0000000) begin
      $display("ERROR (Scen 4): Expected B0000000, got %h", pc_out);
      errors = errors + 1;
    end
    
    // SCENARIO 5: Verify Priority (Branch > Stall)
    @(negedge clk);
    stall = 1; 
    branch_taken = 1; 
    branch_target = 32'hBAADF00D;
    @(negedge clk);
    #1;
    if (pc_out !== 32'hBAADF00D) begin
      $display("ERROR (Scen 5): Expected BAADF00D, got %h", pc_out);
      errors = errors + 1;
    end

    // SCENARIO 6: Verify Reset Priority
    @(negedge clk);
    reset = 1; 
    stall = 1; 
    branch_taken = 1; 
    branch_target = 32'h11FACE11;
    
    @(negedge clk);
    #1;
    if (pc_out !== 0) begin
      $display("ERROR (Scen 6): Expected 0 (Reset priority), got %h", pc_out);
      errors = errors + 1;
    end
    
    // Clean up signals
    reset = 0; stall = 0; branch_taken = 0;
    
    // FINAL VERIFICATION
    if (errors == 0)
      $display("VERIFICATION PASSED! Errors: 0");
    else
      $display("VERIFICATION FAILED! Errors: %0d", errors);
      
    $finish;
  end
endmodule