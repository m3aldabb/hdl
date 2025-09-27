module ezp_uart_rx #(
    parameter START_BYTE    = 8'hAA,
    parameter END_BYTE      = 8'h55,
    parameter MAX_PD_LEN    = 2,                   
    parameter MAX_PKTLEN    = MAX_PD_LEN + 5,      
    parameter CLK_RATE      = 100_000_000,
    parameter BAUD_RATE     = 9600,
    parameter NCLKS_PER_BIT = CLK_RATE/BAUD_RATE       
)(
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    i_rx_data,
    output logic [8*MAX_PKTLEN-1:0] o_data,
    output logic                    o_valid,
    input  logic                    o_ready
);

// ------------------------------
// Internal wires
// ------------------------------
logic        o_rx_valid;
logic [7:0]  o_rx_data;

logic [7:0]  ezp_encode_i_data;           
logic        ezp_encode_i_valid;
logic        ezp_encode_i_ready;

logic [8*MAX_PKTLEN-1:0] ezp_encode_o_data;  
logic        ezp_encode_o_valid;

logic        fifo_1_full;
logic        fifo_1_empty;

// ------------------------------
// UART RX
// ------------------------------
uart_rx #(
    .CLK_RATE(CLK_RATE),
    .BAUD_RATE(BAUD_RATE),
    .NCLKS_PER_BIT(NCLKS_PER_BIT)
) uart_rx_0 (
    .clk(clk),
    .rst(rst),
    .i_rx_data(i_rx_data),
    .o_rx_valid(o_rx_valid),
    .o_rx_data(o_rx_data)
);

// ------------------------------
// FIFO 0 (buffers UART bytes to encoder)
// ------------------------------
fifo #(
    .DATA_WIDTH(8),
    .DEPTH(2*MAX_PKTLEN)
) fifo_0 (
    .clk(clk),
    .rst(rst),
    .wr(o_rx_valid),
    .i_data(o_rx_data),
    .rd(ezp_encode_i_ready),
    .o_data(ezp_encode_i_data),
    .o_valid(ezp_encode_i_valid),
    .full(),  
    .empty()
);

// ------------------------------
// EZPack encoder
// ------------------------------
ezp_encode #(
    .START_BYTE(START_BYTE),
    .END_BYTE(END_BYTE),
    .MAX_PKTLEN(MAX_PKTLEN),
    .MAX_PD_LEN(MAX_PD_LEN)
) ezp_encode_0 (
    .clk(clk),
    .rst(rst),
    .i_data(ezp_encode_i_data),
    .i_valid(ezp_encode_i_valid),
    .i_ready(ezp_encode_i_ready),
    .o_data(ezp_encode_o_data),
    .o_valid(ezp_encode_o_valid),
    .o_ready(!fifo_1_full)
);

// ------------------------------
// FIFO 1 (buffers encoded EZPack packets to output)
// ------------------------------
fifo #(
    .DATA_WIDTH(8*MAX_PKTLEN),
    .DEPTH(32)
) fifo_1 (
    .clk(clk),
    .rst(rst),
    .wr(ezp_encode_o_valid),
    .i_data(ezp_encode_o_data),
    .rd(o_ready),
    .o_data(o_data),
    .o_valid(o_valid),
    .full(fifo_1_full),
    .empty(fifo_1_empty)
);

endmodule
