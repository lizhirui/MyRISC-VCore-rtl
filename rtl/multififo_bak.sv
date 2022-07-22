`include "config.svh"
`include "common.svh"

module multififo #(
        parameter PORT_NUM = 2,
        parameter WIDTH = 1000,
        parameter DEPTH = 256
    )(
        input logic clk,
        input logic rst,
        
        output logic[PORT_NUM - 1:0] data_in_enable,
        input logic[WIDTH - 1:0] data_in[0:PORT_NUM - 1],
        input logic[PORT_NUM - 1:0] data_in_valid,
        input logic push,
        output logic full,
        input logic flush,
        
        output logic[WIDTH - 1:0] data_out[0:PORT_NUM - 1],
        output logic[PORT_NUM - 1:0] data_out_valid,
        input logic[PORT_NUM - 1:0] data_pop_valid,
        input logic pop,
        output logic empty
    );

    localparam DEPTH_WIDTH = $clog2(DEPTH);

    logic[DEPTH_WIDTH:0] rptr;
    logic[DEPTH_WIDTH:0] rptr_next;
    logic[DEPTH_WIDTH:0] wptr;
    logic[DEPTH_WIDTH:0] wptr_next;
    logic[WIDTH - 1:0] buffer[0:PORT_NUM - 1][0:DEPTH / PORT_NUM - 1];

    logic[DEPTH_WIDTH:0] wptr_rptr_sub;
    logic[DEPTH_WIDTH:0] cnt;
    logic[DEPTH_WIDTH:0] remain_space;
    logic[DEPTH_WIDTH:0] push_enable_num;
    logic[DEPTH_WIDTH:0] pop_enable_num;

    logic data_in_valid_filtered[0:PORT_NUM - 1];
    logic[DEPTH_WIDTH:0] data_in_num_temp[0:PORT_NUM - 1];
    logic[DEPTH_WIDTH:0] data_in_num;
    logic[DEPTH_WIDTH:0] data_out_num;
    logic data_pop_valid_filtered[0:PORT_NUM - 1];
    logic[DEPTH_WIDTH:0] data_pop_num_temp[0:PORT_NUM - 1];
    logic[DEPTH_WIDTH:0] data_pop_num;

    logic[DEPTH_WIDTH - 1:0] wptr_temp[0:PORT_NUM - 1];
    logic[DEPTH_WIDTH - 1:0] rptr_temp[0:PORT_NUM - 1];

    logic[WIDTH - 1:0] data_in_temp[0:PORT_NUM - 1][0:PORT_NUM - 1];
    logic[DEPTH_WIDTH - $clog2(PORT_NUM) - 1:0] data_in_addr_temp[0:PORT_NUM - 1][0:PORT_NUM - 1];
    logic data_in_match[0:PORT_NUM - 1][0:PORT_NUM - 1];

    logic[WIDTH - 1:0] buffer_out[0:PORT_NUM - 1];
    logic[DEPTH_WIDTH - $clog2(PORT_NUM) - 1:0] data_out_addr[0:PORT_NUM - 1][0:PORT_NUM - 1];
    logic[WIDTH - 1:0] data_out_temp[0:PORT_NUM - 1][0:PORT_NUM - 1];

    genvar i, j;

    assign full = ((rptr[DEPTH_WIDTH - 1:0] == wptr[DEPTH_WIDTH - 1:0]) && (rptr[DEPTH_WIDTH] != wptr[DEPTH_WIDTH])) ? 'b1 : 'b0;
    assign empty = (rptr == wptr) ? 'b1 : 'b0;

    assign wptr_rptr_sub = wptr - rptr;
    assign cnt = full ? DEPTH : {1'b0, wptr_rptr_sub[DEPTH_WIDTH - 1:0]};
    assign remain_space = DEPTH - cnt;
    assign push_enable_num = (remain_space >= 'd4) ? 'd4 : remain_space;

    generate
        for(i = 0;i < PORT_NUM;i = i + 1) begin
            assign data_in_enable[i] = (i < push_enable_num) ? 'b1 : 'b0;
        end
    endgenerate

    assign data_in_valid_filtered[0] = data_in_valid[0];
    assign data_in_num_temp[0] = data_in_valid[0];

    generate
        for(i = 1;i < PORT_NUM;i = i + 1) begin
            assign data_in_valid_filtered[i] = (data_in_valid_filtered[i - 1] && data_in_valid[i] && (i < push_enable_num)) ? 'b1 : 'b0;
            assign data_in_num_temp[i] = data_in_num_temp[i - 1] + data_in_valid_filtered[i];
        end
    endgenerate

    assign data_in_num = data_in_num_temp[PORT_NUM - 1];

    assign data_out_num = ((DEPTH - remain_space) >= 'd4) ? 'd4 : (DEPTH - remain_space);

    generate
        for(i = 0;i < PORT_NUM;i = i + 1) begin
            assign data_out_valid[i] = (rst | flush) ? 'b0 : (i < data_out_num) ? 'b1 : 'b0;
        end
    endgenerate

    assign pop_enable_num = (cnt >= 'd4) ? 'd4 : cnt;

    assign data_pop_valid_filtered[0] = data_pop_valid[0];
    assign data_pop_num_temp[0] = data_pop_valid[0];

    generate
        for(i = 1;i < PORT_NUM;i = i + 1) begin
            assign data_pop_valid_filtered[i] = (data_pop_valid_filtered[i - 1] && data_pop_valid[i] && (i < pop_enable_num)) ? 'b1 : 'b0;
            assign data_pop_num_temp[i] = data_pop_num_temp[i - 1] + data_pop_valid_filtered[i];
        end
    endgenerate

    assign data_pop_num = data_pop_num_temp[PORT_NUM - 1];

    always_comb begin
        if(rst | flush) begin
            wptr_next = 'b0;
        end
        else if(!full && push) begin
            wptr_next = wptr + data_in_num;
        end
        else begin
            wptr_next = wptr;
        end
    end

    always_comb begin
        if(rst | flush) begin
            rptr_next = 'b0;
        end
        else if(!empty && pop) begin
            rptr_next = rptr + data_pop_num;
        end
        else begin
            rptr_next = rptr;
        end
    end

    always_ff @(posedge clk) begin
        wptr <= wptr_next;
    end

    always_ff @(posedge clk) begin
        rptr <= rptr_next;
    end

    generate
        for(i = 0;i < PORT_NUM;i = i + 1) begin
            assign wptr_temp[i] = wptr[DEPTH_WIDTH - 1:0] + i;
        end
    endgenerate

    generate
        for(j = 0;j < PORT_NUM;j = j + 1) begin
            for(i = 0;i < PORT_NUM;i = i + 1) begin
                assign data_in_match[j][i] = (i == 0) ? data_in_valid_filtered[i] && (j == wptr_temp[i][$clog2(PORT_NUM) - 1:0]) : (data_in_valid_filtered[i] && (j == wptr_temp[i][$clog2(PORT_NUM) - 1:0])) || (data_in_match[j][i - 1]);
                assign data_in_addr_temp[j][i] = (i == 0) ? wptr_temp[i][DEPTH_WIDTH - 1:$clog2(PORT_NUM)] : data_in_match[j][i - 1] ? data_in_addr_temp[j][i - 1] : wptr_temp[i][DEPTH_WIDTH - 1:$clog2(PORT_NUM)];
                assign data_in_temp[j][i] = (i == 0) ? data_in[i] : data_in_match[j][i - 1] ? data_in_temp[j][i - 1] : data_in[i];
            end

            always_ff @(posedge clk) begin
                if(!rst) begin
                    if(full && data_in_match[j][PORT_NUM - 1]) begin
                        buffer[j][data_in_addr_temp[j][PORT_NUM - 1]] <= data_in_temp[j][PORT_NUM - 1];
                    end
                end
            end
        end
    endgenerate

    generate
        for(i = 0;i < PORT_NUM;i = i + 1) begin
            assign rptr_temp[i] = rptr[DEPTH_WIDTH - 1:0] + i;
        end
    endgenerate

    generate
        for(j = 0;j < PORT_NUM;j = j + 1) begin
            for(i = 0;i < PORT_NUM;i = i + 1) begin
                assign data_out_addr[j][i] = (i == 0) ? rptr_temp[i][DEPTH_WIDTH - 1:$clog2(PORT_NUM)] : (j == rptr_temp[i][$clog2(PORT_NUM) - 1:0]) ? rptr_temp[i][DEPTH_WIDTH - 1:$clog2(PORT_NUM)] : data_out_addr[j][i - 1];
            end
        end
    endgenerate

    generate
        for(j = 0;j < PORT_NUM;j = j + 1) begin
            assign buffer_out[j] = buffer[j][data_out_addr[j][PORT_NUM - 1]];
        end
    endgenerate

    generate
        for(i = 0;i < PORT_NUM;i = i + 1) begin
            assign data_out_temp[i][0] = buffer_out[0];

            for(j = 1;j < PORT_NUM;j = j + 1) begin
                assign data_out_temp[i][j] = (j == rptr_temp[i][$clog2(PORT_NUM) - 1:0]) ? buffer_out[j] : data_out_temp[i][j - 1];
            end

            assign data_out[i] = data_out_temp[i][PORT_NUM - 1];
        end
    endgenerate
endmodule