`timescale 1ns/1ps

module tb_register_file;
  logic        i_clk = 0;
  logic        reg_write; 
  logic [4:0]  rs1_addr, rs2_addr, rd_addr; 
  logic [31:0] rd_data, rs1_data, rs2_data;
  
  integer errors = 0; // Error counter
  
  register_file dut (
    .i_clk(i_clk), 
    .reg_write(reg_write), 
    .rs1_addr(rs1_addr), 
    .rs2_addr(rs2_addr), 
    .rd_addr(rd_addr),
    .rd_data(rd_data), 
    .rs1_data(rs1_data), 
    .rs2_data(rs2_data)
  );
    
  always #5 i_clk = ~i_clk; // 10ns clock
  
  initial begin
    $dumpfile("tb_register_file.vcd");
    $dumpvars(0, tb_register_file);
    
    // Initialize inputs
    reg_write = 0;
    rd_addr = 0; rs1_addr = 0; rs2_addr = 0;
    rd_data = 0;
    
    // Drive stimuli on negative edge
    @(negedge i_clk);

    // Test 1: Normal Write and Read
    rd_addr = 5; rd_data = 32'hDEADBEEF; reg_write = 1;
    @(negedge i_clk);
    reg_write = 0;
    
    @(negedge i_clk);
    rs1_addr = 5;
    #1; 
    if (rs1_data !== 32'hDEADBEEF) begin
      $display("ERROR (Test 1): Expected DEADBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    
    // Test 2: Write to x0 (Hardwired to 0)
    @(negedge i_clk);
    rd_addr = 0; rd_data = 32'hFFFFFFFF; reg_write = 1;
    @(negedge i_clk);
    reg_write = 0;
    
    @(negedge i_clk);
    rs1_addr = 0;
    #1;
    if (rs1_data !== 0) begin
      $display("ERROR (Test 2): Expected not to write to x0, got %h", rs1_data);
      errors = errors + 1;
    end
    
    // Test 3: Dual Read
    @(negedge i_clk);
    rd_addr = 2; rd_data = 32'hFACEBEEF; reg_write = 1;
    @(negedge i_clk); 
    reg_write = 0;
    
    @(negedge i_clk);
    rd_addr = 3; rd_data = 32'hCAFEBEEF; reg_write = 1;
    @(negedge i_clk);
    reg_write = 0;
    
    @(negedge i_clk);
    rs1_addr = 2;
    rs2_addr = 3;
    #1; 
    if (rs1_data !== 32'hFACEBEEF) begin
      $display("ERROR (Test 3, rs1): Expected FACEBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    if (rs2_data !== 32'hCAFEBEEF) begin
      $display("ERROR (Test 3, rs2): Expected CAFEBEEF, got %h", rs2_data);
      errors = errors + 1;
    end
    
    // Test 4: Write Enable 
    @(negedge i_clk);
    rd_addr = 2; rd_data = 32'hBADBAD00; reg_write = 0;
    @(negedge i_clk);
    
    @(negedge i_clk);
    rs1_addr = 2;
    #1;
    if (rs1_data !== 32'hFACEBEEF) begin
      $display("ERROR (Test 4): Expected FACEBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    
    // Test 5: Read-After-Write (RAW) Internal Forwarding
    @(negedge i_clk);
    rd_addr = 7; rd_data = 32'hFEEDBEEF; reg_write = 1;
    rs1_addr = 7; // Read same address during write
    #1;
    if (rs1_data !== 32'hFEEDBEEF) begin
      $display("ERROR (Test 5): Expected FEEDBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    @(negedge i_clk);
    reg_write = 0;
    
    // Final Verification
    if (errors == 0)
      $display("VERIFICATION PASSED! Errors: 0");
    else
      $display("VERIFICATION FAILED! Errors: %0d", errors);
      
    $finish;
  end
endmodule