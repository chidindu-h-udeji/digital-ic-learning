`timescale 1ns/1ps

module riscv_core (
  input  logic clk,
  input  logic reset
);

  // ----------------------------------------------------------------------
  // WIRES & SIGNAL DEFINITIONS
  // ----------------------------------------------------------------------

  // IF Stage Wires
  logic [31:0] if_pc, if_pc_plus4, if_instruction;
  
  // IF/ID Register Wires
  logic [31:0] id_pc, id_pc_plus4, id_instruction;
  
  // ID Stage Wires
  logic        id_reg_write, id_alu_src, id_mem_read, id_mem_write, id_mem_to_reg, id_branch;
  logic [2:0]  id_funct3;
  logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr; 
  logic [6:0]  id_funct7, id_opcode;
  logic [31:0] id_pc_out, id_imm_ext, id_rs1_data, id_rs2_data, id_rs1_data_out, id_rs2_data_out;
  
  // ID/EX Register Wires
  logic        ex_reg_write, ex_alu_src, ex_mem_read, ex_mem_write, ex_mem_to_reg, ex_branch;
  logic [2:0]  ex_funct3;
  logic [4:0]  ex_rs1_addr, ex_rs2_addr, ex_rd_addr;
  logic [6:0]  ex_funct7, ex_opcode;
  logic [31:0] ex_pc, ex_rs1_data, ex_rs2_data, ex_imm_ext;

  // EX Stage Wires
  logic        ex_branch_taken;
  logic [31:0] ex_alu_result, ex_branch_target;
  
  // EX/MEM Register Wires
  logic        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;
  logic [4:0]  mem_rd_addr;
  logic [31:0] mem_alu_result, mem_rs2_data;

  // MEM Stage Wires
  logic        mem2wb_mem_to_reg, mem2wb_reg_write;
  logic [4:0]  mem2wb_rd_addr;
  logic [31:0] mem2wb_read_data, mem2wb_alu_result;

  // MEM/WB Register Wires
  logic        wb_reg_write, wb_mem_to_reg;
  logic [4:0]  wb_rd_addr;
  logic [31:0] wb_alu_result, wb_read_data;

  // WB Stage Wires
  logic        wb_final_reg_write;
  logic [4:0]  wb_final_rd_addr;
  logic [31:0] wb_write_back_data;

  // Hazard & Forwarding Wires
  logic        load_use_stall;
  logic [1:0]  forward_a, forward_b;
  logic [31:0] forwarded_rs1_data, forwarded_rs2_data;

  // ----------------------------------------------------------------------
  // HAZARD & FORWARDING UNITS
  // ----------------------------------------------------------------------
  
  // Detects load-use hazards to trigger pipeline stalls
  hazard_unit hazard_unit_inst (
    .id_ex_mem_read(ex_mem_read),
    .id_ex_rd_addr(ex_rd_addr),
    .id_rs1_addr(id_rs1_addr),
    .id_rs2_addr(id_rs2_addr),
    .stall(load_use_stall)
  );

  // Detects data dependencies for operand forwarding
  forwarding_unit forwarding_unit_inst (
    .ex_rs1_addr(ex_rs1_addr),
    .ex_rs2_addr(ex_rs2_addr),
    .ex_mem_rd_addr(mem_rd_addr),
    .ex_mem_reg_write(mem_reg_write),
    .mem_wb_rd_addr(wb_final_rd_addr),
    .mem_wb_reg_write(wb_final_reg_write),
    .forward_a(forward_a),
    .forward_b(forward_b)
  );

  // Forwarding Multiplexers
  
  // Operand A (rs1): Selects between MEM, WB, or default ID/EX data
  assign forwarded_rs1_data = (forward_a == 2'b10) ? mem_alu_result : ((forward_a == 2'b01) ? wb_write_back_data : ex_rs1_data);
  
  // Operand B (rs2): Selects between MEM, WB, or default ID/EX data
  assign forwarded_rs2_data = (forward_b == 2'b10) ? mem_alu_result : ((forward_b == 2'b01) ? wb_write_back_data : ex_rs2_data);
  
  // ----------------------------------------------------------------------
  // STAGE 1: INSTRUCTION FETCH (IF)
  // ----------------------------------------------------------------------
  if_stage if_stage_inst (
    .clk(clk),
    .reset(reset),
    .stall(load_use_stall),                // Freeze PC on load-use hazard
    .branch_taken(ex_branch_taken),        // Redirect PC on taken branch
    .branch_target(ex_branch_target),      // Target address from EX stage
    .pc_out(if_pc),
    .instruction(if_instruction),
    .pc_plus_4(if_pc_plus4)
  );
  
  // IF/ID Pipeline Register
  if_id_register if_id_reg_inst (
    .clk(clk), 
    .reset(reset),
    .stall(load_use_stall),                // Hold current instruction on load-use hazard
    .flush(ex_branch_taken),               // Clear fetched instruction on branch
    .instruction_in(if_instruction), 
    .pc_in(if_pc), 
    .pc_plus4_in(if_pc_plus4),
    .instruction_out(id_instruction),
    .pc_out(id_pc),
    .pc_plus4_out(id_pc_plus4)
  );
  
  // ----------------------------------------------------------------------
  // STAGE 2: INSTRUCTION DECODE (ID)
  // ----------------------------------------------------------------------
  id_stage id_stage_inst (
    .instruction(id_instruction),
    .pc(id_pc),
    .rs1_data(id_rs1_data),
    .rs2_data(id_rs2_data),
    .rs1_addr(id_rs1_addr),
    .rs2_addr(id_rs2_addr),
    .rd_addr(id_rd_addr),
    .imm_ext(id_imm_ext),
    .funct3(id_funct3),
    .funct7(id_funct7),
    .opcode_out(id_opcode),
    .pc_out(id_pc_out),
    .rs1_data_out(id_rs1_data_out),
    .rs2_data_out(id_rs2_data_out),
    .reg_write(id_reg_write),
    .alu_src(id_alu_src),
    .mem_read(id_mem_read),
    .mem_write(id_mem_write),
    .mem_to_reg(id_mem_to_reg),
    .branch(id_branch)
  );
  
  // Register File
  register_file reg_inst (
    .clk(clk), 
    .reset(reset),
    .reg_write(wb_final_reg_write),        // Loop closure from WB stage
    .rs1_addr(id_rs1_addr),
    .rs2_addr(id_rs2_addr),
    .rd_addr(wb_final_rd_addr),            // Loop closure from WB stage
    .rd_data(wb_write_back_data),          // Loop closure from WB stage
    .rs1_data(id_rs1_data), 
    .rs2_data(id_rs2_data)
  );
  
  // ID/EX Pipeline Register
  id_ex_reg id_ex_reg_inst (
    .clk(clk),
    .reset(reset),
    .flush(ex_branch_taken | load_use_stall), // Inject bubble on branch OR load-use hazard
    .stall(1'b0),                             // Never stalled by stages downstream of ID
    .pc_in(id_pc_out),
    .rs1_data_in(id_rs1_data_out),
    .rs2_data_in(id_rs2_data_out),
    .imm_ext_in(id_imm_ext),
    .rs1_addr_in(id_rs1_addr),
    .rs2_addr_in(id_rs2_addr),
    .rd_addr_in(id_rd_addr),
    .funct3_in(id_funct3),
    .funct7_in(id_funct7),
    .opcode_in(id_opcode),
    .reg_write_in(id_reg_write), 
    .alu_src_in(id_alu_src), 
    .mem_read_in(id_mem_read), 
    .mem_write_in(id_mem_write), 
    .mem_to_reg_in(id_mem_to_reg), 
    .branch_in(id_branch),
    .pc_out(ex_pc),
    .rs1_data_out(ex_rs1_data),
    .rs2_data_out(ex_rs2_data),
    .imm_ext_out(ex_imm_ext),
    .rs1_addr_out(ex_rs1_addr),
    .rs2_addr_out(ex_rs2_addr),
    .rd_addr_out(ex_rd_addr),
    .funct3_out(ex_funct3),
    .funct7_out(ex_funct7),
    .opcode_out(ex_opcode),
    .reg_write_out(ex_reg_write), 
    .alu_src_out(ex_alu_src), 
    .mem_read_out(ex_mem_read), 
    .mem_write_out(ex_mem_write), 
    .mem_to_reg_out(ex_mem_to_reg), 
    .branch_out(ex_branch)
  );
  
  // ----------------------------------------------------------------------
  // STAGE 3: EXECUTE (EX)
  // ----------------------------------------------------------------------
  ex_stage ex_stage_inst (
    .pc(ex_pc),
    .rs1_data(forwarded_rs1_data),         // Data from forwarding mux A
    .rs2_data(forwarded_rs2_data),         // Data from forwarding mux B
    .imm_ext(ex_imm_ext),
    .funct3(ex_funct3),
    .funct7(ex_funct7),
    .opcode(ex_opcode),
    .alu_src(ex_alu_src),
    .branch(ex_branch),
    .alu_result(ex_alu_result),
    .branch_target(ex_branch_target),
    .branch_taken(ex_branch_taken)
  );

  // EX/MEM Pipeline Register
  ex_mem_reg ex_mem_reg_inst (
    .clk(clk),
    .reset(reset),
    .alu_result_in(ex_alu_result),
    .rs2_data_in(forwarded_rs2_data),      // Forwarded data routed for store instructions
    .rd_addr_in(ex_rd_addr),
    .mem_read_in(ex_mem_read),
    .mem_write_in(ex_mem_write),
    .mem_to_reg_in(ex_mem_to_reg),
    .reg_write_in(ex_reg_write),
    .alu_result_out(mem_alu_result),
    .rs2_data_out(mem_rs2_data),
    .rd_addr_out(mem_rd_addr),
    .mem_read_out(mem_mem_read),
    .mem_write_out(mem_mem_write),
    .mem_to_reg_out(mem_mem_to_reg),
    .reg_write_out(mem_reg_write)
  );

  // ----------------------------------------------------------------------
  // STAGE 4: MEMORY (MEM)
  // ----------------------------------------------------------------------
  mem_stage mem_stage_inst (
    .clk(clk),
    .alu_result_in(mem_alu_result),
    .rs2_data_in(mem_rs2_data),
    .rd_addr_in(mem_rd_addr),
    .mem_read_in(mem_mem_read),
    .mem_write_in(mem_mem_write),
    .mem_to_reg_in(mem_mem_to_reg),
    .reg_write_in(mem_reg_write),
    .read_data_out(mem2wb_read_data),
    .alu_result_out(mem2wb_alu_result),
    .rd_addr_out(mem2wb_rd_addr),
    .mem_to_reg_out(mem2wb_mem_to_reg),
    .reg_write_out(mem2wb_reg_write)
  );

  // MEM/WB Pipeline Register
  mem_wb_reg mem_wb_reg_inst (
    .clk(clk),
    .reset(reset),
    .read_data_in(mem2wb_read_data),
    .alu_result_in(mem2wb_alu_result),
    .rd_addr_in(mem2wb_rd_addr),
    .mem_to_reg_in(mem2wb_mem_to_reg),
    .reg_write_in(mem2wb_reg_write),
    .read_data_out(wb_read_data),
    .alu_result_out(wb_alu_result),
    .rd_addr_out(wb_rd_addr),
    .mem_to_reg_out(wb_mem_to_reg),
    .reg_write_out(wb_reg_write)
  );

  // ----------------------------------------------------------------------
  // STAGE 5: WRITEBACK (WB) & REGISTER FILE LOOP CLOSURE
  // ----------------------------------------------------------------------
  wb_stage wb_stage_inst (
    .read_data_in(wb_read_data),
    .alu_result_in(wb_alu_result),
    .rd_addr_in(wb_rd_addr),
    .mem_to_reg_in(wb_mem_to_reg),
    .reg_write_in(wb_reg_write),
    .write_back_data(wb_write_back_data),
    .rd_addr_out(wb_final_rd_addr),
    .reg_write_out(wb_final_reg_write)
  );

endmodule