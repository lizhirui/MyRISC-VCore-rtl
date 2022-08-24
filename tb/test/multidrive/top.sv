module top;
    parameter PORT_NUM = 4;
    parameter DEPTH = 8;
    localparam DEPTH_WIDTH = $clog2(DEPTH);

    logic[DEPTH_WIDTH:0] data_in_num;

    count_one #(
        .CONTINUOUS(1),
        .WIDTH(PORT_NUM)
    )count_one_data_in_valid_inst(
        .data_in(4'b0),
        .sum(data_in_num[2:0])
    );

    assign data_in_num[DEPTH_WIDTH - 1:2 + 1] = 'b0;

endmodule