`timescale 1ns/1ps

module tb_ex_mem_reg;
  logic        clk = 0, reset;
  logic        mem_read_in, mem_write_in, mem_to_reg_in, reg_write_in;
  logic        mem_read_out, mem_write_out, mem_to_reg_out, reg_write_out;
  logic [4:0]  rd_addr_in, rd_addr_out;
  logic [31:0] alu_result_in, rs2_data_in, alu_result_out, rs2_data_out;
  
  integer errors = 0; // Error counter
  
  ex_mem_reg dut (
    .clk(clk),
    .reset(reset),
    .alu_result_in(alu_result_in),
    .rs2_data_in(rs2_data_in),
    .rd_addr_in(rd_addr_in),
    .mem_read_in(mem_read_in),
    .mem_write_in(mem_write_in),
    .mem_to_reg_in(mem_to_reg_in),
    .reg_write_in(reg_write_in),
    .alu_result_out(alu_result_out),
    .rs2_data_out(rs2_data_out),
    .rd_addr_out(rd_addr_out),
    .mem_read_out(mem_read_out),
    .mem_write_out(mem_write_out),
    .mem_to_reg_out(mem_to_reg_out),
    .reg_write_out(reg_write_out)
  );
  
  always #5 clk = ~clk; // 10ns clock
  
  initial begin
    $dumpfile("tb_ex_mem_reg.vcd");
    $dumpvars(0, tb_ex_mem_reg);
    
    reset = 1;
    alu_result_in = 32'hBAC2_BACC; rs2_data_in = 32'hBEA7_B100; rd_addr_in = 7;
    mem_read_in = 1; mem_write_in = 1; mem_to_reg_in = 1; reg_write_in = 1;
    
    // SCENARIO 1: Reset
    @(negedge clk);
    if (alu_result_out !== 0 || rs2_data_out !== 0 || rd_addr_out !== 0 || mem_read_out !== 0 || mem_write_out !== 0 || mem_to_reg_out !== 0 || reg_write_out !== 0) begin
      $display("ERROR (Scen 1): Expected reset output (0)");
      errors = errors + 1;
    end

    // SCENARIO 2: Data Latch on Clock Edge
    #1;
    reset = 0;
    @(negedge clk);
    if (alu_result_out !== 32'hBAC2_BACC || rs2_data_out !== 32'hBEA7_B100 || rd_addr_out !== 7 || mem_read_out !== 1 || mem_write_out !== 1 || mem_to_reg_out !== 1 || reg_write_out !== 1) begin
      $display("ERROR (Scen 2): Data latch failed to pass inputs to outputs.");
      errors = errors + 1;
    end

    // SCENARIO 3: The Hold (Register behavior)
    // Inputs change between clock cycles
    #1;
    alu_result_in = 32'h5C17_1DEA; rs2_data_in = 32'hD065_EA75; rd_addr_in = 15; mem_read_in = 0;
    #1;
    if (alu_result_out !== 32'hBAC2_BACC) begin
      $display("ERROR (Scen 3a): Register failed to hold. Data leaked through without a clock edge.");
      errors = errors + 1;
    end

    // Wait for the next clock edge
    @(negedge clk);
    #1;
    if (alu_result_out !== 32'h5C17_1DEA || mem_read_out !== 0) begin
      $display("ERROR (Scen 3b): New data failed to latch on the subsequent clock edge.");
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
    
  
  