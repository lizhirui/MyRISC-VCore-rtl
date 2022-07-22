`include "config.svh"
`include "common.svh"

module top;
    logic clk;
    logic rst;
    
    logic ras_csrf_ras_full_add;
    logic[`ADDR_WIDTH - 1:0] bp_ras_addr;
    logic bp_ras_push;
    logic bp_ras_pop;
    logic[`ADDR_WIDTH - 1:0] ras_bp_addr;

    logic three_ras_csrf_ras_full_add;
    logic[`ADDR_WIDTH - 1:0] three_bp_ras_addr;
    logic three_bp_ras_push;
    logic three_bp_ras_pop;
    logic[`ADDR_WIDTH - 1:0] three_ras_bp_addr;

    integer i;
    
    ras#(
        .DEPTH(2)
    )ras_inst(.*);

    ras#(
        .DEPTH(3)
    )ras_three_inst(
        .*,
        .ras_csrf_ras_full_add(three_ras_csrf_ras_full_add),
        .bp_ras_addr(three_bp_ras_addr),
        .bp_ras_push(three_bp_ras_push),
        .bp_ras_pop(three_bp_ras_pop),
        .ras_bp_addr(three_ras_bp_addr)
    );

    task wait_clk;
        @(posedge clk);
        #0.1;
    endtask

    task test;
        rst = 1;
        bp_ras_addr = 'b0;
        bp_ras_push = 'b0;
        bp_ras_pop = 'b0;
        wait_clk();
        rst = 0;
        wait_clk();
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b1;
        bp_ras_push = 'b1;
        wait_clk();
        assert(ras_bp_addr == 'b1) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b11;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b111;
        wait_clk();
        assert(ras_bp_addr == 'b111) else $finish;
        assert(ras_csrf_ras_full_add == 'b1) else $finish;
        //$finish;
        bp_ras_push = 'b0;
        bp_ras_pop = 'b1;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
    endtask

    task test_cnt;
        rst = 1;
        bp_ras_addr = 'b0;
        bp_ras_push = 'b0;
        bp_ras_pop = 'b0;
        wait_clk();
        rst = 0;
        wait_clk();
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b1;
        bp_ras_push = 'b1;
        wait_clk();
        assert(ras_bp_addr == 'b1) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b11;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b11;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b11;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_push = 'b0;
        bp_ras_pop = 'b1;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b1) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b1) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b1) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
    endtask

    task test_cnt_max;
        rst = 1;
        bp_ras_addr = 'b0;
        bp_ras_push = 'b0;
        bp_ras_pop = 'b0;
        wait_clk();
        rst = 0;
        wait_clk();
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b1;
        bp_ras_push = 'b1;
        wait_clk();
        assert(ras_bp_addr == 'b1) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;

        for(i = 0;i < 10;i++) begin
            bp_ras_addr = 'b11;
            wait_clk();
            assert(ras_bp_addr == 'b11) else $finish;
            assert(ras_csrf_ras_full_add == 'b0) else $finish;
        end
        
        bp_ras_addr = 'b11;
        wait_clk();
        assert(ras_bp_addr == 'b11) else $finish;
        assert(ras_csrf_ras_full_add == 'b1) else $finish;
    endtask

    task test_push_pop;
        rst = 1;
        bp_ras_addr = 'b0;
        bp_ras_push = 'b0;
        bp_ras_pop = 'b0;
        wait_clk();
        rst = 0;
        wait_clk();
        bp_ras_addr = 'b1001;
        bp_ras_push = 'b1;
        bp_ras_pop = 'b1;
        wait_clk();
        assert(ras_bp_addr == 'b1001) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_addr = 'b1111;
        bp_ras_pop = 'b1;
        wait_clk();
        assert(ras_bp_addr == 'b1111) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        bp_ras_push = 'b0;
        wait_clk();
        assert(ras_bp_addr == 'b1111) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(ras_bp_addr == 'b1111) else $finish;
        assert(ras_csrf_ras_full_add == 'b0) else $finish;
    endtask

    task test_push_pop_cnt;
        rst = 1;
        three_bp_ras_addr = 'b0;
        three_bp_ras_push = 'b0;
        three_bp_ras_pop = 'b0;
        wait_clk();
        rst = 0;
        wait_clk();
        three_bp_ras_addr = 'b0110;
        three_bp_ras_push = 'b1;
        wait_clk();
        assert(three_ras_bp_addr == 'b0110) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
        three_bp_ras_addr = 'b1001;
        three_bp_ras_push = 'b1;
        wait_clk();
        assert(three_ras_bp_addr == 'b1001) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
        three_bp_ras_addr = 'b1001;
        three_bp_ras_push = 'b1;
        wait_clk();
        assert(three_ras_bp_addr == 'b1001) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
        three_bp_ras_addr = 'b1111;
        three_bp_ras_pop = 'b1;
        wait_clk();
        assert(three_ras_bp_addr == 'b1111) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
        three_bp_ras_push = 'b0;
        wait_clk();
        assert(three_ras_bp_addr == 'b1001) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(three_ras_bp_addr == 'b0110) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(three_ras_bp_addr == 'b0110) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
        wait_clk();
        assert(three_ras_bp_addr == 'b0110) else $finish;
        assert(three_ras_csrf_ras_full_add == 'b0) else $finish;
    endtask

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        test();
        test_cnt();
        //test_cnt_max();
        test_push_pop();
        test_push_pop_cnt();
        $display("TEST PASSED");
        $finish;
    end

    initial begin
        $fsdbDumpfile("top.fsdb");
        $fsdbDumpvars(0, 0, "+all");
        $fsdbDumpMDA();
    end
endmodule