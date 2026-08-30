`timescale 1ns/1ps

module tb_id_stage;
  logic        reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch;
  logic [2:0]  funct3;
  logic [4:0]  rs1_addr, rs2_addr, rd_addr;
  logic [6:0]  funct7, opcode_out;
  logic [31:0] instruction, pc, rs1_data, rs2_data, imm_ext, pc_out, rs1_data_out, rs2_data_out;
  
  integer errors = 0; // Error counter
  
  id_stage dut (
    .instruction(instruction),
    .pc(pc),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rd_addr(rd_addr),
    .imm_ext(imm_ext),
    .funct3(funct3),
    .funct7(funct7),
    .opcode_out(opcode_out),
    .pc_out(pc_out),
    .rs1_data_out(rs1_data_out),
    .rs2_data_out(rs2_data_out),
    .reg_write(reg_write), 
    .alu_src(alu_src), 
    .mem_read(mem_read), 
    .mem_write(mem_write), 
    .mem_to_reg(mem_to_reg), 
    .branch(branch)
  );
  
  initial begin
    $dumpfile("tb_id_stage.vcd");
    $dumpvars(0, tb_id_stage);
    
    pc = 32'h00000040;
    rs1_data = 32'hABBA600D;
    rs2_data = 32'h70706A55;
    
    // SCENARIO 1: R-Type
    instruction = 32'h003100B3; // add x1, x2, x3
    #10;
    if (rs1_addr !== 2 || rs2_addr !== 3 || rd_addr !== 1 || funct3 !== 0 || funct7 !== 0 || opcode_out !== 7'h33) begin
      $display("ERROR (Scen 1): Instruction slicing failed");
      errors = errors + 1;
    end
    if (imm_ext !== 32'h00000000) begin
      $display("ERROR (Scen 1): Immediate failed, got %h", imm_ext);
      errors = errors + 1;
    end
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b100000) begin
      $display("ERROR (Scen 1): Control signals failed");
      errors = errors + 1;
    end
    if (pc_out !== 32'h00000040 || rs1_data_out !== 32'hABBA600D || rs2_data_out !== 32'h70706A55) begin
      $display("ERROR (Scen 1): Pass-through signals failed");
      errors = errors + 1;
    end
    
    // SCENARIO 2: I-Type
    instruction = 32'hFF600293; // addi x5, x0, -10
    #10;
    if (rs1_addr !== 0 || rd_addr !== 5 || funct3 !== 0 || opcode_out !== 7'h13) begin
      $display("ERROR (Scen 2): Instruction slicing failed (rs1, rd, funct3)");
      errors = errors + 1;
    end
    if (imm_ext !== 32'hFFFFFFF6) begin
      $display("ERROR (Scen 2): Immediate failed, got %h", imm_ext);
      errors = errors + 1;
    end
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b110000) begin
      $display("ERROR (Scen 2): Control signals failed");
      errors = errors + 1;
    end
    
    // SCENARIO 3: S-Type
    instruction = 32'h00502623; // sw x5, 12(x0)
    #10;
    if (rs1_addr !== 0 || rs2_addr !== 5 || funct3 !== 2 || opcode_out !== 7'h23) begin
      $display("ERROR (Scen 3): Instruction slicing failed (rs1, rs2, funct3)");
      errors = errors + 1;
    end
    if (imm_ext !== 32'h0000000C) begin
      $display("ERROR (Scen 3): Immediate failed, got %h", imm_ext);
      errors = errors + 1;
    end
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b010100) begin
      $display("ERROR (Scen 3): Control signals failed");
      errors = errors + 1;
    end
    
    // SCENARIO 4: Load
    instruction = 32'h01002283; // lw x5, 16(x0)
    #10;
    if (rs1_addr !== 0 || rd_addr !== 5 || funct3 !== 2 || opcode_out !== 7'h03) begin
      $display("ERROR (Scen 4): Instruction slicing failed (rs1, rs2, funct3)");
      errors = errors + 1;
    end
    if (imm_ext !== 32'h00000010) begin
      $display("ERROR (Scen 4): Immediate failed, got %h", imm_ext);
      errors = errors + 1;
    end
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b111010) begin
      $display("ERROR (Scen 4): Control signals failed");
      errors = errors + 1;
    end
    
    // SCENARIO 5: Branch
    instruction = 32'h00500863; // beq x0, x5, 16
    #10;
    if (rs1_addr !== 0 || rs2_addr !== 5 || funct3 !== 0 || opcode_out !== 7'h63) begin
      $display("ERROR (Scen 5): Instruction slicing failed (rs1, rs2, funct3)");
      errors = errors + 1;
    end
    if (imm_ext !== 32'h00000010) begin
      $display("ERROR (Scen 5): Immediate failed, got %h", imm_ext);
      errors = errors + 1;
    end
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b000001) begin
      $display("ERROR (Scen 5): Control signals failed");
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