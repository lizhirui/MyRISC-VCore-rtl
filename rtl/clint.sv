`include "config.svh"
`include "common.svh"

module clint(
        input logic clk,
        input logic rst,

        input logic[`ADDR_WIDTH - 1:0] bus_clint_read_addr,
        input logic[`ADDR_WIDTH - 1:0] bus_clint_write_addr,
        input logic[`SIZE_WIDTH - 1:0] bus_clint_read_size,
        input logic[`SIZE_WIDTH - 1:0] bus_clint_write_size,
        input logic[`REG_DATA_WIDTH - 1:0] bus_clint_data,
        input logic bus_clint_rd,
        input logic bus_clint_wr,
        output logic[`BUS_DATA_WIDTH - 1:0] clint_bus_data,

        output logic all_intif_int_software_req,
        output logic all_intif_int_timer_req
    );
    
    localparam logic[`ADDR_WIDTH - 1:0] MSIP_ADDR = 'b0;
    localparam logic[`ADDR_WIDTH - 1:0] MTIMECMP_ADDR = 'h4000;
    localparam logic[`ADDR_WIDTH - 1:0] MTIME_ADDR = 'hbff8;

    logic[`REG_DATA_WIDTH - 1:0] msip;
    logic[`REG_DATA_WIDTH * 2 - 1:0] mtimecmp;
    logic[`REG_DATA_WIDTH * 2 - 1:0] mtime;

    always_ff @(posedge clk) begin
        if(rst) begin
            msip <= 'b0;
            mtimecmp <= 'b0;
        end
        else if(bus_clint_wr && (bus_clint_write_size == 'b10)) begin
            if(bus_clint_write_addr == MSIP_ADDR) begin
                msip <= (bus_clint_data[0]) != 0;
            end
            else if(bus_clint_write_addr == MTIMECMP_ADDR) begin
                mtimecmp <= {mtimecmp[`REG_DATA_WIDTH * 2 - 1:`REG_DATA_WIDTH], bus_clint_data};
            end
            else if(bus_clint_write_addr == (MTIMECMP_ADDR + 'h4)) begin
                mtimecmp <= {bus_clint_data, mtimecmp[`REG_DATA_WIDTH - 1:0]};
            end
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            mtime <= 'b0;
        end
        else if(bus_clint_wr && (bus_clint_write_size == 'b10)) begin 
            if(bus_clint_write_addr == MTIME_ADDR) begin
                mtime <= {mtime[`REG_DATA_WIDTH * 2 - 1:`REG_DATA_WIDTH], bus_clint_data};
            end
            else if(bus_clint_write_addr == (MTIME_ADDR + 'h4)) begin
                mtime <= {bus_clint_data, mtime[`REG_DATA_WIDTH - 1:0]};
            end
            else begin
                mtime <= mtime + 'b1;
            end
        end
        else begin
            mtime <= mtime + 'b1;
        end
    end

    always_comb begin
        case(bus_clint_read_addr)
            MSIP_ADDR: clint_bus_data = msip;
            MTIMECMP_ADDR: clint_bus_data = mtimecmp[`REG_DATA_WIDTH - 1:0];
            (MTIMECMP_ADDR + 'h4): clint_bus_data = mtimecmp[`REG_DATA_WIDTH * 2 - 1:`REG_DATA_WIDTH];
            MTIME_ADDR: clint_bus_data = mtime[`REG_DATA_WIDTH - 1:0];
            (MTIME_ADDR + 'h4): clint_bus_data = mtime[`REG_DATA_WIDTH * 2 - 1:`REG_DATA_WIDTH];
            default: clint_bus_data = 'b0;
        endcase
    end

    assign all_intif_int_timer_req = mtime >= mtimecmp;
    assign all_intif_int_software_req = msip[0];
endmodule