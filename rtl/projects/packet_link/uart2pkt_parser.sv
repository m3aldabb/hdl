module uart2pkt_parser #(
    parameter PD_LEN = 2,                       // Payload length in bytes
    parameter PKTLEN = PD_LEN + 5               // Full packet length: start + type + length + payload + checksum + end
)(
    input  logic             clk,
    input  logic             rst,

    input  logic [7:0]       i_data,
    input  logic             i_valid,

    output logic [15:0] o_data,
    output logic             o_valid
);

// Constants
localparam START_BYTE = 8'hAA;
localparam END_BYTE   = 8'h55;

// FSM states
typedef enum logic [2:0] {
    S_IDLE,
    S_PKT_TYPE,
    S_LEN,
    S_PD,
    S_CHK,
    S_END,
    S_ERR
} states_t;

states_t state;

// Internal registers
logic [7:0] pkt_type;
logic [7:0] pkt_length;
logic [8*PD_LEN-1:0] pd;
logic [$clog2(PD_LEN):0] pd_byte_cnt;
logic [7:0] checksum;
logic packet_good;

// Reverse buffer
logic [8*PD_LEN-1:0] pd_rev;

// FSM
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state         <= S_IDLE;
        pkt_type      <= 8'd0;
        pkt_length    <= 8'd0;
        pd            <= {8*PD_LEN{1'b0}};
        pd_byte_cnt   <= 0;
        checksum      <= 8'd0;
        packet_good   <= 1'b0;
    end else begin
        packet_good <= 1'b0; // default low

        case (state)
            S_IDLE: begin
                if (i_valid && i_data == START_BYTE) begin
                    pkt_type    <= 8'd0;
                    pkt_length  <= 8'd0;
                    pd          <= {8*PD_LEN{1'b0}};
                    pd_byte_cnt <= 0;
                    checksum    <= 8'd0;
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
                    pd <= {pd[8*(PD_LEN-1)-1:0], i_data}; // shift in new byte
                    checksum <= checksum ^ i_data;
                    pd_byte_cnt <= pd_byte_cnt + 1;

                    if (pd_byte_cnt == PD_LEN-1)
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
                if (i_valid) begin
                    if (i_data == END_BYTE) begin
                        packet_good <= 1'b1;
                    end
                    state <= S_IDLE;
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
assign o_valid = packet_good;
assign o_data  = {END_BYTE, checksum, pd, pkt_length, pkt_type, START_BYTE};

endmodule
