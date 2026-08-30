`timescale 1ns/1ps

module hazard_unit (
  input  logic       id_ex_mem_read,
  input  logic [4:0] id_ex_rd_addr,
  input  logic [4:0] id_rs1_addr,
  input  logic [4:0] id_rs2_addr,
  output logic       stall
);
  
  // Stall if EX is a load, rd is not x0, and rd matches rs1 or rs2
  assign stall = id_ex_mem_read && (id_ex_rd_addr != 0) && ((id_ex_rd_addr == id_rs1_addr) || (id_ex_rd_addr == id_rs2_addr));
    
endmodule