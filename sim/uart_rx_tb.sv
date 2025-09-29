`timescale 1ns/1ps

module uart_rx_tb;

// =====================================
// Parameters
// =====================================
localparam  CLK_RATE       = 100_000_000;      // 100 MHz
parameter   BAUD_RATE      = 9600;
parameter   NCLKS_PER_BIT  = CLK_RATE / BAUD_RATE;

parameter   NUM_TEST_BYTES = 20; // Number of random bytes to test

// DUT signals
logic        clk;
logic        rst;
logic        i_rx_data;
wire  [7:0]  o_rx_data;
wire         o_rx_valid;

// DUT instance
uart_rx #(
    .CLK_RATE(CLK_RATE),
    .BAUD_RATE(BAUD_RATE)
) dut (
    .clk        (clk),
    .rst        (rst),
    .o_rx_data  (o_rx_data),
    .o_rx_valid (o_rx_valid),
    .i_rx_data  (i_rx_data)
);

// =====================================
// Clock generation
// =====================================
initial clk = 0;
always #5 clk = ~clk; // 100 MHz -> 10 ns period

// =====================================
// Task: send a UART byte (8N1)
// =====================================
task send_uart_byte(input [7:0] data);
    integer i;
    begin
        // Start bit
        i_rx_data = 0;
        #(NCLKS_PER_BIT*10);

        // Data bits (LSB first)
        for (i = 0; i < 8; i++) begin
            i_rx_data = data[i];
            #(NCLKS_PER_BIT*10);
        end

        // Stop bit
        i_rx_data = 1;
        #(NCLKS_PER_BIT*10);
    end
endtask

// =====================================
// Test Stimulus
// =====================================

logic [7:0] expected_bytes [0:NUM_TEST_BYTES-1];

initial begin
    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, uart_rx_tb);

    // Reset sequence
    rst = 1;
    i_rx_data = 1; // idle high
    repeat(10) @(posedge clk);
    rst = 0;

    // Small wait after reset
    #(NCLKS_PER_BIT*20);

    // Generate random bytes
    for (int i = 0; i < NUM_TEST_BYTES; i++) begin
        expected_bytes[i] = $urandom_range(0, 255);
    end

    // Transmit bytes
    for (int i = 0; i < NUM_TEST_BYTES; i++) begin
        send_uart_byte(expected_bytes[i]);

        // Optional: random gap between bytes
        #(NCLKS_PER_BIT*($urandom_range(1, 5)));
    end

    // Wait some cycles for last byte to be received
    #(NCLKS_PER_BIT*50);

    $display("[%0t] Simulation finished", $time);
    $finish;
end

// =====================================
// Self-checking monitor
// =====================================
int recv_count = 0;

always @(posedge clk) begin
    if (o_rx_valid) begin
        if (recv_count < NUM_TEST_BYTES) begin
            if (o_rx_data === expected_bytes[recv_count]) begin
                $display("[%0t] PASS: Received 0x%0h matches expected 0x%0h", 
                            $time, o_rx_data, expected_bytes[recv_count]);
            end else begin
                $display("[%0t] FAIL: Received 0x%0h DOES NOT MATCH expected 0x%0h", 
                            $time, o_rx_data, expected_bytes[recv_count]);
            end
            recv_count++;
        end else begin
            $display("[%0t] Warning: Extra byte received 0x%0h", $time, o_rx_data);
        end
    end
end

endmodule
