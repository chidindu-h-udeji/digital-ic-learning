`timescale 1ns/1ps

module tb_mem_stage;
  logic        clk = 0;
  logic        mem_read_in, mem_write_in, mem_to_reg_in, reg_write_in, mem_to_reg_out, reg_write_out;
  logic [4:0]  rd_addr_in, rd_addr_out;
  logic [31:0] alu_result_in, rs2_data_in, read_data_out, alu_result_out;

  integer errors = 0; // Error counter

  mem_stage dut (
    .clk(clk),
    .alu_result_in(alu_result_in),
    .rs2_data_in(rs2_data_in),
    .rd_addr_in(rd_addr_in),
    .mem_read_in(mem_read_in),
    .mem_write_in(mem_write_in),
    .mem_to_reg_in(mem_to_reg_in),
    .reg_write_in(reg_write_in),
    .read_data_out(read_data_out),
    .alu_result_out(alu_result_out),
    .rd_addr_out(rd_addr_out),
    .mem_to_reg_out(mem_to_reg_out),
    .reg_write_out(reg_write_out)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("tb_mem_stage.vcd");
    $dumpvars(0, tb_mem_stage);

    alu_result_in = 0; rs2_data_in = 0; rd_addr_in = 0;
    mem_read_in = 0; mem_write_in = 0; mem_to_reg_in = 0; reg_write_in = 0;
    #12;

    // SCENARIO 1: Passthrough check & Memory Read
    alu_result_in = 0; 
    rs2_data_in = 32'hFADA_FADA;
    rd_addr_in = 15;
    mem_read_in = 1; mem_write_in = 0; mem_to_reg_in = 1; reg_write_in = 1;
    
    #1;
    if (read_data_out !== 32'h6600AA11 || alu_result_out !== 0 || rd_addr_out !== 15 || mem_to_reg_out !== 1 || reg_write_out !== 1) begin
      $display("ERROR (Scen 1): Passthrough or memory read failed.");
      errors = errors + 1;
    end

    // SCENARIO 2: Memory Write through wrapper
    @(negedge clk);
    alu_result_in = 8;
    rs2_data_in = 32'hBABA_BABA; 
    rd_addr_in = 20;
    mem_read_in = 0; mem_write_in = 1; mem_to_reg_in = 0; reg_write_in = 0;
    
    @(negedge clk);
    alu_result_in = 8; mem_read_in = 1; mem_write_in = 0;
    #1;
    if (read_data_out !== 32'hBABA_BABA || alu_result_out !== 8 || rd_addr_out !== 20 || mem_to_reg_out !== 0 || reg_write_out !== 0) begin
      $display("ERROR (Scen 2): Write-then-read through wrapper failed.");
      errors = errors + 1;
    end

    // SCENARIO 3: Read Disable
    mem_read_in = 0;
    #1;
    if (read_data_out !== 0) begin
      $display("ERROR (Scen 3): read_data_out should be 0 when mem_read_in is low");
      errors = errors + 1;
    end

    if (errors == 0)
      $display("VERIFICATION PASSED! Errors: 0");
    else
      $display("VERIFICATION FAILED! Errors: %0d", errors);

    $finish;
  end
endmodule