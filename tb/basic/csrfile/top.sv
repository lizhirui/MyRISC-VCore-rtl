`include "config.svh"
`include "common.svh"

module top;
    logic clk;
    logic rst;
    
    logic[`CSR_ADDR_WIDTH - 1:0] excsr_csrf_addr;
    logic[`REG_DATA_WIDTH - 1:0] csrf_excsr_data;
    
    logic[`CSR_ADDR_WIDTH - 1:0] commit_csrf_read_addr[0:`COMMIT_CSR_CHANNEL_NUM - 1];
    logic[`REG_DATA_WIDTH - 1:0] csrf_commit_read_data[0:`COMMIT_CSR_CHANNEL_NUM - 1];
    logic[`CSR_ADDR_WIDTH - 1:0] commit_csrf_write_addr[0:`COMMIT_CSR_CHANNEL_NUM - 1];
    logic[`REG_DATA_WIDTH - 1:0] commit_csrf_write_data[0:`COMMIT_CSR_CHANNEL_NUM - 1];
    logic[`COMMIT_CSR_CHANNEL_NUM - 1:0] commit_csrf_we;
    
    logic[`REG_DATA_WIDTH - 1:0] intif_csrf_mip_data;
    
    logic[`REG_DATA_WIDTH - 1:0] csrf_all_mie_data;
    logic[`REG_DATA_WIDTH - 1:0] csrf_all_mstatus_data;
    logic[`REG_DATA_WIDTH - 1:0] csrf_all_mip_data;
    logic[`REG_DATA_WIDTH - 1:0] csrf_all_mepc_data;
    
    logic fetch_csrf_checkpoint_buffer_full_add;
    logic fetch_csrf_fetch_not_full_add;
    logic fetch_csrf_fetch_decode_fifo_full_add;
    logic decode_csrf_decode_rename_fifo_full_add;
    logic rename_csrf_phy_regfile_full_add;
    logic rename_csrf_rob_full_add;
    logic issue_csrf_issue_execute_fifo_full_add;
    logic issue_csrf_issue_queue_full_add;
    logic commit_csrf_branch_num_add;
    logic commit_csrf_branch_predicted_add;
    logic commit_csrf_branch_hit_add;
    logic commit_csrf_branch_miss_add;
    logic[$clog2(`COMMIT_WIDTH):0] commit_csrf_commit_num_add;
    logic ras_csrf_ras_full_add;

    integer i;

    csrfile csrfile_inst(.*);
    
    task wait_clk;
        @(posedge clk);
        #0.1;
    endtask

    task test;
        rst = 1;
        excsr_csrf_addr = 'b0;

        for(i = 0;i < `COMMIT_CSR_CHANNEL_NUM;i++) begin
            commit_csrf_read_addr[i] = 'b0;
            commit_csrf_write_addr[i] = 'b0;
            commit_csrf_write_data[i] = 'b0;
            commit_csrf_we[i] = 'b0;
        end

        intif_csrf_mip_data = 'b0;
        fetch_csrf_checkpoint_buffer_full_add = 'b0;
        fetch_csrf_fetch_not_full_add = 'b0;
        fetch_csrf_fetch_decode_fifo_full_add = 'b0;
        decode_csrf_decode_rename_fifo_full_add = 'b0;
        rename_csrf_phy_regfile_full_add = 'b0;
        rename_csrf_rob_full_add = 'b0;
        issue_csrf_issue_execute_fifo_full_add = 'b0;
        issue_csrf_issue_queue_full_add = 'b0;
        commit_csrf_branch_num_add = 'b0;
        commit_csrf_branch_predicted_add = 'b0;
        commit_csrf_branch_hit_add = 'b0;
        commit_csrf_branch_miss_add = 'b0;
        commit_csrf_commit_num_add = 'b0;
        ras_csrf_ras_full_add = 'b0;
        wait_clk();
        rst = 0;
        wait_clk();
        excsr_csrf_addr = `CSR_MARCHID;
        wait_clk();
        assert(csrf_excsr_data == 'h19981001) else $finish;
        wait_clk();
        commit_csrf_read_addr[0] = `CSR_MARCHID;
        commit_csrf_read_addr[1] = `CSR_MIMPID;
        commit_csrf_read_addr[2] = `CSR_MISA;
        commit_csrf_read_addr[3] = `CSR_FINISH;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'h19981001) else $finish;
        assert(csrf_commit_read_data[1] == 'h20220201) else $finish;
        assert(csrf_commit_read_data[2] == 'h40001100) else $finish;
        assert(csrf_commit_read_data[3] == 'hffffffff) else $finish;
        wait_clk();
        commit_csrf_read_addr[0] = `CSR_MSCRATCH;
        commit_csrf_read_addr[1] = `CSR_MCAUSE;
        commit_csrf_read_addr[2] = `CSR_MTVAL;
        commit_csrf_read_addr[3] = `CSR_FINISH;
        commit_csrf_write_addr[0] = `CSR_MSCRATCH;
        commit_csrf_write_addr[1] = `CSR_MCAUSE;
        commit_csrf_write_addr[2] = `CSR_MTVAL;
        commit_csrf_write_addr[3] = `CSR_FINISH;
        
        for(i = 0;i < `COMMIT_CSR_CHANNEL_NUM;i++) begin
            commit_csrf_write_data[i] = 'hfabc1245 + i;
            commit_csrf_we[i] = 'b1;
        end

        wait_clk();

        for(i = 0;i < `COMMIT_CSR_CHANNEL_NUM;i++) begin
            assert(csrf_commit_read_data[i] == 'hfabc1245 + i) else begin $display("%d - %x - %x", i, csrf_commit_read_data[i], ('hfabc1245 + i));$finish; end

            commit_csrf_we[i] = 'b0;
        end

        assert(csrf_all_mie_data == 'b0) else $finish;
        assert(csrf_all_mstatus_data == 'b0) else $finish;
        assert(csrf_all_mip_data == 'b0) else $finish;
        assert(csrf_all_mepc_data == 'b0) else $finish;
        intif_csrf_mip_data = 'h888;
        wait_clk();
        assert(csrf_all_mip_data == 'h888) else $finish;
        commit_csrf_write_addr[0] = `CSR_MIE;
        commit_csrf_write_data[0] = 'h880;
        commit_csrf_we[0] = 'b1;
        wait_clk();
        assert(csrf_all_mie_data == 'h880) else $finish;
        commit_csrf_write_addr[0] = `CSR_MSTATUS;
        commit_csrf_write_data[0] = 'b1000;
        wait_clk();
        assert(csrf_all_mstatus_data == 'b1000) else $finish;
        commit_csrf_write_addr[0] = `CSR_MEPC;
        commit_csrf_write_data[0] = 'hff0;
        wait_clk();
        assert(csrf_all_mepc_data == 'hff0) else $finish;
        commit_csrf_we[0] = 'b0;
        commit_csrf_read_addr[0] = `CSR_CB;
        fetch_csrf_checkpoint_buffer_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_FNF;
        fetch_csrf_fetch_not_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_FD;
        fetch_csrf_fetch_decode_fifo_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_DR;
        decode_csrf_decode_rename_fifo_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_PHY;
        rename_csrf_phy_regfile_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_ROB;
        rename_csrf_rob_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_IE;
        issue_csrf_issue_execute_fifo_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_IQ;
        issue_csrf_issue_queue_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_BRANCHNUM;
        commit_csrf_branch_num_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_BRANCHPREDICTED;
        commit_csrf_branch_predicted_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_BRANCHHIT;
        commit_csrf_branch_hit_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_BRANCHMISS;
        commit_csrf_branch_miss_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_RAS;
        ras_csrf_ras_full_add = 'b1;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'b1) else $finish;
        commit_csrf_read_addr[0] = `CSR_MINSTRET;
        commit_csrf_commit_num_add = 'd4;
        #1;
        assert(csrf_commit_read_data[0] == 'b0) else $finish;
        wait_clk();
        assert(csrf_commit_read_data[0] == 'd4) else $finish;
    endtask

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        test();
        $display("TEST PASSED");
        $finish;
    end

    `ifdef FSDB_DUMP
        initial begin
            $fsdbDumpfile("top.fsdb");
            $fsdbDumpvars(0, 0, "+all");
            $fsdbDumpMDA();
        end
    `endif
endmodule