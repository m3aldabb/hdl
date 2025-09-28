`timescale 1ns/1ps

module clk_divider_tb;

// Parameters
parameter CLK_PERIOD = 10;  // 100 MHz clock
parameter DIV = 5;

// Signals
logic rst;
logic clk_in;
wire clk_out;

// Instantiate DUT
clk_divider #(.DIV(DIV)) dut (
  .rst(rst),
  .clk_in(clk_in),
  .clk_out(clk_out)
);

// Clock generation
initial clk_in = 0;
always #(CLK_PERIOD/2) clk_in = ~clk_in;

// Reset and simulation
initial begin
  rst = 1;
  #(5*CLK_PERIOD);
  rst = 0;

  #(200*CLK_PERIOD);
  $finish;
end

// VCD dump for GTKWave
initial begin
  $dumpfile("clk_divider_tb.vcd");
  $dumpvars(0, clk_divider_tb);
end

endmodule
