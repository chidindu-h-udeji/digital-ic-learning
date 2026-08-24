`timescale 1ns/1ps

module tb_if_id_register;
  logic        clk = 0, reset;
  logic        stall, flush; 
  logic [31:0] instruction_in, pc_in, pc_plus4_in, instruction_out, pc_out, pc_plus4_out;
  
  integer errors = 0; // Error counter
  
  if_id_register dut (
    .clk(clk), 
    .reset(reset),
    .stall(stall),
    .flush(flush),
    .instruction_in(instruction_in), 
    .pc_in(pc_in), 
    .pc_plus4_in(pc_plus4_in),
    .instruction_out(instruction_out),
    .pc_out(pc_out),
    .pc_plus4_out(pc_plus4_out)
  );
  
  always #5 clk = ~clk; // 10ns clock
  
  initial begin
    $dumpfile("tb_if_id_register.vcd");
    $dumpvars(0, tb_if_id_register);
    
    reset = 1;
    stall = 0;
    flush = 0;
    instruction_in = 32'hD1CE;
    pc_in = 32'h91CE;
    pc_plus4_in = 32'h512E;
    
    // SCENARIO 1: Reset
    @(negedge clk); 
    #1;
    if (pc_out !== 0) begin
      $display("ERROR (Scen 1, pc_out): Expected reset output (0), got %h", pc_out);
      errors = errors + 1;
    end
    if (pc_plus4_out !== 0) begin
      $display("ERROR (Scen 1, pc_plus4_out): Expected reset output (0), got %h", pc_plus4_out);
      errors = errors + 1;
    end
    if (instruction_out !== 32'h00000013) begin
      $display("ERROR (Scen 1, instruction_out): Expected reset output 00000013, got %h", instruction_out);
      errors = errors + 1;
    end
    reset = 0;
    
    // SCENARIO 2: Normal Latch
    @(negedge clk); 
    #1;
    if (pc_out !== 32'h91CE) begin
      $display("ERROR (Scen 2, pc_out): Expected 91CE, got %h", pc_out);
      errors = errors + 1;
    end
    if (pc_plus4_out !== 32'h512E) begin
      $display("ERROR (Scen 2, pc_plus4_out): Expected 512E, got %h", pc_plus4_out);
      errors = errors + 1;
    end
    if (instruction_out !== 32'hD1CE) begin
      $display("ERROR (Scen 2, instruction_out): Expected D1CE, got %h", instruction_out);
      errors = errors + 1;
    end
    
    // SCENARIO 3: Stall
    stall = 1;
    flush = 0;
    instruction_in = 32'hB2B2;
    pc_in = 32'hEA51;
    pc_plus4_in = 32'hFEA7;
    
    @(negedge clk); 
    #1;
    if (pc_out !== 32'h91CE) begin
      $display("ERROR (Scen 3, pc_out): Expected 91CE, got %h", pc_out);
      errors = errors + 1;
    end
    if (pc_plus4_out !== 32'h512E) begin
      $display("ERROR (Scen 3, pc_plus4_out): Expected 512E, got %h", pc_plus4_out);
      errors = errors + 1;
    end
    if (instruction_out !== 32'hD1CE) begin
      $display("ERROR (Scen 3, instruction_out): Expected D1CE, got %h", instruction_out);
      errors = errors + 1;
    end
    
    // SCENARIO 4: Flush
    @(negedge clk);
    stall = 0; 
    flush = 1;
    
    @(negedge clk); 
    #1;
    if (pc_out !== 0) begin
      $display("ERROR (Scen 4, pc_out): Expected reset output (0), got %h", pc_out);
      errors = errors + 1;
    end
    if (pc_plus4_out !== 0) begin
      $display("ERROR (Scen 4, pc_plus4_out): Expected reset output (0), got %h", pc_plus4_out);
      errors = errors + 1;
    end
    if (instruction_out !== 32'h00000013) begin
      $display("ERROR (Scen 4, instruction_out): Expected reset output 00000013, got %h", instruction_out);
      errors = errors + 1;
    end
    
    // RECOVERY 1: Re-establish the baseline non-bubble state
    reset = 0; stall = 0; flush = 0;
    instruction_in = 32'hDAFF;
    pc_in = 32'h101A;
    pc_plus4_in = 32'hB065;
    @(negedge clk);
    
    // SCENARIO 5: Verify Priority (Flush > Stall)
    stall = 1; 
    flush = 1;
    
    @(negedge clk); 
    #1;
    if (pc_out !== 0) begin
      $display("ERROR (Scen 5, pc_out): Expected reset output (0), got %h", pc_out);
      errors = errors + 1;
    end
    if (pc_plus4_out !== 0) begin
      $display("ERROR (Scen 5, pc_plus4_out): Expected reset output (0), got %h", pc_plus4_out);
      errors = errors + 1;
    end
    if (instruction_out !== 32'h00000013) begin
      $display("ERROR (Scen 5, instruction_out): Expected reset output 00000013, got %h", instruction_out);
      errors = errors + 1;
    end

    // RECOVERY 2: Re-establish the baseline non-bubble state
    reset = 0; stall = 0; flush = 0;
    instruction_in = 32'hBEEF;
    pc_in = 32'h202B;
    pc_plus4_in = 32'hC076;
    @(negedge clk);
    
    // SCENARIO 6: Verify Reset Priority
    reset = 1;
    stall = 1; 
    flush = 1;
    
    @(negedge clk); 
    #1;
    if (pc_out !== 0) begin
      $display("ERROR (Scen 6, pc_out): Expected reset output (0), got %h", pc_out);
      errors = errors + 1;
    end
    if (pc_plus4_out !== 0) begin
      $display("ERROR (Scen 6, pc_plus4_out): Expected reset output (0), got %h", pc_plus4_out);
      errors = errors + 1;
    end
    if (instruction_out !== 32'h00000013) begin
      $display("ERROR (Scen 6, instruction_out): Expected reset output 00000013, got %h", instruction_out);
      errors = errors + 1;
    end
    
    // Clean up signals
    reset = 0; stall = 0; flush = 0;
    
    // FINAL VERIFICATION
    if (errors == 0)
      $display("VERIFICATION PASSED! Errors: 0");
    else
      $display("VERIFICATION FAILED! Errors: %0d", errors);
      
    $finish;
  end
endmodule