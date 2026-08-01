`timescale 1ns/1ps

module tb_register_file;
  logic        clk = 0, reset;
  logic        reg_write; 
  logic [4:0]  rs1_addr, rs2_addr, rd_addr; 
  logic [31:0] rd_data, rs1_data, rs2_data;
  
  integer errors = 0; // Error counter
  
  register_file dut (
    .clk(clk), 
    .reset(reset),
    .reg_write(reg_write), 
    .rs1_addr(rs1_addr), 
    .rs2_addr(rs2_addr), 
    .rd_addr(rd_addr),
    .rd_data(rd_data), 
    .rs1_data(rs1_data), 
    .rs2_data(rs2_data)
  );
    
  always #5 clk = ~clk; // 10ns clock
  
  initial begin
    $dumpfile("tb_register_file.vcd");
    $dumpvars(0, tb_register_file);
    
    reg_write = 0; reset = 1;
    rd_addr = 0; rs1_addr = 0; rs2_addr = 0;
    rd_data = 0;
    @(negedge clk);
    reset = 0;

    // SCENARIO 1: Verify Reset (Unwritten register)
    @(negedge clk);
    rs1_addr = 1;
    #1;
    if (rs1_data !== 0) begin
      $display("ERROR (Scen 1): Expected reset output (0), got %h", rs1_data);
      errors = errors + 1;
    end

    // SCENARIO 2: Normal Write and Read
    @(negedge clk);
    rd_addr = 5; rd_data = 32'hDEADBEEF; reg_write = 1;
    @(negedge clk);
    reg_write = 0;
    
    @(negedge clk);
    rs1_addr = 5;
    #1;
    if (rs1_data !== 32'hDEADBEEF) begin
      $display("ERROR (Scen 2): Expected DEADBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    
    // SCENARIO 3: The x0 Trap (Hardwired to 0)
    @(negedge clk);
    rd_addr = 0; rd_data = 32'hFFFFFFFF; reg_write = 1;
    @(negedge clk);
    reg_write = 0;
    
    @(negedge clk);
    rs1_addr = 0;
    #1;
    if (rs1_data !== 0) begin
      $display("ERROR (Scen 3): Expected not to write to x0, got %h", rs1_data);
      errors = errors + 1;
    end
    
    // SCENARIO 4: Dual Read
    @(negedge clk);
    rd_addr = 2; rd_data = 32'hFACEBEEF; reg_write = 1;
    @(negedge clk); 
    reg_write = 0;
    
    @(negedge clk);
    rd_addr = 3; rd_data = 32'hCAFEBEEF; reg_write = 1;
    @(negedge clk);
    reg_write = 0;
    
    @(negedge clk);
    rs1_addr = 2;
    rs2_addr = 3;
    #1; 
    if (rs1_data !== 32'hFACEBEEF) begin
      $display("ERROR (Scen 4, rs1): Expected FACEBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    if (rs2_data !== 32'hCAFEBEEF) begin
      $display("ERROR (Scen 4, rs2): Expected CAFEBEEF, got %h", rs2_data);
      errors = errors + 1;
    end
    
    // SCENARIO 5: Write Enable Test (reg_write = 0)
    @(negedge clk);
    rd_addr = 2; rd_data = 32'hBADBAD00; reg_write = 0;
    @(negedge clk);
    
    @(negedge clk);
    rs1_addr = 2;
    #1;
    if (rs1_data !== 32'hFACEBEEF) begin
      $display("ERROR (Scen 5): Expected FACEBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    
    // SCENARIO 6: RAW Forwarding Test
    @(negedge clk);
    rd_addr = 7; rd_data = 32'hFEEDBEEF; reg_write = 1;
    rs1_addr = 7; // Request read on the exact same cycle
    #1;
    if (rs1_data !== 32'hFEEDBEEF) begin
      $display("ERROR (Scen 6): Expected FEEDBEEF, got %h", rs1_data);
      errors = errors + 1;
    end
    @(negedge clk);
    reg_write = 0;
    
    // FINAL VERIFICATION
    if (errors == 0)
      $display("VERIFICATION PASSED! Errors: 0");
    else
      $display("VERIFICATION FAILED! Errors: %0d", errors);
      
    $finish;
  end
endmodule