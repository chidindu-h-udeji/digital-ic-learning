`timescale 1ns/1ps

module data_memory (
  input  logic        clk,
  input  logic        mem_read,
  input  logic        mem_write,
  input  logic [31:0] addr,
  input  logic [31:0] write_data,
  output logic [31:0] read_data
);

  // 1KB Memory Array (256 words x 32 bits)
  logic [31:0] mem [0:255];
  
  // Initialize memory with test vectors
  initial begin
    $readmemh("data_mem_init.hex", mem);
  end
  
  always_ff @(posedge clk) begin
    if (mem_write) begin
      mem[addr[9:2]] <= write_data;
    end
  end
  
  assign read_data = (mem_read) ? mem[addr[9:2]] : 32'b0;
  
endmodule