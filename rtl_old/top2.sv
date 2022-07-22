module top(
    input logic clk,
    input logic rst,
    input logic[15:0] addr,
    input logic[31:0] data_in,
    output logic[31:0] data_out,
    input logic we
);
    logic[31:0] mem[0:65535];
    
    always_ff @(posedge clk) begin
        data_out <= mem[addr];
    end 
    
    always_ff @(posedge clk) begin
        if(we) begin
            mem[addr] <= data_in;
        end
    end
endmodule
