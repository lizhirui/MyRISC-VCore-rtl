`include "config.svh"
`include "common.svh"

module branch_predictor(
        input logic clk,
        input logic rst,
        
        input logic[`ADDR_WIDTH -1:0] fetch_bp_pc,
        input logic[`INSTRUCTION_WIDTH - 1:0] fetch_bp_instruction,
        input logic fetch_bp_valid,
        output logic bp_fetch_jump,
        output logic[`ADDR_WIDTH - 1:0] bp_fetch_next_pc,
        output logic bp_fetch_valid,
        output logic[`GSHARE_GLOBAL_HISTORY_WIDTH - 1:0] bp_fetch_global_history,
        output logic[`LOCAL_BHT_WIDTH - 1:0] bp_fetch_local_history, 
        
        input logic[`ADDR_WIDTH - 1:0] fetch_bp_update_pc,
        input logic[`INSTRUCTION_WIDTH - 1:0] fetch_bp_update_instruction,
        input logic fetch_bp_update_jump,
        input logic[`ADDR_WIDTH - 1:0] fetch_bp_update_next_pc,
        input logic fetch_bp_update_valid,
        
        output logic[`ADDR_WIDTH - 1:0] bp_ras_addr,
        output logic bp_ras_push,
        input logic[`ADDR_WIDTH - 1:0] ras_bp_addr,
        output logic bp_ras_pop,
        
        input checkpoint_t exbru_bp_cp,
        input logic[`ADDR_WIDTH -1:0] exbru_bp_pc,
        input logic[`INSTRUCTION_WIDTH - 1:0] exbru_bp_instruction,
        input logic exbru_bp_jump,
        input logic[`ADDR_WIDTH - 1:0] exbru_bp_next_pc,
        input logic exbru_bp_hit,
        input logic exbru_bp_valid,
        
        input logic[`ADDR_WIDTH -1:0] commit_bp_pc[0:`COMMIT_WIDTH - 1],
        input logic[`INSTRUCTION_WIDTH - 1:0] commit_bp_instruction[0:`COMMIT_WIDTH - 1],
        input logic[`COMMIT_WIDTH - 1:0] commit_bp_jump,
        input logic[`ADDR_WIDTH - 1:0] commit_bp_next_pc[0:`COMMIT_WIDTH - 1],
        input logic[`COMMIT_WIDTH - 1:0] commit_bp_hit,
        input logic[`COMMIT_WIDTH - 1:0] commit_bp_valid
    );

    logic[6:0] fetch_opcode;
    logic[`ARCH_REG_ID_WIDTH - 1:0] fetch_rd;
    logic[`ARCH_REG_ID_WIDTH - 1:0] fetch_rs1;
    logic[12:0] fetch_imm_b;
    logic[20:0] fetch_imm_j;
    logic fetch_rd_is_link;
    logic fetch_rs1_is_link;
    logic fetch_is_branch;
    logic fetch_is_call;
    logic fetch_is_normal_jump;
    logic fetch_is_jal;
    logic fetch_is_jalr;

    logic gshare_jump;
    logic[`ADDR_WIDTH - 1:0] gshare_next_pc;

    logic local_jump;
    logic[`ADDR_WIDTH - 1:0] local_next_pc;

    logic[`ADDR_WIDTH - 1:0] call_next_pc;

    logic[`ADDR_WIDTH - 1:0] normal_next_pc;

    logic[6:0] commit_opcode;
    logic[`ARCH_REG_ID_WIDTH - 1:0] commit_rd;
    logic[`ARCH_REG_ID_WIDTH - 1:0] commit_rs1;
    logic commit_rd_is_link;
    logic commit_rs1_is_link;
    logic commit_is_branch;
    logic commit_is_call;
    logic commit_is_normal_jump;

    logic[$clog2(`COMMIT_WIDTH) - 1:0] commit_index;

    logic[`GSHARE_GLOBAL_HISTORY_WIDTH - 1:0] gshare_global_history;
    logic[`GSHARE_GLOBAL_HISTORY_WIDTH - 1:0] gshare_global_history_next;
    logic[`GSHARE_GLOBAL_HISTORY_WIDTH - 1:0] gshare_global_history_retired;
    logic[1:0] gshare_pht[0:`GSHARE_PHT_SIZE - 1];

    logic[`GSHARE_PHT_ADDR_WIDTH - 1:0] gshare_pht_write_addr;
    logic[1:0] gshare_pht_write_data;
    logic gshare_pht_we;

    logic[`LOCAL_BHT_WIDTH - 1:0] local_bht[0:`LOCAL_BHT_SIZE - 1];
    logic[`LOCAL_BHT_WIDTH - 1:0] local_bht_retired[0:`LOCAL_BHT_SIZE - 1];
    logic[1:0] local_pht[0:`LOCAL_PHT_SIZE - 1];

    logic[`LOCAL_BHT_ADDR_WIDTH - 1:0] local_bht_write_addr;
    logic[`LOCAL_PHT_ADDR_WIDTH - 1:0] local_pht_write_addr;
    logic[1:0] local_pht_write_data;
    logic local_pht_we;

    logic[1:0] cpht[0:`GSHARE_PHT_SIZE - 1];

    logic[`LOCAL_PHT_ADDR_WIDTH - 1:0] cpht_write_addr;
    logic[1:0] cpht_write_data;
    logic cpht_we;

    logic[`CALL_GLOBAL_HISTORY_WIDTH - 1:0] call_global_history;
    logic[`ADDR_WIDTH - 1:0] call_target_cache[0:`CALL_TARGET_CACHE_SIZE - 1];

    logic[`NORMAL_GLOBAL_HISTORY_WIDTH - 1:0] normal_global_history;
    logic[`ADDR_WIDTH - 1:0] normal_target_cache[0:`NORMAL_TARGET_CACHE_SIZE - 1];

    genvar i, j;
    integer gshare_pht_k, local_bht_retired_k, local_bht_k, local_pht_k, cpht_k, call_k, normal_k;

    function logic[`GSHARE_PC_P1_ADDR_WIDTH - 1:0] gshare_get_pc_p1(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        gshare_get_pc_p1 = (pc >> (2 + `GSHARE_PC_P2_ADDR_WIDTH)) & `GSHARE_PC_P1_ADDR_MASK;
    endfunction

    function logic[`GSHARE_PC_P2_ADDR_WIDTH - 1:0] gshare_get_pc_p2(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        gshare_get_pc_p2 = (pc >> 2) & `GSHARE_PC_P2_ADDR_MASK;
    endfunction

    function logic[`GSHARE_PHT_ADDR_WIDTH - 1:0] gshare_get_pht_addr(
            input logic[`GSHARE_GLOBAL_HISTORY_WIDTH - 1:0] global_history,
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        gshare_get_pht_addr = ((global_history ^ gshare_get_pc_p1(pc)) << `GSHARE_PC_P2_ADDR_WIDTH) | gshare_get_pc_p2(pc);
    endfunction

    function logic[`LOCAL_PC_P1_ADDR_WIDTH - 1:0] local_get_pc_p1(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        local_get_pc_p1 = (pc >> (2 + `LOCAL_PC_P2_ADDR_WIDTH)) & `LOCAL_PC_P1_ADDR_MASK;
    endfunction

    function logic[`LOCAL_PC_P2_ADDR_WIDTH - 1:0] local_get_pc_p2(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        local_get_pc_p2 = (pc >> 2) & `LOCAL_PC_P2_ADDR_MASK;
    endfunction

    function logic[`LOCAL_PHT_ADDR_WIDTH - 1:0] local_get_pht_addr(
            input logic[`LOCAL_BHT_WIDTH - 1:0] bht_value,
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        local_get_pht_addr = ((bht_value ^ local_get_pc_p1(pc)) << `LOCAL_PC_P2_ADDR_WIDTH) | local_get_pc_p2(pc);
    endfunction

    function logic[`GSHARE_PC_P1_ADDR_WIDTH - 1:0] cpht_get_pc_p1(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        cpht_get_pc_p1 = (pc >> (2 + `GSHARE_PC_P2_ADDR_WIDTH)) & `GSHARE_PC_P1_ADDR_MASK;
    endfunction

    function logic[`GSHARE_PC_P2_ADDR_WIDTH - 1:0] cpht_get_pc_p2(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        cpht_get_pc_p2 = (pc >> 2) & `GSHARE_PC_P2_ADDR_MASK;
    endfunction

    function logic[`GSHARE_PHT_ADDR_WIDTH - 1:0] cpht_get_pht_addr(
            input logic[`GSHARE_GLOBAL_HISTORY_WIDTH - 1:0] global_history,
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        cpht_get_pht_addr = ((global_history ^ cpht_get_pc_p1(pc)) << `GSHARE_PC_P2_ADDR_WIDTH) | cpht_get_pc_p2(pc);
    endfunction

    function logic[`CALL_PC_P1_ADDR_WIDTH - 1:0] call_get_pc_p1(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        call_get_pc_p1 = (pc >> (2 + `CALL_PC_P2_ADDR_WIDTH)) & `CALL_PC_P1_ADDR_MASK;
    endfunction

    function logic[`CALL_PC_P2_ADDR_WIDTH - 1:0] call_get_pc_p2(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        call_get_pc_p2 = (pc >> 2) & `CALL_PC_P2_ADDR_MASK;
    endfunction

    function logic[`CALL_TARGET_CACHE_ADDR_WIDTH - 1:0] call_get_target_cache_addr(
            input logic[`CALL_GLOBAL_HISTORY_WIDTH - 1:0] global_history,
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        call_get_target_cache_addr = ((global_history ^ call_get_pc_p1(pc)) << `CALL_PC_P2_ADDR_WIDTH) | call_get_pc_p2(pc);
    endfunction

    function logic[`NORMAL_PC_P1_ADDR_WIDTH - 1:0] normal_get_pc_p1(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        normal_get_pc_p1 = (pc >> (2 + `NORMAL_PC_P2_ADDR_WIDTH)) & `NORMAL_PC_P1_ADDR_MASK;
    endfunction

    function logic[`NORMAL_PC_P2_ADDR_WIDTH - 1:0] normal_get_pc_p2(
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        normal_get_pc_p2 = (pc >> 2) & `CALL_PC_P2_ADDR_MASK;
    endfunction

    function logic[`NORMAL_TARGET_CACHE_ADDR_WIDTH - 1:0] normal_get_target_cache_addr(
            input logic[`NORMAL_GLOBAL_HISTORY_WIDTH - 1:0] global_history,
            input logic[`ADDR_WIDTH - 1:0] pc
        );

        normal_get_target_cache_addr = ((global_history ^ normal_get_pc_p1(pc)) << `NORMAL_PC_P2_ADDR_WIDTH) | normal_get_pc_p2(pc);
    endfunction

    priority_finder #(
        .FIRST_PRIORITY(1),
        .WIDTH(`COMMIT_WIDTH)
    )priority_finder_commit_channel_sel_inst(
        .data_in(commit_bp_valid),
        .index(commit_index)
    );

    assign fetch_opcode = fetch_bp_instruction[6:0];
    assign fetch_rd = fetch_bp_instruction[7+:5];
    assign fetch_rs1 = fetch_bp_instruction[15+:5];
    assign fetch_imm_b = {fetch_bp_instruction[31], fetch_bp_instruction[7], fetch_bp_instruction[25+:6], fetch_bp_instruction[8+:4], 1'b0};
    assign fetch_imm_j = {fetch_bp_instruction[31], fetch_bp_instruction[12+:8], fetch_bp_instruction[20], fetch_bp_instruction[21+:10], 1'b0};

    assign fetch_rd_is_link = (fetch_rd == 'h1) || (fetch_rd == 'h5);
    assign fetch_rs1_is_link = (fetch_rs1 == 'h1) || (fetch_rs1 == 'h5);
    assign fetch_is_jal = fetch_opcode == 'h6f;
    assign fetch_is_jalr = fetch_opcode == 'h67;
    assign fetch_is_branch = fetch_opcode == 'h63;
    assign fetch_is_call = fetch_is_jalr && fetch_rd_is_link && (!fetch_rs1_is_link || (fetch_rs1 == fetch_rd));
    assign fetch_is_normal_jump = fetch_is_jalr && !fetch_rd_is_link && !fetch_rs1_is_link;

    assign gshare_jump = gshare_pht[gshare_get_pht_addr(gshare_global_history, fetch_bp_pc)] >= 2;
    assign gshare_next_pc = gshare_jump ? (fetch_bp_pc + sign_extend#(13)::_do(fetch_imm_b)) : (fetch_bp_pc + 'd4);

    assign local_jump = local_pht[local_get_pht_addr(local_bht[local_get_pc_p2(fetch_bp_pc)], fetch_bp_pc)] >= 2;
    assign local_next_pc = local_jump ? (fetch_bp_pc + sign_extend#(13)::_do(fetch_imm_b)) : (fetch_bp_pc + 'd4);

    assign call_next_pc = call_target_cache[call_get_target_cache_addr(call_global_history, fetch_bp_pc)];

    assign normal_next_pc = normal_target_cache[normal_get_target_cache_addr(normal_global_history, fetch_bp_pc)];

    assign bp_fetch_jump = fetch_is_branch ? ((cpht[cpht_get_pht_addr(gshare_global_history, fetch_bp_pc)] <= 1) ? gshare_jump : local_jump) : 'b1;
    assign bp_fetch_next_pc = fetch_is_branch ? ((cpht[cpht_get_pht_addr(gshare_global_history, fetch_bp_pc)] <= 1) ? gshare_next_pc : local_next_pc) : 
                              fetch_is_jal ? (fetch_bp_pc + sign_extend#(21)::_do(fetch_imm_j)) : 
                              fetch_is_jalr ? (fetch_is_call ? call_next_pc : fetch_is_normal_jump ? normal_next_pc : ras_bp_addr) : ras_bp_addr;

    assign bp_fetch_valid = fetch_bp_valid;
    assign bp_fetch_global_history = gshare_global_history;
    assign bp_fetch_local_history = local_bht[local_get_pc_p2(fetch_bp_pc)];

    assign bp_ras_addr = fetch_bp_pc + 'd4;
    assign bp_ras_push = fetch_bp_valid && fetch_is_jalr && fetch_rd_is_link;
    assign bp_ras_pop = fetch_bp_valid && fetch_is_jalr && ((fetch_rd_is_link && fetch_rs1_is_link && (fetch_rs1 != fetch_rd)) || 
                        (!fetch_rd_is_link && fetch_rs1_is_link));

    assign commit_opcode = commit_bp_instruction[commit_index][6:0];
    assign commit_rd = commit_bp_instruction[commit_index][7+:5];
    assign commit_rs1 = commit_bp_instruction[commit_index][15+:5];
    assign commit_rd_is_link = (commit_rd == 'h1) || (commit_rd == 'h5);
    assign commit_rs1_is_link = (commit_rs1 == 'h1) || (commit_rs1 == 'h5);
    assign commit_is_branch = commit_opcode == 'h63;
    assign commit_is_call = (commit_opcode == 'h67) && commit_rd_is_link && (!commit_rs1_is_link || (commit_rs1 == commit_rd));
    assign commit_is_normal_jump = (commit_opcode == 'h67) && !commit_rd_is_link && !commit_rs1_is_link;

    always_ff @(posedge clk) begin
        if(rst) begin
            gshare_global_history <= 'b0;
        end
        else begin
            gshare_global_history <= gshare_global_history_next;
        end
    end

    always_comb begin
        gshare_global_history_next = gshare_global_history;

        if(commit_bp_valid[commit_index] && !commit_bp_hit[commit_index] && commit_is_branch) begin
            gshare_global_history_next = ((gshare_global_history_retired << 1) & `GSHARE_GLOBAL_HISTORY_MASK) | (commit_bp_jump[commit_index] ? 'b1 : 'b0);
        end
        else if(fetch_bp_update_valid && fetch_is_branch) begin
            if(exbru_bp_valid && !exbru_bp_hit) begin
                gshare_global_history_next = (((((exbru_bp_cp.global_history << 1) & `GSHARE_GLOBAL_HISTORY_MASK) | (exbru_bp_jump ? 'b1 : 'b0)) << 1) & `GSHARE_GLOBAL_HISTORY_MASK) | (fetch_bp_update_jump ? 'b1 : 'b0);
            end
            else begin
                gshare_global_history_next = ((gshare_global_history << 1) & `GSHARE_GLOBAL_HISTORY_MASK) | (fetch_bp_update_jump ? 'b1 : 'b0);
            end
        end
        else if(exbru_bp_valid && !exbru_bp_hit) begin
            gshare_global_history_next = ((exbru_bp_cp.global_history << 1) & `GSHARE_GLOBAL_HISTORY_MASK) | (exbru_bp_jump ? 'b1 : 'b0);
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            gshare_global_history_retired <= 'b0;
        end
        else if(commit_bp_valid[commit_index] && commit_is_branch) begin
            gshare_global_history_retired <= ((gshare_global_history_retired << 1) & `GSHARE_GLOBAL_HISTORY_MASK) | (commit_bp_jump[commit_index] ? 'b1 : 'b0);
        end
    end

    assign gshare_pht_write_addr = gshare_get_pht_addr(gshare_global_history_retired, commit_bp_pc[commit_index]);
    assign gshare_pht_write_data = commit_bp_jump[commit_index] ? (gshare_pht[gshare_pht_write_addr] + 'b1) : (gshare_pht[gshare_pht_write_addr] - 'b1);
    assign gshare_pht_we = commit_bp_valid[commit_index] && commit_is_branch && ((commit_bp_jump[commit_index] && (gshare_pht[gshare_pht_write_addr] < 'd3)) || 
                           (!commit_bp_jump[commit_index] && (gshare_pht[gshare_pht_write_addr] > 'd0)));

    always_ff @(posedge clk) begin
        if(rst) begin
            for(gshare_pht_k = 0;gshare_pht_k < `GSHARE_PHT_SIZE;gshare_pht_k = gshare_pht_k + 1) begin
                gshare_pht[gshare_pht_k] <= 'b0;
            end
        end
        else if(gshare_pht_we) begin
            gshare_pht[gshare_pht_write_addr] <= gshare_pht_write_data;
        end
    end

    assign local_bht_write_addr = local_get_pc_p1(commit_bp_pc[commit_index]);
    assign local_pht_write_addr = local_get_pht_addr(local_bht_retired[local_bht_write_addr], commit_bp_pc[commit_index]);
    assign local_pht_write_data = commit_bp_jump[commit_index] ? (gshare_pht[local_pht_write_addr] + 'b1) : (gshare_pht[local_pht_write_addr] - 'b1);
    assign local_pht_we = commit_bp_valid[commit_index] && commit_is_branch && ((commit_bp_jump[commit_index] && (gshare_pht[local_pht_write_addr] < 'd3)) || 
                          (!commit_bp_jump[commit_index] && (gshare_pht[local_pht_write_addr] > 'd0)));

    always_ff @(posedge clk) begin
        if(rst) begin
            for(local_bht_retired_k = 0;local_bht_retired_k < `LOCAL_BHT_SIZE;local_bht_retired_k = local_bht_retired_k + 1) begin
                local_bht_retired[local_bht_retired_k] <= 'b0;
            end
        end
        else if(commit_bp_valid[commit_index] && commit_is_branch) begin
            local_bht_retired[local_bht_write_addr] <= ((local_bht_retired[local_bht_write_addr] << 1) & `LOCAL_BHT_WIDTH_MASK) | (commit_bp_jump[commit_index] ? 'b1 : 'b0);
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(local_bht_k = 0;local_bht_k < `LOCAL_BHT_SIZE;local_bht_k = local_bht_k + 1) begin
                local_bht[local_bht_k] <= 'b0;
            end
        end
        else if(commit_bp_valid[commit_index] && !commit_bp_hit[commit_index] && commit_is_branch) begin
            local_bht[local_bht_write_addr] <= ((local_bht_retired[local_bht_write_addr] << 1) & `LOCAL_BHT_WIDTH_MASK) | (commit_bp_jump[commit_index] ? 'b1 : 'b0);
        end
        else if(fetch_bp_update_valid && fetch_is_branch) begin
            if(exbru_bp_valid && !exbru_bp_hit && (local_get_pc_p1(exbru_bp_pc) == local_get_pc_p1(fetch_bp_pc))) begin
                local_bht[local_get_pc_p1(fetch_bp_pc)] <= (((((exbru_bp_cp.local_history << 1) & `LOCAL_BHT_WIDTH_MASK) | (exbru_bp_jump ? 'b1 : 'b0)) << 1) & `LOCAL_BHT_WIDTH_MASK) | (fetch_bp_update_jump ? 'b1 : 'b0);
            end
            else begin
                local_bht[local_get_pc_p1(fetch_bp_pc)] <= ((gshare_global_history << 1) & `LOCAL_BHT_WIDTH_MASK) | (fetch_bp_update_jump ? 'b1 : 'b0);
            end
        end
        else if(exbru_bp_valid && !exbru_bp_hit) begin
            local_bht[local_get_pc_p1(exbru_bp_pc)] <= ((exbru_bp_cp.global_history << 1) & `LOCAL_BHT_WIDTH_MASK) | (exbru_bp_jump ? 'b1 : 'b0);
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(local_pht_k = 0;local_pht_k < `LOCAL_PHT_SIZE;local_pht_k = local_pht_k + 1) begin
                local_pht[local_pht_k] <= 'b0;
            end
        end
        else if(local_pht_we) begin
            local_pht[local_pht_write_addr] <= local_pht_write_data;
        end
    end

    assign cpht_write_addr = cpht_get_pht_addr(gshare_global_history, commit_bp_pc[commit_index]);
    assign cpht_write_data = (((cpht[cpht_write_addr] <= 'd1) && (!commit_bp_hit[commit_index])) || ((cpht[cpht_write_addr] > 'd1) && commit_bp_hit[commit_index] && (cpht[cpht_write_addr] < 'd3))) ?
                             (cpht[cpht_write_addr] + 'b1) : (cpht[cpht_write_addr] - 'b1);
    assign cpht_we = commit_bp_valid[commit_index] && commit_is_branch && (((cpht[cpht_write_addr] <= 'd1) && ((commit_bp_hit[commit_index] && (cpht[cpht_write_addr] > 'd0)) || !commit_bp_hit[commit_index])) || 
                     ((cpht[cpht_write_addr] > 'd1) && ((commit_bp_hit[commit_index] && (cpht[cpht_write_addr] < 'd3)) || !commit_bp_hit[commit_index])));

    always_ff @(posedge clk) begin
        if(rst) begin
            for(cpht_k = 0;cpht_k < `GSHARE_PHT_SIZE;cpht_k = cpht_k + 1) begin
                cpht[cpht_k] <= 'b0;
            end
        end
        else if(cpht_we) begin
            cpht[cpht_write_addr] <= cpht_write_data;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            call_global_history <= 'b0;
        end
        else if(commit_bp_valid && commit_is_call) begin
            call_global_history <= ((call_global_history << 1) & `CALL_GLOBAL_HISTORY_MASK) | (commit_bp_jump[commit_index] ? 'b1 : 'b0);
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(call_k = 0;call_k < `CALL_TARGET_CACHE_SIZE;call_k = call_k + 1) begin
                call_target_cache[call_k] <= 'b0;
            end
        end
        else if(commit_bp_valid[commit_index] && commit_is_call) begin
            call_target_cache[call_get_target_cache_addr(call_global_history, commit_bp_pc[commit_index])] <= commit_bp_next_pc[commit_index];
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            normal_global_history <= 'b0;
        end
        else if(commit_bp_valid[commit_index] && commit_is_normal_jump) begin
            normal_global_history <= ((normal_global_history << 1) & `NORMAL_GLOBAL_HISTORY_MASK) | (commit_bp_jump[commit_index] ? 'b1 : 'b0);
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(normal_k = 0;normal_k < `NORMAL_TARGET_CACHE_SIZE;normal_k = normal_k + 1) begin
                normal_target_cache[normal_k] <= 'b0;
            end
        end
        else if(commit_bp_valid[commit_index] && commit_is_normal_jump) begin
            normal_target_cache[normal_get_target_cache_addr(normal_global_history, commit_bp_pc[commit_index])] <= commit_bp_next_pc[commit_index];
        end
    end
endmodule