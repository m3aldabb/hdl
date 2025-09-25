module fifo #(parameter DATA_WIDTH = 8, parameter DEPTH = 16) (
    input clk,
    input rst,

    input wr,
    input [DATA_WIDTH-1:0] i_data,

    input rd,
    output logic [DATA_WIDTH-1:0] o_data,
    
    output full,
    output empty
);

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
logic roll;

always_ff @(posedge clk) begin
    if(rst) begin
        wr_ptr  <= '0;
        rd_ptr  <= '0;
    end else begin
        if(rd && !empty) begin
            o_data  <= mem[rd_ptr];
            rd_ptr  <= rd_ptr + 1;
        end
        
        if(wr && !full) begin
            mem[wr_ptr] <= i_data;
            wr_ptr  <= wr_ptr + 1;
        end 
    end
end

always_ff @(posedge clk) begin
    if(rst) begin
        roll <= 1'b0;
    end else begin
        if(wr && !fulll && (wr_ptr == DEPTH-1)) begin
            roll <= 1'b1;
        end else if(rd && !empty && (rd_ptr == DEPTH-1)) begin
            roll <= 1'b0;
        end
    end
end

assign full     = (wr_ptr == rd_ptr) && roll;
assign empty    = (wr_ptr == rd_ptr) && !roll;

endmodule