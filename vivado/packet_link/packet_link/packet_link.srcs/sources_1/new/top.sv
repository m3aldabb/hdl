`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2025 10:10:14 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input clk, 
    input rst,
    input rx,
    output [6:0]  seg,
    output [3:0]  an
    );
    
parameter CLK_FREQ      = 100_000_000;
parameter BAUD_RATE     = 9600;
parameter NCLKS_PER_BIT = CLK_FREQ/BAUD_RATE;

parameter FIFO_DEPTH    = 1500;
parameter FIFO_DWIDTH   = 8;

logic   [7:0]   o_rx;
logic   [7:0]   i_tx_data;
logic           wr;
logic           rd_pulse;
logic   [3:0]   bcd_num;
logic   [15:0]  i_num_bcd;
logic           tx_fifo_empty;
logic           o_rx_valid;

logic pkt_valid;
logic [15:0] pkt_data;

uart_rx #(
    .NCLKS_PER_BIT(NCLKS_PER_BIT)
) uart_rx_0 (
    .clk(clk),
    .rst(rst),
    .i_rx_data(rx),
    .o_rx_valid(o_rx_valid),
    .o_rx_data(o_rx)
);

// ------------------------------------------------------------------------
// UART-to-Packet Parser
// ------------------------------------------------------------------------
uart2pkt_parser #(
    .PD_LEN(2),                       // Example: 2-byte payload
    .PKTLEN(2 + 5)                    // Full packet length = 7
) uart2pkt_parser_0 (
    .clk(clk),
    .rst(rst),

    .i_data(o_rx),                     // from uart_rx
    .i_valid(o_rx_valid),              // uart_rx says byte is valid

    .o_data(pkt_data),                 // full parsed packet
    .o_valid(pkt_valid)                // high when a packet is ready
);

assign i_num_bcd = pkt_data;

ssd_ctrl ssd_ctrl_0 (
    .clk(clk),
    .rst(rst),
    .i_num_bcd(i_num_bcd),
    .o_digit_en(an),
    .o_led(seg)
);


endmodule
