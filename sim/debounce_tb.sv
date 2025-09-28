`timescale 1ns/1ps

module debounce_tb;


// Parameters
parameter DIV = 4;

// Testbench signals
logic clk;
logic rst;
logic din;
wire dout;

// Clock generation (100 MHz => 10 ns period)
initial clk = 0;
always #5 clk = ~clk;

// DUT
debounce #(
    .DIV(DIV)   // << make small for simulation
) dut (
    .clk(clk),
    .rst(rst),
    .din(din),
    .dout(dout)
);

// Stimulus
initial begin
    // Init
    rst = 1;
    din = 0;
    #50;
    rst = 0;

    // Hold low for a while
    #100;

    // Simulate bouncing input when pressing
    repeat (5) begin
        din = 1; #15;
        din = 0; #10;
    end
    din = 1;  // finally pressed stable
    #200;

    // Simulate bouncing input when releasing
    repeat (5) begin
        din = 0; #12;
        din = 1; #8;
    end
    din = 0;  // finally released stable
    #200;

    // Finish
    $finish;
end

// Optional waveform dump for GTKWave
initial begin
    $dumpfile("debounce_tb.vcd");
    $dumpvars(0, debounce_tb);
end

endmodule
