`timescale 1ns/100ps
`include "config.svh"
`include "common.svh"

module top;
    logic clk;
    logic rst;

    logic int_ext;
    logic rxd;
    logic txd;
    
    integer i, j;
    integer ri;

    logic[7:0] rev_data_buf;

    localparam FREQ_DIV = `SYS_FREQ / `UART_BAUD;

    core_top #(
        .IMAGE_PATH("../../../image/hello_world.hex"),
        .IMAGE_INIT(1)
    )core_top_inst(
        .*
    );
    
    task wait_clk;
        @(posedge clk);
        #0.1;
    endtask

    task eval;
        #0.1;
    endtask

    task test;
        rst = 1;
        int_ext = 0;
        rxd = 1;
        wait_clk();
        rst = 0;
        i = 0;
        repeat(1000000) begin 
            wait_clk();

            /*if(i % 1000 == 0) begin
                $display("i = %0d, pc = %0x", i, core_top_inst.fetch_inst.pc);
            end*/

            i++;
        end
    endtask

    initial begin
        rev_data_buf = 'b0;
        
        while(1) begin
            wait_clk();

            if(!txd) begin
                for(ri = 0;ri < 8;ri++) begin
                    repeat(FREQ_DIV) wait_clk();
                    rev_data_buf[ri] = txd;
                end

                repeat(FREQ_DIV) wait_clk();
                $display("[%0d] %c", i, rev_data_buf);
            end
        end
    end

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        test();
    end
endmodule