`timescale 1ns/1ps

module ex_stage (
  input  logic [31:0] pc,
  input  logic [31:0] rs1_data,
  input  logic [31:0] rs2_data,
  input  logic [31:0] imm_ext,
  input  logic [2:0]  funct3,
  input  logic [6:0]  funct7,
  input  logic [6:0]  opcode,
  input  logic        alu_src,
  input  logic        branch,
  output logic [31:0] alu_result,
  output logic [31:0] branch_target,
  output logic        branch_taken
);

  logic [3:0]  alu_ctrl;
  logic [31:0] alu_operand_b;

  // ALU Control Decoder
  always @(*) begin
    if (opcode == 7'h33) begin
      // R-Type Instructions (funct7 is valid)
      case (funct3)
        3'b000:  alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB vs ADD
        3'b001:  alu_ctrl = 4'b0010;                         // SLL
        3'b010:  alu_ctrl = 4'b0100;                         // SLT
        3'b011:  alu_ctrl = 4'b0110;                         // SLTU
        3'b100:  alu_ctrl = 4'b1000;                         // XOR
        3'b101:  alu_ctrl = (funct7[5]) ? 4'b1011 : 4'b1010; // SRA vs SRL
        3'b110:  alu_ctrl = 4'b1100;                         // OR
        3'b111:  alu_ctrl = 4'b1110;                         // AND
        default: alu_ctrl = 4'b0000;
      endcase
    end else begin
      // I-Type, Load, Store, etc. (Ignore funct7 completely)
      case (funct3)
        3'b000:  alu_ctrl = 4'b0000; // ADD (e.g., addi, lw, sw)
        3'b001:  alu_ctrl = 4'b0010; // SLLI
        3'b010:  alu_ctrl = 4'b0100; // SLTI
        3'b011:  alu_ctrl = 4'b0110; // SLTIU
        3'b100:  alu_ctrl = 4'b1000; // XORI
        3'b101:  alu_ctrl = 4'b1010; // SRAI / SRLI
        3'b110:  alu_ctrl = 4'b1100; // ORI
        3'b111:  alu_ctrl = 4'b1110; // ANDI
        default: alu_ctrl = 4'b0000;
      endcase
    end
  end

  // Arithmetic Logic Unit (ALU)
  assign alu_operand_b = (alu_src) ? imm_ext : rs2_data;

  always @(*) begin
    case (alu_ctrl)
      4'b0000: alu_result = rs1_data + alu_operand_b;                                     // ADD
      4'b0001: alu_result = rs1_data - alu_operand_b;                                     // SUB
      4'b0010: alu_result = rs1_data << alu_operand_b[4:0];                               // SLL
      4'b0100: alu_result = ($signed(rs1_data) < $signed(alu_operand_b)) ? 32'b1 : 32'b0; // SLT (Signed)
      4'b0110: alu_result = (rs1_data < alu_operand_b) ? 32'b1 : 32'b0;                   // SLTU (Unsigned)
      4'b1000: alu_result = rs1_data ^ alu_operand_b;                                     // XOR
      4'b1010: alu_result = rs1_data >> alu_operand_b[4:0];                               // SRL (Logical Shift)
      4'b1011: alu_result = $signed(rs1_data) >>> alu_operand_b[4:0];                     // SRA (Arithmetic Shift)
      4'b1100: alu_result = rs1_data | alu_operand_b;                                     // OR
      4'b1110: alu_result = rs1_data & alu_operand_b;                                     // AND
      default: alu_result = 32'b0;
    endcase
  end

  // Branch Comparator & Target
  assign branch_target = pc + imm_ext;
  always @(*) begin
    branch_taken = 1'b0;
    
    if (branch) begin
      case (funct3)
        3'b000:  branch_taken = (rs1_data == rs2_data);                   // BEQ
        3'b001:  branch_taken = (rs1_data != rs2_data);                   // BNE
        3'b100:  branch_taken = ($signed(rs1_data) < $signed(rs2_data));  // BLT
        3'b101:  branch_taken = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
        3'b110:  branch_taken = (rs1_data < rs2_data);                    // BLTU
        3'b111:  branch_taken = (rs1_data >= rs2_data);                   // BGEU
        default: branch_taken = 1'b0;
      endcase
    end
  end

endmodule