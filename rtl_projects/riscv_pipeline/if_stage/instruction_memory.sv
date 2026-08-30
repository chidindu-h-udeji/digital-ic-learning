`timescale 1ns/1ps

module instruction_memory (
  input  logic [31:0] addr,
  output logic [31:0] instruction
);

  // 1KB Memory Array: 256 words, each 32 bits wide
  logic [31:0] mem [0:255];

  // Load machine code from hex file at time zero
  // (Synthesizers recognize this as a request to initialize BRAM/ROM)
  initial begin
    $readmemh("program.hex", mem);
  end

  // Combinational read: Drop bottom 2 bits (addr[1:0]) to convert 
  // RISC-V byte address to SystemVerilog word index (divide by 4).
  // Extract bits [9:2] because a 256-word array requires an 8-bit index.
  assign instruction = mem[addr[9:2]];

endmodule