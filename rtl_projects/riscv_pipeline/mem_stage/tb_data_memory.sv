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

    mem_read = 0; mem_write = 0; addr = 0; write_data = 0;
    #12;

    // SCENARIO 1: Read pre-loaded data (lw)
    addr = 4; mem_read = 1; mem_write = 0;
    
    #1;
    if (read_data !== 32'h0915ACFC) begin
      $display("ERROR (Scen 1): Expected 0915ACFC at addr 4, got %h", read_data);
      errors = errors + 1;
    end

    // SCENARIO 2: Write new data (sw) & Read back
    @(negedge clk);
    addr = 12; write_data = 32'hF157_A1DD; 
    mem_read = 0; mem_write = 1;
    
    @(negedge clk);
    addr = 12; mem_read = 1; mem_write = 0;
    #1;
    if (read_data !== 32'hF157_A1DD) begin
      $display("ERROR (Scen 2): Write-then-read failed. Got %h", read_data);
      errors = errors + 1;
    end
    
    // SCENARIO 3: Write Disable
    @(negedge clk);
    addr = 12; write_data = 32'hBADD_C0DE;
    mem_read = 0; mem_write = 0;
    
    @(negedge clk);
    addr = 12; mem_read = 1; mem_write = 0;
    #1;
    if (read_data !== 32'hF157_A1DD) begin
      $display("ERROR (Scen 3): Write disable failed. Data corrupted. Got %h", read_data);
      errors = errors + 1;
    end

    // SCENARIO 4: Read Disable
    mem_read = 0;
    #1;
    if (read_data !== 0) begin
      $display("ERROR (Scen 4): read_data should be 0 when mem_read is low");
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