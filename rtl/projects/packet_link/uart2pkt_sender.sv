module uart2pkt_sender #(
    parameter PD_LEN = 2,                       // Payload length in bytes
    parameter PKTLEN = PD_LEN + 5               // Full packet length: start + type + length + payload + checksum + end
) (
    input  logic             clk,
    input  logic             rst,

    input  logic [8*PKTLEN-1:0] i_data,
    input  logic                i_valid,
    output logic                i_ready,

    output logic [7:0]          o_data,
    output logic                o_valid,
    input  logic                o_ready
);

// Constants
localparam START_BYTE = 8'hAA;
localparam END_BYTE   = 8'h55;

logic   [7:0]   fifo_in_data;
logic           fifo_wr;
logic           fifo_full;

logic   [7:0]           pkt_length;
logic   [7:0]           pkt_byte_cnt;
logic   [8*PKTLEN-1:0]  pkt_data;
logic                   pkt_in_progress;
always_ff @(posedge clk) begin
    if(rst) begin
        pkt_length      <= '0;
        pkt_byte_cnt    <= '0;
        pkt_data        <= '0;
        fifo_in_data    <= '0;
        fifo_wr         <= 1'b0;
    end else begin
        if(fifo_wr && !fifo_full) begin
            // Ongoing transfer of a packet. Only proceed when we have space in fifo.
            if(pkt_byte_cnt == pkt_length - 1) begin
                // On the last byte
                pkt_length      <= '0;
                pkt_byte_cnt    <= '0;
                pkt_data        <= '0;
                fifo_wr         <= 1'b0;
            end else begin
                pkt_byte_cnt    <= pkt_byte_cnt + 1;
                pkt_data        <= pkt_data >> 8;
                fifo_in_data    <= pkt_data[7:0];
            end
        end else if(i_valid && (i_data[7:0] == START_BYTE)) begin
            // Starting the transfer of a new, valid packet
            pkt_length      <= i_data[23:16];
            pkt_byte_cnt    <= 1;
            pkt_data        <= i_data >> 8;
            fifo_wr         <= 1'b1;
            fifo_in_data    <= i_data[7:0];
        end
    end
end
   
fifo #(
    .DATA_WIDTH(8),
    .DEPTH(16)
) u_fifo (
    .clk    (clk),
    .rst    (rst),

    // Write side
    .wr     (fifo_wr),         
    .i_data (fifo_in_data),  

    // Read side
    .rd     (o_ready),         
    .o_data (o_data),
    .o_valid (o_valid),
    // Status flags
    .full   (fifo_full),
    .empty  ()
);

assign i_ready  = !fifo_wr;

endmodule