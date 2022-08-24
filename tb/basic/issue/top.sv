`include "config.svh"
`include "common.svh"

module top;
    logic clk;
    logic rst;
    
    logic stbuf_all_empty;
        
    logic[`PHY_REG_ID_WIDTH - 1:0] issue_phyf_id[0:`READREG_WIDTH - 1][0:1];
    logic[`REG_DATA_WIDTH - 1:0] phyf_issue_data[0:`READREG_WIDTH - 1][0:1];
    logic phyf_issue_data_valid[0:`READREG_WIDTH - 1][0:1];

    logic[`ADDR_WIDTH - 1:0] issue_stbuf_read_addr;
    logic[`SIZE_WIDTH - 1:0] issue_stbuf_read_size;
    logic issue_stbuf_rd;
    
    logic issue_csrf_issue_execute_fifo_full_add;
    logic issue_csrf_issue_queue_full_add;
    
    readreg_issue_pack_t readreg_issue_port_data_out;
    
    logic[`ALU_UNIT_NUM - 1:0] issue_alu_fifo_full;
    issue_execute_pack_t issue_alu_fifo_data_in[0:`ALU_UNIT_NUM - 1];
    logic[`ALU_UNIT_NUM - 1:0] issue_alu_fifo_push;
    logic[`ALU_UNIT_NUM - 1:0] issue_alu_fifo_flush;
    logic[`BRU_UNIT_NUM - 1:0] issue_bru_fifo_full;
    issue_execute_pack_t issue_bru_fifo_data_in[0:`BRU_UNIT_NUM - 1];
    logic[`BRU_UNIT_NUM - 1:0] issue_bru_fifo_push;
    logic[`BRU_UNIT_NUM - 1:0] issue_bru_fifo_flush;
    logic[`CSR_UNIT_NUM - 1:0] issue_csr_fifo_full;
    issue_execute_pack_t issue_csr_fifo_data_in[0:`CSR_UNIT_NUM - 1];
    logic[`CSR_UNIT_NUM - 1:0] issue_csr_fifo_push;
    logic[`CSR_UNIT_NUM - 1:0] issue_csr_fifo_flush;
    logic[`DIV_UNIT_NUM - 1:0] issue_div_fifo_full;
    issue_execute_pack_t issue_div_fifo_data_in[0:`DIV_UNIT_NUM - 1];
    logic[`DIV_UNIT_NUM - 1:0] issue_div_fifo_push;
    logic[`DIV_UNIT_NUM - 1:0] issue_div_fifo_flush;
    logic[`LSU_UNIT_NUM - 1:0] issue_lsu_fifo_full;
    issue_execute_pack_t issue_lsu_fifo_data_in[0:`LSU_UNIT_NUM - 1];
    logic[`LSU_UNIT_NUM - 1:0] issue_lsu_fifo_push;
    logic[`LSU_UNIT_NUM - 1:0] issue_lsu_fifo_flush;
    logic[`MUL_UNIT_NUM - 1:0] issue_mul_fifo_full;
    issue_execute_pack_t issue_mul_fifo_data_in[0:`MUL_UNIT_NUM - 1];
    logic[`MUL_UNIT_NUM - 1:0] issue_mul_fifo_push;
    logic[`MUL_UNIT_NUM - 1:0] issue_mul_fifo_flush;
    
    issue_feedback_pack_t issue_feedback_pack;
    execute_feedback_pack_t execute_feedback_pack;
    wb_feedback_pack_t wb_feedback_pack;
    commit_feedback_pack_t commit_feedback_pack;

    integer i, j, k;

    issue issue_inst(.*);

    task wait_clk;
        @(posedge clk);
        #0.1;
    endtask

    task eval;
        #0.1;
    endtask

    task test;
        rst = 1;
        stbuf_all_empty = 'b0;

        for(i = 0;i < `READREG_WIDTH;i++) begin
            for(j = 0;j < 2;j++) begin
                phyf_issue_data[i][j] = 'b0;
                phyf_issue_data_valid[i][j] = 'b0;
            end
        end

        for(i = 0;i < `READREG_WIDTH;i++) begin
            readreg_issue_port_data_out.op_info[i].enable = 'b0;
            readreg_issue_port_data_out.op_info[i].value = 'b0;
            readreg_issue_port_data_out.op_info[i].valid = 'b0;
            readreg_issue_port_data_out.op_info[i].rob_id = 'b0;
            readreg_issue_port_data_out.op_info[i].pc = 'b0;
            readreg_issue_port_data_out.op_info[i].imm = 'b0;
            readreg_issue_port_data_out.op_info[i].has_exception = 'b0;
            readreg_issue_port_data_out.op_info[i].exception_id = riscv_exception_t::instruction_address_misaligned;
            readreg_issue_port_data_out.op_info[i].exception_value = 'b0;
            readreg_issue_port_data_out.op_info[i].predicted = 'b0;
            readreg_issue_port_data_out.op_info[i].predicted_jump = 'b0;
            readreg_issue_port_data_out.op_info[i].predicted_next_pc = 'b0;
            readreg_issue_port_data_out.op_info[i].checkpoint_id_valid = 'b0;
            readreg_issue_port_data_out.op_info[i].checkpoint_id = 'b0;
            readreg_issue_port_data_out.op_info[i].rs1 = 'b0;
            readreg_issue_port_data_out.op_info[i].arg1_src = arg_src_t::_reg;
            readreg_issue_port_data_out.op_info[i].rs1_need_map = 'b0;
            readreg_issue_port_data_out.op_info[i].rs1_phy = 'b0;
            readreg_issue_port_data_out.op_info[i].src1_value = 'b0;
            readreg_issue_port_data_out.op_info[i].src1_loaded = 'b0;
            readreg_issue_port_data_out.op_info[i].rs2 = 'b0;
            readreg_issue_port_data_out.op_info[i].arg2_src = arg_src_t::_reg;
            readreg_issue_port_data_out.op_info[i].rs2_need_map = 'b0;
            readreg_issue_port_data_out.op_info[i].rs2_phy = 'b0;
            readreg_issue_port_data_out.op_info[i].src2_value = 'b0;
            readreg_issue_port_data_out.op_info[i].src2_loaded = 'b0;
            readreg_issue_port_data_out.op_info[i].rd = 'b0;
            readreg_issue_port_data_out.op_info[i].rd_enable = 'b0;
            readreg_issue_port_data_out.op_info[i].need_rename = 'b0;
            readreg_issue_port_data_out.op_info[i].rd_phy = 'b0;
            readreg_issue_port_data_out.op_info[i].csr = 'b0;
            readreg_issue_port_data_out.op_info[i].op = op_t::add;
            readreg_issue_port_data_out.op_info[i].op_unit = op_unit_t::alu;
            readreg_issue_port_data_out.op_info[i].sub_op.alu_op = alu_op_t::add;
        end

        issue_alu_fifo_full = 'b0;
        issue_bru_fifo_full = 'b0;
        issue_csr_fifo_full = 'b0;
        issue_div_fifo_full = 'b0;
        issue_lsu_fifo_full = 'b0;
        issue_mul_fifo_full = 'b0;

        for(i = 0;i < `EXECUTE_UNIT_NUM;i++) begin
            execute_feedback_pack.channel[i].enable = 'b0;
            execute_feedback_pack.channel[i].phy_id = 'b0;
            execute_feedback_pack.channel[i].value = 'b0;
            wb_feedback_pack.channel[i].enable = 'b0;
            wb_feedback_pack.channel[i].phy_id = 'b0;
            wb_feedback_pack.channel[i].value = 'b0;
        end

        commit_feedback_pack.enable = 'b0;
        commit_feedback_pack.next_handle_rob_id_valid = 'b0;
        commit_feedback_pack.has_exception = 'b0;
        commit_feedback_pack.exception_pc = 'b0;
        commit_feedback_pack.flush = 'b0;
        commit_feedback_pack.committed_rob_id = 'b0;
        commit_feedback_pack.committed_rob_id_valid = 'b0;
        commit_feedback_pack.jump_enable = 'b0;
        commit_feedback_pack.jump = 'b0;
        commit_feedback_pack.next_pc = 'b0;
        wait_clk();
        rst = 0;
        assert(issue_stbuf_rd == 'b0) else $finish;
        assert(issue_csrf_issue_execute_fifo_full_add == 'b0) else $finish;
        assert(issue_csrf_issue_queue_full_add == 'b0) else $finish;
        assert(issue_alu_fifo_push == 'b0) else $finish;
        assert(issue_bru_fifo_push == 'b0) else $finish;
        assert(issue_csr_fifo_push == 'b0) else $finish;
        assert(issue_div_fifo_push == 'b0) else $finish;
        assert(issue_lsu_fifo_push == 'b0) else $finish;
        assert(issue_mul_fifo_push == 'b0) else $finish;
        assert(issue_feedback_pack.stall == 'b0) else $finish;
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