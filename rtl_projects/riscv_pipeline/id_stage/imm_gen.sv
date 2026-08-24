`timescale 1ns/1ps

module imm_gen (
  input  logic [31:0] instruction,
  output logic [31:0] imm_ext
);
  
  logic [6:0] opcode;
  assign opcode = instruction[6:0];
  
  always @(*) begin
    case (opcode)
      // I-Type (addi, slti, xori, ori, andi, lw)
      7'b0010011, 7'b0000011: begin
        imm_ext = {{20{instruction[31]}}, instruction[31:20]};
      end
      
      // S-Type (sw)
      7'b0100011: begin
        imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
      end
      
      // B-Type (beq, bne)
      7'b1100011: begin             
        imm_ext = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
      end
      
      // Default (R-Type or unknown)
      // Note: J-type and U-type formats (jal, jalr, lui, auipc) are deliberately unhandled — out of scope for this 18-instruction subset.
      default: begin                
        imm_ext = 32'b0;
      end
    endcase
  end
    
endmodule