`timescale 1ns/1ps

module tb_control_unit;
  logic [6:0] opcode;
  logic       reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch;
  
  integer errors = 0; // Error counter
  
  control_unit dut (
    .opcode(opcode),
    .reg_write(reg_write),
    .alu_src(alu_src),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .branch(branch)
  );
  
  initial begin
    $dumpfile("tb_control_unit.vcd");
    $dumpvars(0, tb_control_unit);
    
    // SCENARIO 1: R-Type
    opcode = 7'b0110011;
    #10;
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b100000) begin
      $display("ERROR (Scen 1): Expected 6'b100000, got %b", {reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch});
      errors = errors + 1;
    end
    
    // SCENARIO 2: I-Type ALU
    opcode = 7'b0010011;
    #10;
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b110000) begin
      $display("ERROR (Scen 2): Expected 6'b110000, got %b", {reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch});
      errors = errors + 1;
    end
    
    // SCENARIO 3: Load
    opcode = 7'b0000011;
    #10;
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b111010) begin
      $display("ERROR (Scen 3): Expected 6'b111010, got %b", {reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch});
      errors = errors + 1;
    end
    
    // SCENARIO 4: Store
    opcode = 7'b0100011;
    #10;
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b010100) begin
      $display("ERROR (Scen 4): Expected 6'b010100, got %b", {reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch});
      errors = errors + 1;
    end
    
    // SCENARIO 5: Branch
    opcode = 7'b1100011;
    #10;
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b000001) begin
      $display("ERROR (Scen 5): Expected 6'b000001, got %b", {reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch});
      errors = errors + 1;
    end
    
    // SCENARIO 6: Unknown/Garbage
    opcode = 7'b1111111;
    #10;
    if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} !== 6'b000000) begin
      $display("ERROR (Scen 6): Expected 6'b000000, got %b", {reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch});
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