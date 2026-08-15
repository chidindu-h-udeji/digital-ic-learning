`timescale 1ns/1ps

module tb_mem_wb_reg;
  logic        clk = 0, reset;
  logic        mem_to_reg_in, reg_write_in, mem_to_reg_out, reg_write_out;
  logic [4:0]  rd_addr_in, rd_addr_out;
  logic [31:0] read_data_in, alu_result_in, read_data_out, alu_result_out;

  integer errors = 0; // Error counter

  mem_wb_reg dut (
    .clk(clk),
    .reset(reset),
    .read_data_in(read_data_in),
    .alu_result_in(alu_result_in),
    .rd_addr_in(rd_addr_in),
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
    $dumpfile("tb_mem_wb_reg.vcd");
    $dumpvars(0, tb_mem_wb_reg);

    reset = 1;
    read_data_in = 32'h1A1A_1ADD; alu_result_in = 32'hF001_601D; 
    rd_addr_in = 31; mem_to_reg_in = 1; reg_write_in = 1;
    
    // SCENARIO 1: Reset
    @(negedge clk);
    if (read_data_out !== 0 || alu_result_out !== 0 || rd_addr_out !== 0 || mem_to_reg_out !== 0 || reg_write_out !== 0) begin
      $display("ERROR (Scen 1): Expected reset output (0)");
      errors = errors + 1;
    end

    // SCENARIO 2: Load Word Latch
    reset = 0;
    read_data_in = 32'h0CEA_E1E5; alu_result_in = 32'hB111_1EE1;
    rd_addr_in = 10; mem_to_reg_in = 1; reg_write_in = 1;
    
    @(negedge clk);
    if (read_data_out !== 32'h0CEA_E1E5 || alu_result_out !== 32'hB111_1EE1 || rd_addr_out !== 10 || mem_to_reg_out !== 1 || reg_write_out !== 1) begin
      $display("ERROR (Scen 2): Load Word latch failed. Outputs do not match inputs.");
      errors = errors + 1;
    end

    // SCENARIO 3: R-Type Latch
    read_data_in = 32'h71CC_7ACC; alu_result_in = 32'hFEE1_F335;
    rd_addr_in = 20; mem_to_reg_in = 0; reg_write_in = 1;
    
    @(negedge clk);
    if (read_data_out !== 32'h71CC_7ACC || alu_result_out !== 32'hFEE1_F335 || rd_addr_out !== 20 || mem_to_reg_out !== 0 || reg_write_out !== 1) begin
      $display("ERROR (Scen 3): R-Type latch failed. Outputs did not update correctly.");
      errors = errors + 1;
    end

    // SCENARIO 4: Store/Branch Latch
    read_data_in = 32'hBA77_CAFE; alu_result_in = 32'hD00D_C0DE;
    rd_addr_in = 0; mem_to_reg_in = 0; reg_write_in = 0;
    
    @(negedge clk);
    if (read_data_out !== 32'hBA77_CAFE || alu_result_out !== 32'hD00D_C0DE || rd_addr_out !== 0 || mem_to_reg_out !== 0 || reg_write_out !== 0) begin
      $display("ERROR (Scen 4): Store/Branch latch failed. reg_write_out should be 0.");
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