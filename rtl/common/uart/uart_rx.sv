// NCLKS_PER_BIT = (Fclk)/(BR)
// Example: 25 MHz Clock, 115200 baud UART
// NCLKS_PER_BIT = (25000000)/(115200) = 217
module uart_rx #(parameter NCLKS_PER_BIT = 217) (
    input clk, 
    input rst,

    // Ouput data
    output [7:0] o_rx_data,
    output       o_rx_valid,

    // Input UART Interface
    input      i_rx_data
);

typedef enum logic[2:0] {
    IDLE,
    START,
    DATA,
    STOP, 
    DONE
} states_t;


// Signals and Registers
states_t        state, next_state;

logic           r_o_rx_valid, next_o_rx_valid;

logic   [7:0]   byte_mem, next_byte_mem;  
logic   [2:0]   byte_idx, next_byte_idx;

logic   [$clog2(NCLKS_PER_BIT)-1:0] clk_count, next_clk_count;


// Output Assignments
assign o_rx_valid  = r_o_rx_valid;
assign o_rx_data   = (r_o_rx_valid) ? byte_mem : 'X;


// Sequential Logic
always @(posedge clk) begin
    if(rst) begin
        state               <= IDLE;
        byte_mem            <= '0;
        byte_idx            <= '0;
        clk_count           <= '0;
        r_o_rx_valid   <= 1'b0;
    end else begin
        state               <= next_state;
        byte_mem            <= next_byte_mem;
        byte_idx            <= next_byte_idx;
        clk_count           <= next_clk_count;
        r_o_rx_valid   <= next_o_rx_valid;
    end
end
// Combinational Logic
always @(*) begin
    next_state               = state;
    next_byte_mem            = byte_mem;
    next_byte_idx            = byte_idx;
    next_clk_count           = clk_count;
    next_o_rx_valid     = r_o_rx_valid;
    case(state)
        IDLE: begin
            if(~i_rx_data) begin // Start bit
                next_state  = START;
            end else begin
                next_state  = IDLE;
            end
        end

        START: begin
            if(clk_count == NCLKS_PER_BIT/2 - 1) begin // Found the halfway point
                next_clk_count = '0;
                if(~i_rx_data) begin
                    // Start bit accepted, ready to move on to data bits.
                    next_state  = DATA;
                end else begin
                    next_state  = IDLE;
                end
            end else begin
                next_clk_count      = clk_count + 1;
                next_state          = START;
            end
        end

        DATA: begin
            if(clk_count == NCLKS_PER_BIT - 1) begin
                next_clk_count          = '0;
                next_byte_mem[byte_idx] = i_rx_data;

                if(byte_idx < 7) begin
                    next_byte_idx   = byte_idx + 1;
                    next_state      = DATA;
                end else begin
                    next_byte_idx   = '0;
                    next_state      = STOP;
                end
            end else begin
                next_clk_count      = clk_count + 1;
                next_state          = DATA;
            end
            
        end

        STOP: begin
            if (clk_count == NCLKS_PER_BIT-1) begin
                next_clk_count          = '0;
                next_state              = DONE;
                next_o_rx_valid    = 1'b1; 
            end else begin
                next_clk_count          = clk_count + 1;
                next_state              = STOP;
            end
        end

        DONE: begin
            next_o_rx_valid        = 1'b0;
            next_state                  = IDLE;
        end
    endcase
end

endmodule