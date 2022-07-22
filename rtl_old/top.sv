module top(
        input clk,
        input rst,
        input logic[31:0] data_in,
        output logic[4:0] index,
        output logic index_valid
    );
    
    logic[31:0] data_in_reg;
    logic[4:0] index_reg;
    logic index_valid;
    
    always_ff @(posedge clk) begin
        data_in_reg <= data_in;
    end
    
    priority_finder #(
        .FIRST_PRIORITY(1),
        .WIDTH(32)
    )priority_finder_inst(
        .data_in(data_in_reg),
        .index(index_reg),
        .index_valid(index_valid_reg)
    );
    
    always_ff @(posedge clk) begin
        index <= index_reg;
        index_valid <= index_valid_reg;
    end
endmodule
