`timescale 1ns/1ps

module tb_data_memory;
  logic        clk = 0;
  logic        mem_read, mem_write;
  logic [31:0] addr, write_data, read_data;

  integer errors = 0; // Error counter

  data_memory dut (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .addr(addr),
    .write_data(write_data),
    .read_data(read_data)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("tb_data_memory.vcd");
    $dumpvars(0, tb_data_memory);

    `ifdef __pnr__
      // Backdoor array initialization
      $readmemh("data_mem_init.hex", dut.data_mem_macro.mem);
    `endif

    mem_read = 0; mem_write = 0; addr = 0; write_data = 0;
    
    @(negedge clk);

    // SCENARIO 1: Read pre-loaded data
    addr = 4; mem_read = 1; mem_write = 0;
    
    @(posedge clk);
    #9;
    if (read_data !== 32'h0915ACFC) begin
      $display("ERROR (Scen 1): Expected 0915ACFC, got %h", read_data);
      errors = errors + 1;
    end

    // SCENARIO 2: Write and read back
    @(negedge clk);
    addr = 12; write_data = 32'hF157_A1DD; 
    mem_read = 0; mem_write = 1;
    
    @(negedge clk);
    addr = 12; mem_read = 1; mem_write = 0;
    
    @(posedge clk);
    #9;
    if (read_data !== 32'hF157_A1DD) begin
      $display("ERROR (Scen 2): Write-read failed. Got %h", read_data);
      errors = errors + 1;
    end
    
    // SCENARIO 3: Write disable
    @(negedge clk);
    addr = 12; write_data = 32'hBADD_C0DE;
    mem_read = 0; mem_write = 0;
    
    @(negedge clk);
    addr = 12; mem_read = 1; mem_write = 0;
    
    @(posedge clk);
    #9;
    if (read_data !== 32'hF157_A1DD) begin
      $display("ERROR (Scen 3): Write disable failed. Got %h", read_data);
      errors = errors + 1;
    end

    // SCENARIO 4: Read disable (hold previous)
    @(negedge clk);
    mem_read = 0;
    
    `ifndef __pnr__
    @(posedge clk);
    #9;
    if (read_data !== 32'hF157_A1DD) begin
      $display("ERROR (Scen 4): Hold failed. Got %h", read_data);
      errors = errors + 1;
    end
    `endif

    if (errors == 0)
      $display("VERIFICATION PASSED! Errors: 0");
    else begin
      $display("VERIFICATION FAILED! Errors: %0d", errors);
    end

    $finish;
  end
endmodule