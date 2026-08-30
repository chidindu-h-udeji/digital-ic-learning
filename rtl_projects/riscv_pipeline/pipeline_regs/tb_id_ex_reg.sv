`timescale 1ns/1ps

module tb_id_ex_reg;
  logic        clk = 0, reset, flush, stall;
  logic        reg_write_in, alu_src_in, mem_read_in, mem_write_in, mem_to_reg_in, branch_in;
  logic        reg_write_out, alu_src_out, mem_read_out, mem_write_out, mem_to_reg_out, branch_out;
  logic [2:0]  funct3_in, funct3_out;
  logic [4:0]  rs1_addr_in, rs2_addr_in, rd_addr_in, rs1_addr_out, rs2_addr_out, rd_addr_out;
  logic [6:0]  funct7_in, funct7_out, opcode_in, opcode_out;
  logic [31:0] pc_in, rs1_data_in, rs2_data_in, imm_ext_in;
  logic [31:0] pc_out, rs1_data_out, rs2_data_out, imm_ext_out;
  
  integer errors = 0; // Error counter
  
  id_ex_reg dut (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .stall(stall),
    .pc_in(pc_in),
    .rs1_data_in(rs1_data_in),
    .rs2_data_in(rs2_data_in),
    .rs1_addr_in(rs1_addr_in),
    .rs2_addr_in(rs2_addr_in),
    .rd_addr_in(rd_addr_in),
    .imm_ext_in(imm_ext_in),
    .funct3_in(funct3_in),
    .funct7_in(funct7_in),
    .opcode_in(opcode_in),
    .pc_out(pc_out),
    .rs1_data_out(rs1_data_out),
    .rs2_data_out(rs2_data_out),
    .rs1_addr_out(rs1_addr_out),
    .rs2_addr_out(rs2_addr_out),
    .rd_addr_out(rd_addr_out),
    .imm_ext_out(imm_ext_out),
    .funct3_out(funct3_out),
    .funct7_out(funct7_out),
    .opcode_out(opcode_out),
    .reg_write_in(reg_write_in), 
    .alu_src_in(alu_src_in), 
    .mem_read_in(mem_read_in), 
    .mem_write_in(mem_write_in), 
    .mem_to_reg_in(mem_to_reg_in), 
    .branch_in(branch_in),
    .reg_write_out(reg_write_out), 
    .alu_src_out(alu_src_out), 
    .mem_read_out(mem_read_out), 
    .mem_write_out(mem_write_out), 
    .mem_to_reg_out(mem_to_reg_out), 
    .branch_out(branch_out)
  );
  
  always #5 clk = ~clk; // 10ns clock
  
  initial begin
    $dumpfile("tb_id_ex_reg.vcd");
    $dumpvars(0, tb_id_ex_reg);
    
    reset = 1; flush = 0; stall = 0;
    pc_in = 32'h600D_CA5E; imm_ext_in = 32'hDACC9167; rs1_data_in = 32'hC00C_D1E7; rs2_data_in = 32'hFEED_D1E7; rs1_addr_in = 1; rs2_addr_in = 2; rd_addr_in = 3; funct3_in = 2; funct7_in = 6; opcode_in = 7'h13;
    reg_write_in = 1; alu_src_in = 1; mem_read_in = 1; mem_write_in = 1; mem_to_reg_in = 1; branch_in = 1;
    
    #12; 
    reset = 0;
    
    // SCENARIO 1: Normal flow
    pc_in = 32'hD0D0_B1DD; imm_ext_in = 32'hCA57_7EAA; rs1_data_in = 32'hC8D8_F868; rs2_data_in = 32'hB100_57A7; rs1_addr_in = 4; rs2_addr_in = 3; rd_addr_in = 2; funct3_in = 1; funct7_in = 0; opcode_in = 7'h23;
    reg_write_in = 1; alu_src_in = 1; mem_read_in = 1; mem_write_in = 1; mem_to_reg_in = 1; branch_in = 1;
    
    @(negedge clk); 
    if (pc_out !== 32'hD0D0_B1DD || imm_ext_out !== 32'hCA57_7EAA || rs1_data_out !== 32'hC8D8_F868 || rs2_data_out !== 32'hB100_57A7 || rs1_addr_out !== 4 || rs2_addr_out !== 3 || rd_addr_out !== 2 || funct3_out !== 1 || funct7_out !== 0 || opcode_out !== 7'h23 || {reg_write_out, alu_src_out, mem_read_out, mem_write_out, mem_to_reg_out, branch_out} !== 6'b111111) begin
      $display("ERROR (Scen 1): Normal pipeline flow failed on one or more ports");
      errors = errors + 1;
    end
    
    // SCENARIO 2: Stall
    stall = 1;
    pc_in = 32'hA5CE_DEAD; imm_ext_in = 32'hBEA7_4FEE; rs1_data_in = 32'h533D_5EED; rs2_data_in = 32'h2026_AD55; rs1_addr_in = 5; rs2_addr_in = 6; rd_addr_in = 7; funct3_in = 2; funct7_in = 3; opcode_in = 7'h13;
    reg_write_in = 0; alu_src_in = 0; mem_read_in = 0; mem_write_in = 1; mem_to_reg_in = 0; branch_in = 1;
    
    @(negedge clk); 
    if (pc_out !== 32'hD0D0_B1DD || imm_ext_out !== 32'hCA57_7EAA || rs1_data_out !== 32'hC8D8_F868 || rs2_data_out !== 32'hB100_57A7 || rs1_addr_out !== 4 || rs2_addr_out !== 3 || rd_addr_out !== 2 || funct3_out !== 1 || funct7_out !== 0 || opcode_out !== 7'h23 || {reg_write_out, alu_src_out, mem_read_out, mem_write_out, mem_to_reg_out, branch_out} !== 6'b111111) begin
      $display("ERROR (Scen 2): Stall failed, output changed");
      errors = errors + 1;
    end
    
    // SCENARIO 3: Priority Conflict (Flush > Stall)
    flush = 1;
    
    @(negedge clk); 
    if ({reg_write_out, alu_src_out, mem_read_out, mem_write_out, mem_to_reg_out, branch_out} !== 6'b0) begin
      $display("ERROR (Scen 3): Flush failed to override stall (control signals not zeroed)");
      errors = errors + 1;
    end
    if (pc_out !== 32'hD0D0_B1DD || imm_ext_out !== 32'hCA57_7EAA || rs1_data_out !== 32'hC8D8_F868 || rs2_data_out !== 32'hB100_57A7 || rs1_addr_out !== 4 || rs2_addr_out !== 3 || rd_addr_out !== 2 || funct3_out !== 1 || funct7_out !== 0 || opcode_out !== 7'h23) begin
      $display("ERROR (Scen 3): Data failed to hold during flush");
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