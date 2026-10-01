`timescale 1ns/1ps

module data_memory (
  input  logic        clk,
  input  logic        mem_read,
  input  logic        mem_write,
  input  logic [31:0] addr,
  input  logic [31:0] write_data,
  output logic [31:0] read_data
);

`ifdef __pnr__
  // Active-low macro controls
  wire        csb0   = ~(mem_read | mem_write);
  wire        web0   = ~mem_write;
  wire [3:0]  wmask0 = 4'b1111;
  
  wire [31:0] macro_dout;
  wire [31:0] dummy_dout1; // Terminate unused output port to prevent simulation X artifacts


  sky130_sram_1kbyte_1rw1r_32x256_8 data_mem_macro (
    .clk0(clk),
    .clk1(clk),
    .csb0(csb0),
    .web0(web0),
    .wmask0(wmask0),
    .csb1(1'b1),
    .addr1(8'b0),
    .dout1(dummy_dout1),
    .din0(write_data),
    .dout0(macro_dout),
    .addr0(addr[9:2])
  );

  // Direct bypass (macro provides 1-cycle latency natively)
  assign read_data = macro_dout;

`else
  // Behavioral simulation model
  // 1KB Memory Array (256 words x 32 bits)
  logic [31:0] mem [0:255];
  
  initial begin
    $readmemh("data_mem_init.hex", mem);
  end
  
  always_ff @(posedge clk) begin
    if (mem_write) begin
      mem[addr[9:2]] <= write_data;
    end
    // Synchronous read (holds value when mem_read is low)
    if (mem_read) begin
      read_data <= mem[addr[9:2]];
    end
  end
`endif

endmodule