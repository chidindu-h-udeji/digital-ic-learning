`timescale 1ns/1ps

module tb_ex_stage;
  logic        alu_src, branch, branch_taken;
  logic [2:0]  funct3;
  logic [6:0]  funct7, opcode;
  logic [31:0] pc, rs1_data, rs2_data, imm_ext, alu_result, branch_target;

  integer errors = 0; // Error counter

  ex_stage dut (
    .pc(pc),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .imm_ext(imm_ext),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .alu_src(alu_src),
    .branch(branch),
    .alu_result(alu_result),
    .branch_target(branch_target),
    .branch_taken(branch_taken)
  );

  initial begin
    $dumpfile("tb_ex_stage.vcd");
    $dumpvars(0, tb_ex_stage);
    
    // SCENARIO 1: R-Type ADD (25 + 10 = 35)
    pc = 0; imm_ext = 0; branch = 0; alu_src = 0;
    opcode = 7'h33; funct3 = 3'b000; funct7 = 7'b0000000;
    rs1_data = 25; rs2_data = 10;
    #10;
    if (alu_result !== 35 || branch_taken !== 0) begin
      $display("ERROR (Scen 1): R-Type ADD failed. Got %0d", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 2: R-Type SUB (25 - 10 = 15)
    opcode = 7'h33; funct3 = 3'b000; funct7 = 7'b0100000; // Bit 5 is 1
    rs1_data = 25; rs2_data = 10;
    #10;
    if (alu_result !== 15) begin
      $display("ERROR (Scen 2): R-Type SUB failed. Got %0d", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 3: R-Type SLT (The Signed Trap: -5 < 10)
    opcode = 7'h33; funct3 = 3'b010; funct7 = 7'b0000000;
    rs1_data = 32'hFFFFFFFB; // -5 in two's complement
    rs2_data = 10;
    #10;
    if (alu_result !== 1) begin
      $display("ERROR (Scen 3): R-Type SLT failed. Got %0d", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 4: R-Type SLL
    opcode = 7'h33; funct3 = 3'b001; funct7 = 7'b0000000; alu_src = 0;
    rs1_data = 32'h0000000F; rs2_data = 4;
    #10;
    if (alu_result !== 32'h000000F0) begin
      $display("ERROR (Scen 4): R-Type SLL failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 5: R-Type XOR
    opcode = 7'h33; funct3 = 3'b100; funct7 = 7'b0000000; alu_src = 0;
    rs1_data = 32'hAAAA5555; rs2_data = 32'hFFFF0000;
    #10;
    if (alu_result !== 32'h55555555) begin
      $display("ERROR (Scen 5): R-Type XOR failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 6: R-Type SRL (Logical Shift Right)
    opcode = 7'h33; funct3 = 3'b101; funct7 = 7'b0000000; alu_src = 0;
    rs1_data = 32'hFFFFFFFF; rs2_data = 4;
    #10;
    if (alu_result !== 32'h0FFFFFFF) begin
      $display("ERROR (Scen 6): R-Type SRL failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 7: R-Type SRA (Arithmetic Shift Right)
    opcode = 7'h33; funct3 = 3'b101; funct7 = 7'b0100000; alu_src = 0;
    rs1_data = 32'hFFFFFFFF; rs2_data = 4;
    #10;
    if (alu_result !== 32'hFFFFFFFF) begin
      $display("ERROR (Scen 7): R-Type SRA failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 8: R-Type OR
    opcode = 7'h33; funct3 = 3'b110; funct7 = 7'b0000000; alu_src = 0;
    rs1_data = 32'hAAAA0000; rs2_data = 32'h00005555;
    #10;
    if (alu_result !== 32'hAAAA5555) begin
      $display("ERROR (Scen 8): R-Type OR failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 9: R-Type AND
    opcode = 7'h33; funct3 = 3'b111; funct7 = 7'b0000000; alu_src = 0;
    rs1_data = 32'hF0F0F0F0; rs2_data = 32'h12345678;
    #10;
    if (alu_result !== 32'h10305070) begin
      $display("ERROR (Scen 9): R-Type AND failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 10: I-Type ADDI
    // Opcode forces ADD, ignores funct7
    opcode = 7'h13; funct3 = 3'b000; funct7 = 7'b0100000; alu_src = 1;
    rs1_data = 50; imm_ext = 20;
    #10;
    if (alu_result !== 70) begin
      $display("ERROR (Scen 10): I-Type ADDI failed. Got %0d (Expected 70)", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 11: I-Type SLTI (The Signed Trap)
    opcode = 7'h13; funct3 = 3'b010; funct7 = 7'b0000000; alu_src = 1;
    rs1_data = 32'hFFFFFFFF; imm_ext = 5;
    #10;
    if (alu_result !== 32'h00000001) begin
      $display("ERROR (Scen 11): I-Type SLTI failed. Got %0d", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 12: I-Type XORI
    opcode = 7'h13; funct3 = 3'b100; funct7 = 7'b0000000; alu_src = 1;
    rs1_data = 32'hF0F0F0F0; imm_ext = 32'h0F0F0F0F;
    #10;
    if (alu_result !== 32'hFFFFFFFF) begin
      $display("ERROR (Scen 12): I-Type XORI failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 13: I-Type ORI
    opcode = 7'h13; funct3 = 3'b110; funct7 = 7'b0000000; alu_src = 1;
    rs1_data = 32'h12340000; imm_ext = 32'h00005678;
    #10;
    if (alu_result !== 32'h12345678) begin
      $display("ERROR (Scen 13): I-Type ORI failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 14: I-Type ANDI
    opcode = 7'h13; funct3 = 3'b111; funct7 = 7'b0000000; alu_src = 1;
    rs1_data = 32'hFFFFFFFF; imm_ext = 32'h000000FF;
    #10;
    if (alu_result !== 32'h000000FF) begin
      $display("ERROR (Scen 14): I-Type ANDI failed. Got %h", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 15: Load/Store
    opcode = 7'h03; funct3 = 3'b010; alu_src = 1;
    rs1_data = 100; imm_ext = 4;
    #10;
    if (alu_result !== 104) begin
      $display("ERROR (Scen 15): Load failed to use ADD. Got %0d", alu_result);
      errors = errors + 1;
    end

    // SCENARIO 16a: Branch BEQ (Taken)
    opcode = 7'h63; funct3 = 3'b000; branch = 1; alu_src = 0;
    pc = 32'h00000100; imm_ext = 32'h00000010;
    rs1_data = 42; rs2_data = 42;
    #10;
    if (branch_target !== 32'h00000110 || branch_taken !== 1) begin
      $display("ERROR (Scen 16a): Branch BEQ taken failed");
      errors = errors + 1;
    end

    // SCENARIO 16b: Branch BEQ (Not Taken)
    rs2_data = 43; // unequal
    #10;
    if (branch_taken !== 0) begin
      $display("ERROR (Scen 16b): Branch BEQ not taken failed");
      errors = errors + 1;
    end

    // SCENARIO 17: Branch BNE (Branch Not Equal)
    opcode = 7'h63; funct3 = 3'b001; branch = 1; alu_src = 0;
    rs1_data = 10; rs2_data = 20;
    #10;
    if (branch_taken !== 1) begin
      $display("ERROR (Scen 17): Branch BNE failed to take jump.");
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