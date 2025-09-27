module ezp_uart_tx #(
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
    
    input  logic [8*MAX_PKTLEN-1:0] i_data,
    input  logic                    i_valid,
    output logic                    i_ready,

    output logic                    o_tx_data,
    output logic                    o_tx_busy,
    output logic                    o_tx_done
);

// ------------------------------
// Internal signals
// ------------------------------
logic [7:0]  ezp_decode_o_data;
logic        ezp_decode_o_valid;
logic [7:0]  i_tx_data;
logic        i_tx_start;
logic        fifo_0_full;
logic        fifo_0_empty;
logic        fifo_0_rd;
logic        uart_tx_in_progress;

// ------------------------------
// EZPack decoder instance
// ------------------------------
ezp_decode #(
    .START_BYTE (START_BYTE),
    .END_BYTE   (END_BYTE),
    .MAX_PD_LEN (MAX_PD_LEN),
    .MAX_PKTLEN (MAX_PKTLEN)
) u_ezp_decode (
    .clk    (clk),
    .rst    (rst),
    .i_data (i_data),
    .i_valid(i_valid),
    .i_ready(i_ready),
    .o_data (ezp_decode_o_data),
    .o_valid(ezp_decode_o_valid),
    .o_ready(!fifo_0_full)
);

// ------------------------------
// FIFO 0: buffers decoder bytes to UART transmitter
// ------------------------------
fifo #(
    .DATA_WIDTH(8),
    .DEPTH(2*MAX_PKTLEN)
) fifo_0 (
    .clk(clk),
    .rst(rst),
    .wr(ezp_decode_o_valid),
    .i_data(ezp_decode_o_data),
    .rd(fifo_0_rd),
    .o_data(i_tx_data),
    .o_valid(i_tx_start),
    .full(fifo_0_full),
    .empty(fifo_0_empty)      // not used
);

// Read control
always_ff @(posedge clk) begin
    if(rst) begin
        fifo_0_rd           <= 1'b0;
        uart_tx_in_progress <= 1'b0;
    end else begin
        if(!fifo_0_rd && !o_tx_busy && !fifo_0_empty && !uart_tx_in_progress) begin
            fifo_0_rd           <= 1'b1;
            uart_tx_in_progress <= 1'b1;
        end else if(uart_tx_in_progress) begin
            fifo_0_rd   <= 1'b0;
            if(o_tx_done) begin
                uart_tx_in_progress <= 1'b0;
            end
        end
    end
end

// ------------------------------
// UART transmitter instance
// ------------------------------
uart_tx #(
    .CLK_RATE     (CLK_RATE),
    .BAUD_RATE    (BAUD_RATE),
    .NCLKS_PER_BIT(NCLKS_PER_BIT)
) u_uart_tx (
    .clk       (clk),
    .rst       (rst),
    .i_tx_data (i_tx_data),
    .i_tx_start(i_tx_start),
    .o_tx_data (o_tx_data),
    .o_tx_busy (o_tx_busy),
    .o_tx_done (o_tx_done)
);

endmodule
