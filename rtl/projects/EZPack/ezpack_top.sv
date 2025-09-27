module top (
    input  logic       clk,      // System clock
    input  logic       rst,      // Reset signal
    input  logic       rx,       // UART RX input
    output logic [6:0] seg,      // SSD cathodes
    output logic [3:0] an,       // SSD anodes
    output logic       tx        // UART TX output
);

    // ------------------------------
    // Parameters
    // ------------------------------
    localparam MAX_PD_LEN  = 2;                 // Payload length in bytes
    localparam MAX_PKTLEN  = MAX_PD_LEN + 5;    // Full EZPack length: start + type + length + payload + checksum + end

    // ------------------------------
    // Internal signals
    // ------------------------------
    logic [8*MAX_PKTLEN-1:0] o_data;    // EZPack packet output
    logic                o_valid;       // Packet valid
    logic                o_ready;       // Ready signal
    logic [15:0]         num_bcd;       // Hex digits for SSD

    // Signals for UART TX
    logic                tx_busy;

    // ------------------------------
    // EZPack UART RX
    // ------------------------------
    ezp_uart_rx #(
        .START_BYTE(8'hAA),
        .END_BYTE(8'h55),
        .MAX_PD_LEN(MAX_PD_LEN),
        .MAX_PKTLEN(MAX_PKTLEN),
        .CLK_RATE(100_000_000),
        .BAUD_RATE(9600)
    ) ezp_uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .i_rx_data(rx),
        .o_data(o_data),
        .o_valid(o_valid),
        .o_ready(1'b1)
    );

    // ------------------------------
    // Extract 2-byte payload and map to SSD
    // Payload sits between length and checksum:
    // o_data = {END, CHK, PD[15:0], LEN, TYPE, START}
    // ------------------------------
    logic [15:0] payload;
    assign payload = o_data[39:24];   // grab PD[15:0]

    // Drive SSD controller - each nibble is one hex digit
    assign num_bcd = payload;

    // ------------------------------
    // 7-segment display controller
    // ------------------------------
    ssd_ctrl ssd_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .i_num_bcd(num_bcd),
        .o_digit_en(an),
        .o_led(seg)
    );

    // ------------------------------
    // EZPack UART TX (loopback)
    // ------------------------------
    ezp_uart_tx #(
        .START_BYTE(8'hAA),
        .END_BYTE(8'h55),
        .MAX_PD_LEN(MAX_PD_LEN),
        .MAX_PKTLEN(MAX_PKTLEN),
        .CLK_RATE(100_000_000),
        .BAUD_RATE(9600)
    ) ezp_uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .i_data(o_data),
        .i_valid(o_valid),
        .i_ready(1'b1), // optional: tie to 1'b1 if no flow control
        .o_tx_data(tx),
        .o_tx_busy(tx_busy),
        .o_tx_done()       // unused
    );

endmodule
