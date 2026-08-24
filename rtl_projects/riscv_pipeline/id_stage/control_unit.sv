`timescale 1ns/1ps

module control_unit (
  input  logic [6:0] opcode,
  output logic       reg_write,
  output logic       alu_src,
  output logic       mem_read,
  output logic       mem_write,
  output logic       mem_to_reg,
  output logic       branch
);

  always @(*) begin
    // Default all signals to 0 to prevent accidental latches
    {reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch} = 6'b0;
    
    case (opcode)
      // R-Type (add, sub, sll, slt, xor, srl, sra, or, and)
      7'b0110011: begin 
        reg_write  = 1'b1;
      end
      
      // I-Type ALU (addi, slti, xori, ori, andi)
      7'b0010011: begin 
        reg_write  = 1'b1;
        alu_src    = 1'b1;
      end
      
      // Load (lw)
      7'b0000011: begin 
        reg_write  = 1'b1;
        alu_src    = 1'b1;
        mem_read   = 1'b1;
        mem_to_reg = 1'b1;
      end
      
      // Store (sw)
      7'b0100011: begin 
        alu_src    = 1'b1;
        mem_write  = 1'b1;
      end
      
      // Branch (beq, bne)
      7'b1100011: begin 
        branch     = 1'b1;
      end
      
      // Default catches all unknown opcodes (outputs remain 0)
      default: ; 
    endcase
  end
    
endmodule