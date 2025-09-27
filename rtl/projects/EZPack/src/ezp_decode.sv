module ezp_decode #(
    parameter START_BYTE    = 8'hAA,
    parameter END_BYTE      = 8'h55,
    parameter MAX_PD_LEN    = 2,              
    parameter MAX_PKTLEN    = MAX_PD_LEN + 5          
) (
    input  logic             clk,
    input  logic             rst,

    input  logic [8*MAX_PKTLEN-1:0] i_data,
    input  logic                    i_valid,
    output logic                    i_ready,

    output logic [7:0]              o_data,
    output logic                    o_valid,
    input  logic                    o_ready
);

logic   [$clog2(MAX_PD_LEN):0]      pd_length;
logic   [$clog2(MAX_PKTLEN):0]      pkt_length;
logic   [$clog2(MAX_PKTLEN):0]      pkt_byte_cnt;
logic   [8*MAX_PKTLEN-1:0]          pkt_data;

assign pkt_length = pd_length + 5;

typedef enum {
    IDLE,
    WAIT,
    DONE
} states_t;

states_t    state;

always_ff @(posedge clk) begin
    if(rst) begin
        pd_length       <= '0;
        pkt_byte_cnt    <= '0;
        pkt_data        <= '0;
        o_data          <= '0;
        o_valid         <= 1'b0;
        state           <= IDLE;
    end else begin
        case(state)
            IDLE: begin
                if(i_valid && i_ready && i_data[7:0] == START_BYTE) begin
                    // Starting the transfer of a new, valid packet
                    pd_length       <= i_data[23:16];
                    pkt_byte_cnt    <= 1;
                    pkt_data        <= i_data >> 8;
                    o_valid         <= 1'b1;
                    o_data          <= START_BYTE;
                    state           <= WAIT;
                end
            end

            WAIT: begin
                // Ongoing transfer of a packet.
                if(o_valid && o_ready) begin
                    if(pkt_byte_cnt == pkt_length - 1) begin
                        // On the last byte
                        pd_length       <= '0;
                        pkt_byte_cnt    <= '0;
                        pkt_data        <= '0;
                        state           <= DONE;
                    end else begin
                        pkt_byte_cnt    <= pkt_byte_cnt + 1;
                        pkt_data        <= pkt_data >> 8;
                    end
                    o_data  <= pkt_data[7:0];
                end
            end

            DONE: begin
                o_valid <= 1'b0;
                state   <= IDLE;
            end
        endcase
    end
end

assign i_ready  = (state == IDLE);

endmodule
