`timescale 1ns/1ps

module edge_detect_tb;

    // Testbench signals
    logic clk;
    logic rst;
    logic din;
    wire  o_pedge_pulse;

    // Clock generation (100 MHz → 10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
    edge_detect dut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .o_pedge_pulse(o_pedge_pulse)
    );

    // Stimulus
    initial begin
        // Init
        rst = 1;
        din = 0;
        #20;
        rst = 0;

        // Keep low for a bit
        #50;

        // Rising edge -> expect pulse
        din = 1; #20;

        // Stay high (no new pulse expected)
        #40;

        // Falling edge (no pulse expected)
        din = 0; #30;

        // Rising edge again -> expect pulse
        din = 1; #20;

        // Stay high
        #40;

        // Falling again
        din = 0; #30;

        // Finish
        #100;
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("edge_detect_tb.vcd");
        $dumpvars(0, edge_detect_tb);
    end

endmodule
