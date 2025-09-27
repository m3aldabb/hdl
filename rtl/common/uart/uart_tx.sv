module uart_tx #(   parameter CLK_RATE      = 100_000_000,
                    parameter BAUD_RATE     = 9600,
                    parameter NCLKS_PER_BIT = CLK_RATE/BAUD_RATE                 
) (
   input clk, 
   input rst,

   // Input data
   input [7:0] i_tx_data,
   input       i_tx_start,

   // Output UART Interface
   output      o_tx_data,
   output      o_tx_busy,
   output      o_tx_done
);

typedef enum {
   IDLE,
   START,
   DATA,
   STOP,
   DONE
} states_t;

// Signals and Registers 
states_t        state, next_state;
logic   [7:0]   byte_mem, next_byte_mem;  
logic   [$clog2(NCLKS_PER_BIT)-1:0] clk_count, next_clk_count;
logic   [2:0]   tx_data_idx, next_tx_data_idx;
logic   r_tx_data, next_tx_data;
logic   r_tx_done, next_tx_done;


// Output Assignments
assign o_tx_data          = r_tx_data;
assign o_tx_busy          = (state != IDLE);
assign o_tx_done          = (state == DONE);

// Sequential Logic
always @(posedge clk) begin
   if(rst) begin
       state               <= IDLE;
       byte_mem            <= '0;
       clk_count           <= '0;
       tx_data_idx         <= '0;

       r_tx_data           <= 1'b1;
       r_tx_done           <= 1'b0;
   end else begin
       state               <= next_state;
       byte_mem            <= next_byte_mem;
       clk_count           <= next_clk_count;
       tx_data_idx         <= next_tx_data_idx;

       r_tx_data           <= next_tx_data;
       r_tx_done           <= next_tx_done;
   end
end

// Combinational Logic
always @(*) begin
   next_byte_mem       = byte_mem;
   next_clk_count      = clk_count;
   next_tx_data_idx    = tx_data_idx;
   next_tx_data        = r_tx_data;
   next_tx_done        = r_tx_done;
   next_state          = state;

   case(state)
        IDLE: begin
            next_tx_data    = 1'b1;
            if(i_tx_start) begin
                next_byte_mem       = i_tx_data;
                next_clk_count      = 0;
                next_tx_data_idx    = 0;
                next_tx_done        = 1'b0;
                next_state          = START;
            end else begin
                next_state          = IDLE;
            end
        end

        START: begin
            next_tx_data    = 1'b0;
            if(clk_count == NCLKS_PER_BIT-1) begin
                next_clk_count      = '0;
                next_state          = DATA;
            end else begin
                next_clk_count      = clk_count + 1;
                next_state          = START;
            end
        end
        DATA: begin
            next_tx_data    = byte_mem[tx_data_idx];
            if(clk_count == NCLKS_PER_BIT-1) begin
                next_clk_count  = '0;
                if(tx_data_idx < 7) begin
                    // We still have more bits to send out.
                    next_tx_data_idx    = tx_data_idx + 1;
                    next_state          = DATA;
                end else begin
                    next_tx_data_idx    = '0;
                    next_state          = STOP;
                end
            end else begin
                next_clk_count      = clk_count + 1;
                next_state          = DATA;
            end
        end

        STOP: begin
            next_tx_data    = 1'b1;
            if(clk_count == NCLKS_PER_BIT-1) begin
                next_clk_count      = '0;
                next_tx_done        = 1'b1;                    
                next_state          = DONE;
            end else begin
                next_clk_count      = clk_count + 1;
                next_state          = STOP;
            end
        end

        DONE: begin
            next_state  = IDLE;
        end
    endcase
end

endmodule
