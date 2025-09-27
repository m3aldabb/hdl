module ezp_encode #(
    parameter START_BYTE    = 8'hAA,
    parameter END_BYTE      = 8'h55,
    parameter MAX_PD_LEN    = 2,                       
    parameter MAX_PKTLEN    = MAX_PD_LEN + 5        
)(
    input  logic                    clk,
    input  logic                    rst,

    input  logic [7:0]              i_data,
    input  logic                    i_valid,
    output logic                    i_ready,

    output logic [8*MAX_PKTLEN-1:0] o_data,
    output logic                    o_valid,
    input  logic                    o_ready
);

// FSM states
typedef enum {
    S_IDLE,
    S_PKT_TYPE,
    S_LEN,
    S_PD,
    S_CHK,
    S_END,
    S_ERR,
    S_DONE
} states_t;

states_t state;

// Internal registers
logic [7:0] pkt_type;
logic [7:0] pkt_length;
logic [8*MAX_PD_LEN-1:0] pd;
logic [$clog2(MAX_PD_LEN):0] pd_byte_cnt;
logic [7:0] checksum;

// FSM
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state         <= S_IDLE;
        pkt_type      <= 8'd0;
        pkt_length    <= 8'd0;
        pd            <= {8*MAX_PD_LEN{1'b0}};
        pd_byte_cnt   <= 0;
        checksum      <= 8'd0;
        o_valid       <= 1'b0;
    end else begin
        case (state)
            S_IDLE: begin
                if (i_valid && i_data == START_BYTE) begin
                    pkt_type    <= 8'd0;
                    pkt_length  <= 8'd0;
                    pd          <= {8*MAX_PD_LEN{1'b0}};
                    pd_byte_cnt <= 0;
                    checksum    <= 8'd0;
                    o_valid     <= 1'b0;
                    state       <= S_PKT_TYPE;
                end
            end

            S_PKT_TYPE: begin
                if (i_valid) begin
                    pkt_type <= i_data;
                    checksum <= i_data;
                    state    <= S_LEN;
                end
            end

            S_LEN: begin
                if (i_valid) begin
                    pkt_length <= i_data;
                    checksum   <= checksum ^ i_data;
                    state      <=  S_PD;
                end
            end

            S_PD: begin
                if (i_valid) begin
                    pd          <= {pd[8*(MAX_PD_LEN-1)-1:0], i_data}; // shift in new byte
                    checksum    <= checksum ^ i_data;
                    pd_byte_cnt <= pd_byte_cnt + 1;

                    if (pd_byte_cnt == MAX_PD_LEN-1)
                        state <= S_CHK;
                end
            end

            S_CHK: begin
                if (i_valid) begin
                    if (i_data == checksum) begin
                        state <= S_END;
                    end else begin
                        state <= S_ERR;
                    end
                end
            end

            S_END: begin
                if (i_valid && (i_data == END_BYTE)) begin
                    state   <= S_DONE;
                    o_valid <= 1'b1;
                end
            end

            S_DONE: begin
                if (o_ready && o_valid) begin
                    o_valid <= 1'b0;
                    state   <= S_IDLE;
                end
            end

            S_ERR: begin
                state <= S_IDLE;
            end

            default: state <= S_IDLE;

        endcase
    end
end

// Output
assign o_data  = {END_BYTE, checksum, pd, pkt_length, pkt_type, START_BYTE};
assign i_ready = (state != S_DONE) && (state != S_ERR);

endmodule
