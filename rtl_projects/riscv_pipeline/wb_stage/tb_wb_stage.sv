`timescale 1ns/1ps

module tb_wb_stage;
  logic        mem_to_reg_in, reg_write_in, reg_write_out;
  logic [4:0]  rd_addr_in, rd_addr_out;
  logic [31:0] read_data_in, alu_result_in, write_back_data;

  integer errors = 0; // Error counter

  wb_stage dut (
    .read_data_in(read_data_in),
    .alu_result_in(alu_result_in),
    .rd_addr_in(rd_addr_in),
    .mem_to_reg_in(mem_to_reg_in),
    .reg_write_in(reg_write_in),
    .write_back_data(write_back_data),
    .rd_addr_out(rd_addr_out),
    .reg_write_out(reg_write_out)
  );

  initial begin
    $dumpfile("tb_wb_stage.vcd");
    $dumpvars(0, tb_wb_stage);

    read_data_in = 0; alu_result_in = 0; rd_addr_in = 0;
    mem_to_reg_in = 0; reg_write_in = 0;
    #10;

    // SCENARIO 1: Memory to Register (lw)
    read_data_in = 32'hE1E5_FACE; alu_result_in = 32'hB111_1D01;
    rd_addr_in = 5; mem_to_reg_in = 1; reg_write_in = 1;
    
    #1;
    if (write_back_data !== 32'hE1E5_FACE || rd_addr_out !== 5 || reg_write_out !== 1) begin
      $display("ERROR (Scen 1): Memory data not selected or passthrough failed.");
      errors = errors + 1;
    end

    // SCENARIO 2: ALU to Register (R-Type)
    read_data_in = 32'h1960_F11C; alu_result_in = 32'hFEEA_AAAA;
    rd_addr_in = 20; mem_to_reg_in = 0; reg_write_in = 1;
    
    #1;
    if (write_back_data !== 32'hFEEA_AAAA || rd_addr_out !== 20 || reg_write_out !== 1) begin
      $display("ERROR (Scen 2): ALU data not selected or passthrough failed.");
      errors = errors + 1;
    end

    // SCENARIO 3: Non-Writing Instruction (Store/Branch)
    read_data_in = 32'h6000_0057; alu_result_in = 32'hB000_57EA;
    rd_addr_in = 0; mem_to_reg_in = 0; reg_write_in = 0;
    
    #1;
    if (write_back_data !== 32'hB000_57EA || rd_addr_out !== 0 || reg_write_out !== 0) begin
      $display("ERROR (Scen 3): Store/Branch passthrough failed.");
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