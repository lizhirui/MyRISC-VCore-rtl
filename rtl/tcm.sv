`include "config.svh"
`include "common.svh"

module tcm #(
        parameter IMAGE_PATH = "",
        parameter IMAGE_INIT = 0
    )(
        input logic clk,
        input logic rst,

        input logic[`ADDR_WIDTH - 1:0] bus_tcm_fetch_addr,
        input logic bus_tcm_fetch_rd,
        output logic[`BUS_DATA_WIDTH - 1:0] tcm_bus_fetch_data,

        input logic[`ADDR_WIDTH - 1:0] bus_tcm_stbuf_read_addr,
        input logic[`ADDR_WIDTH - 1:0] bus_tcm_stbuf_write_addr,
        input logic[`SIZE_WIDTH - 1:0] bus_tcm_stbuf_read_size,
        input logic[`SIZE_WIDTH - 1:0] bus_tcm_stbuf_write_size,
        input logic[`REG_DATA_WIDTH - 1:0] bus_tcm_stbuf_data,
        input logic bus_tcm_stbuf_rd,
        input logic bus_tcm_stbuf_wr,
        output logic[`BUS_DATA_WIDTH - 1:0] tcm_bus_stbuf_data
    );

    localparam BANK_NUM = `BUS_DATA_WIDTH / 8;
    localparam BANK_ADDR_WIDTH = $clog2(BANK_NUM);
    localparam TCM_ADDR_WIDTH = $clog2(`TCM_SIZE);

    logic[7:0] fetch_mem[0:BANK_NUM - 1][0:`TCM_SIZE / BANK_NUM - 1];
    logic[7:0] stbuf_mem[0:BANK_NUM - 1][0:`TCM_SIZE / BANK_NUM - 1];

    logic[`ADDR_WIDTH - 1:0] bus_tcm_fetch_addr_r;
    logic[`ADDR_WIDTH - 1:0] bus_tcm_stbuf_read_addr_r;

    logic[`ADDR_WIDTH - 1:0] fetch_full_addr_set[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - 1:0] fetch_full_addr_set_r[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - BANK_ADDR_WIDTH - 1:0] fetch_bank_addr_set[0:BANK_NUM - 1];
    logic[BANK_NUM - 1:0] fetch_bank_id_cmp[0:BANK_NUM - 1];
    logic[BANK_NUM - 1:0] fetch_bank_id_cmp_r[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - BANK_ADDR_WIDTH - 1:0] fetch_bank_addr[0:BANK_NUM - 1];
    logic[BANK_ADDR_WIDTH - 1:0] fetch_bank_set_index[0:BANK_NUM - 1];
    logic[`BUS_DATA_WIDTH - 1:0] fetch_bank_data_reg[0:BANK_NUM - 1];
    logic[$clog2(`BUS_DATA_WIDTH) - 1:0] fetch_bank_data_reg_shift[0:BANK_NUM - 1];
    logic[`BUS_DATA_WIDTH - 1:0] fetch_bank_data_recombine[0:BANK_NUM - 1];

    logic[`ADDR_WIDTH - 1:0] stbuf_read_full_addr_set[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - 1:0] stbuf_read_full_addr_set_r[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - BANK_ADDR_WIDTH - 1:0] stbuf_read_bank_addr_set[0:BANK_NUM - 1];
    logic[BANK_NUM - 1:0] stbuf_read_bank_id_cmp[0:BANK_NUM - 1];
    logic[BANK_NUM - 1:0] stbuf_read_bank_id_cmp_r[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - BANK_ADDR_WIDTH - 1:0] stbuf_read_bank_addr[0:BANK_NUM - 1];
    logic[BANK_ADDR_WIDTH - 1:0] stbuf_read_bank_set_index[0:BANK_NUM - 1];
    logic[`BUS_DATA_WIDTH - 1:0] stbuf_read_bank_data_reg[0:BANK_NUM - 1];
    logic[$clog2(`BUS_DATA_WIDTH) - 1:0] stbuf_read_bank_data_reg_shift[0:BANK_NUM - 1];
    logic[`BUS_DATA_WIDTH - 1:0] stbuf_read_bank_data_recombine[0:BANK_NUM - 1];

    logic[`ADDR_WIDTH - 1:0] stbuf_write_full_addr_set[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - BANK_ADDR_WIDTH - 1:0] stbuf_write_bank_addr_set[0:BANK_NUM - 1];
    logic[BANK_NUM - 1:0] stbuf_write_bank_id_cmp[0:BANK_NUM - 1];
    logic[`ADDR_WIDTH - BANK_ADDR_WIDTH - 1:0] stbuf_write_bank_addr[0:BANK_NUM - 1];
    logic[BANK_NUM - 1:0] stbuf_set_we_flatten;
    logic stbuf_set_we[0:BANK_NUM - 1];
    logic stbuf_bank_we[0:BANK_NUM - 1];
    logic[7:0] stbuf_set_write_data[0:BANK_NUM - 1];
    logic[7:0] stbuf_bank_write_data[0:BANK_NUM - 1];

    genvar i, j;

    generate
        if(IMAGE_INIT) begin
            initial begin
                $readmemh(IMAGE_PATH, fetch_mem);
                $readmemh(IMAGE_PATH, stbuf_mem);
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        if(rst) begin
            bus_tcm_fetch_addr_r <= 'b0;
        end
        else if(bus_tcm_fetch_rd) begin
            bus_tcm_fetch_addr_r <= bus_tcm_fetch_addr;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            bus_tcm_stbuf_read_addr_r <= 'b0;
        end
        else if(bus_tcm_stbuf_rd) begin
            bus_tcm_stbuf_read_addr_r <= bus_tcm_stbuf_read_addr;
        end
    end

    generate
        for(i = 0;i < BANK_NUM;i = i + 1) begin
            assign fetch_full_addr_set[i] = bus_tcm_fetch_addr + unsigned'(i);
            assign fetch_full_addr_set_r[i] = bus_tcm_fetch_addr_r + unsigned'(i);
            assign fetch_bank_addr_set[i] = fetch_full_addr_set[i][`ADDR_WIDTH - 1:BANK_ADDR_WIDTH];

            for(j = 0;j < BANK_NUM;j = j + 1) begin
                assign fetch_bank_id_cmp[i][j] = fetch_full_addr_set[j][BANK_ADDR_WIDTH - 1:0] == unsigned'(i);
                assign fetch_bank_id_cmp_r[i][j] = fetch_full_addr_set_r[j][BANK_ADDR_WIDTH - 1:0] == unsigned'(i);
            end

            parallel_finder #(
                .WIDTH(BANK_NUM)
            )parallel_finder_fetch_bank_set_index_inst(
                .data_in(fetch_bank_id_cmp_r[i]),
                .index(fetch_bank_set_index[i])
            );

            data_selector #(
                .SEL_WIDTH(BANK_NUM),
                .DATA_WIDTH(`ADDR_WIDTH - BANK_ADDR_WIDTH)
            )data_selector_fetch_bank_addr_inst(
                .sel_in(fetch_bank_id_cmp[i]),
                .data_in(fetch_bank_addr_set),
                .data_out(fetch_bank_addr[i])
            );

            always_ff @(posedge clk) begin
                if(stbuf_bank_we[i] && (stbuf_write_bank_addr[i] == fetch_bank_addr[i])) begin
                    fetch_bank_data_reg[i] <= stbuf_bank_write_data[i];
                end
                else begin
                    fetch_bank_data_reg[i] <= fetch_mem[i][fetch_bank_addr[i]];
                end
            end

            assign fetch_bank_data_reg_shift[i] = ($clog2(`BUS_DATA_WIDTH)'(fetch_bank_set_index[i])) << 3;
            assign fetch_bank_data_recombine[i] = ((i != 0) ? fetch_bank_data_recombine[i - 1] : 'b0) | (fetch_bank_data_reg[i] << fetch_bank_data_reg_shift[i]);
        end
    endgenerate

    assign tcm_bus_fetch_data = fetch_bank_data_recombine[BANK_NUM - 1];

    generate
        for(i = 0;i < BANK_NUM;i = i + 1) begin
            assign stbuf_read_full_addr_set[i] = bus_tcm_stbuf_read_addr + unsigned'(i);
            assign stbuf_read_full_addr_set_r[i] = bus_tcm_stbuf_read_addr_r + unsigned'(i);
            assign stbuf_read_bank_addr_set[i] = stbuf_read_full_addr_set[i][`ADDR_WIDTH - 1:BANK_ADDR_WIDTH];

            for(j = 0;j < BANK_NUM;j = j + 1) begin
                assign stbuf_read_bank_id_cmp[i][j] = stbuf_read_full_addr_set[j][BANK_ADDR_WIDTH - 1:0] == unsigned'(i);
                assign stbuf_read_bank_id_cmp_r[i][j] = stbuf_read_full_addr_set_r[j][BANK_ADDR_WIDTH - 1:0] == unsigned'(i);
            end

            parallel_finder #(
                .WIDTH(BANK_NUM)
            )parallel_finder_stbuf_read_bank_set_index_inst(
                .data_in(stbuf_read_bank_id_cmp_r[i]),
                .index(stbuf_read_bank_set_index[i])
            );

            data_selector #(
                .SEL_WIDTH(BANK_NUM),
                .DATA_WIDTH(`ADDR_WIDTH - BANK_ADDR_WIDTH)
            )data_selector_stbuf_read_bank_addr_inst(
                .sel_in(stbuf_read_bank_id_cmp[i]),
                .data_in(stbuf_read_bank_addr_set),
                .data_out(stbuf_read_bank_addr[i])
            );

            always_ff @(posedge clk) begin
                if(stbuf_bank_we[i] && (stbuf_write_bank_addr[i] == stbuf_read_bank_addr[i])) begin
                    stbuf_read_bank_data_reg[i] <= stbuf_bank_write_data[i];
                end
                else begin
                    stbuf_read_bank_data_reg[i] <= stbuf_mem[i][stbuf_read_bank_addr[i]];
                end
            end

            assign stbuf_read_bank_data_reg_shift[i] = ($clog2(`BUS_DATA_WIDTH)'(stbuf_read_bank_set_index[i])) << 3;
            assign stbuf_read_bank_data_recombine[i] = ((i != 0) ? stbuf_read_bank_data_recombine[i - 1] : 'b0) | (stbuf_read_bank_data_reg[i] << stbuf_read_bank_data_reg_shift[i]);
        end
    endgenerate

    assign tcm_bus_stbuf_data = stbuf_read_bank_data_recombine[BANK_NUM - 1];

    always_comb begin
        if(bus_tcm_stbuf_wr) begin
            case(bus_tcm_stbuf_write_size)
                'd1: stbuf_set_we_flatten = 'b1;
                'd2: stbuf_set_we_flatten = 'b11;
                'd4: stbuf_set_we_flatten = 'b1111;
                default: stbuf_set_we_flatten = 'b0;
            endcase
        end
        else begin
            stbuf_set_we_flatten = 'b0;
        end
    end

    generate
        for(i = 0;i < BANK_NUM;i = i + 1) begin
            assign stbuf_set_we[i] = stbuf_set_we_flatten[i];
            assign stbuf_set_write_data[i] = ((i * 8 + 8) <= `REG_DATA_WIDTH) ? bus_tcm_stbuf_data[i * 8+:8] : 'b0;
        end
    endgenerate

    generate
        for(i = 0;i < BANK_NUM;i = i + 1) begin
            assign stbuf_write_full_addr_set[i] = bus_tcm_stbuf_write_addr + i;
            assign stbuf_write_bank_addr_set[i] = stbuf_write_full_addr_set[i][`ADDR_WIDTH - 1:BANK_ADDR_WIDTH];

            for(j = 0;j < BANK_NUM;j = j + 1) begin
                assign stbuf_write_bank_id_cmp[i][j] = stbuf_write_full_addr_set[j][BANK_ADDR_WIDTH - 1:0] == unsigned'(i);
            end

            data_selector #(
                .SEL_WIDTH(BANK_NUM),
                .DATA_WIDTH(`ADDR_WIDTH - BANK_ADDR_WIDTH)
            )data_selector_stbuf_write_bank_addr_inst(
                .sel_in(stbuf_write_bank_id_cmp[i]),
                .data_in(stbuf_write_bank_addr_set),
                .data_out(stbuf_write_bank_addr[i])
            );

            data_selector #(
                .SEL_WIDTH(BANK_NUM),
                .DATA_WIDTH(1)
            )data_selector_stbuf_bank_we_inst(
                .sel_in(stbuf_write_bank_id_cmp[i]),
                .data_in(stbuf_set_we),
                .data_out(stbuf_bank_we[i])
            );

            data_selector #(
                .SEL_WIDTH(BANK_NUM),
                .DATA_WIDTH(8)
            )data_selector_stbuf_bank_write_data_inst(
                .sel_in(stbuf_write_bank_id_cmp[i]),
                .data_in(stbuf_set_write_data),
                .data_out(stbuf_bank_write_data[i])
            );

            always_ff @(posedge clk) begin
                if(stbuf_bank_we[i]) begin
                    stbuf_mem[i][stbuf_write_bank_addr[i]] <= stbuf_bank_write_data[i];
                    fetch_mem[i][stbuf_write_bank_addr[i]] <= stbuf_bank_write_data[i];
                end
            end
        end
    endgenerate
endmodule