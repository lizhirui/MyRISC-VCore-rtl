`ifndef __CONFIG_FILE_SVH__
`define __CONFIG_FILE_SVH__

    `define FETCH_WIDTH 4
    `define DECODE_WIDTH 4
    `define RENAME_WIDTH 4
    `define READREG_WIDTH `RENAME_WIDTH
    `define ISSUE_WIDTH 2
    `define COMMIT_WIDTH 4
    `define PHY_REG_NUM 128
    `define PHY_REG_ID_WIDTH $clog2(`PHY_REG_NUM)
    `define ARCH_REG_NUM 32
    `define ARCH_REG_ID_WIDTH $clog2(`ARCH_REG_NUM)
    `define FETCH_DECODE_FIFO_SIZE 256
    `define DECODE_RENAME_FIFO_SIZE 16
    `define ISSUE_QUEUE_SIZE 16
    `define ROB_SIZE 64
    `define ROB_ID_WIDTH $clog2(`ROB_SIZE)
    `define CHECKPOINT_BUFFER_SIZE 256
    `define CHECKPOINT_ID_WIDTH $clog2(`CHECKPOINT_BUFFER_SIZE)
    `define ADDR_WIDTH 32
    `define CSR_ADDR_WIDTH 12
    `define SIZE_WIDTH 3
    `define BUS_DATA_WIDTH 128
    `define GSHARE_PC_P1_ADDR_WIDTH 12
    `define GSHARE_PC_P2_ADDR_WIDTH 6
    `define LOCAL_PC_P1_ADDR_WIDTH 12
    `define LOCAL_PC_P2_ADDR_WIDTH 6
    `define RAS_SIZE 256
    `define CALL_PC_P1_ADDR_WIDTH 12
    `define CALL_PC_P2_ADDR_WIDTH 6
    `define STORE_BUFFER_SIZE 16
    `define ALU_UNIT_NUM 2
    `define BRU_UNIT_NUM 1
    `define CSR_UNIT_NUM 1
    `define DIV_UNIT_NUM 1
    `define LSU_UNIT_NUM 1
    `define MUL_UNIT_NUM 2
    `define EXECUTE_UNIT_NUM (`ALU_UNIT_NUM + `BRU_UNIT_NUM + `CSR_UNIT_NUM + `DIV_UNIT_NUM + `LSU_UNIT_NUM + `MUL_UNIT_NUM)
    `define WB_WIDTH `EXECUTE_UNIT_NUM
    `define INSTRUCTION_WIDTH 32
    `define REG_DATA_WIDTH 32
    `define NORMAL_PC_P1_ADDR_WIDTH 12
    `define NORMAL_PC_P2_ADDR_WIDTH 6
    `define INIT_PC 'h80000000
    `define COMMIT_CSR_CHANNEL_NUM 4

    `define TCM_ADDR 'h80000000
    `define TCM_SIZE (1 * 1048576)

    `define CLINT_ADDR 'h20000000
    `define CLINT_SIZE 'h10000

    `define GSHARE_GLOBAL_HISTORY_WIDTH `GSHARE_PC_P1_ADDR_WIDTH
    `define GSHARE_PHT_ADDR_WIDTH (`GSHARE_PC_P1_ADDR_WIDTH + `GSHARE_PC_P2_ADDR_WIDTH)
    `define GSHARE_PHT_SIZE (1 << `GSHARE_PHT_ADDR_WIDTH)
    `define GSHARE_PC_P1_ADDR_MASK ((1 << `GSHARE_PC_P1_ADDR_WIDTH) - 1)
    `define GSHARE_PC_P2_ADDR_MASK ((1 << `GSHARE_PC_P2_ADDR_WIDTH) - 1)
    `define GSHARE_GLOBAL_HISTORY_MASK ((1 << `GSHARE_GLOBAL_HISTORY_WIDTH) - 1)

    `define LOCAL_BHT_ADDR_WIDTH `LOCAL_PC_P1_ADDR_WIDTH
    `define LOCAL_BHT_SIZE (1 << `LOCAL_BHT_ADDR_WIDTH)
    `define LOCAL_BHT_WIDTH `LOCAL_PC_P1_ADDR_WIDTH
    `define LOCAL_PHT_ADDR_WIDTH (`LOCAL_PC_P1_ADDR_WIDTH + `LOCAL_PC_P2_ADDR_WIDTH)
    `define LOCAL_PHT_SIZE (1 << `LOCAL_PHT_ADDR_WIDTH)
    `define LOCAL_PC_P1_ADDR_MASK ((1 << `LOCAL_PC_P1_ADDR_WIDTH) - 1)
    `define LOCAL_PC_P2_ADDR_MASK ((1 << `LOCAL_PC_P2_ADDR_WIDTH) - 1)
    `define LOCAL_BHT_WIDTH_MASK ((1 << `LOCAL_BHT_WIDTH) - 1)

    `define CALL_GLOBAL_HISTORY_WIDTH `CALL_PC_P1_ADDR_WIDTH
    `define CALL_TARGET_CACHE_ADDR_WIDTH (`CALL_PC_P1_ADDR_WIDTH + `CALL_PC_P2_ADDR_WIDTH)
    `define CALL_TARGET_CACHE_SIZE (1 << `CALL_TARGET_CACHE_ADDR_WIDTH)
    `define CALL_PC_P1_ADDR_MASK ((1 << `CALL_PC_P1_ADDR_WIDTH) - 1)
    `define CALL_PC_P2_ADDR_MASK ((1 << `CALL_PC_P2_ADDR_WIDTH) - 1)
    `define CALL_GLOBAL_HISTORY_MASK ((1 << `CALL_GLOBAL_HISTORY_WIDTH) - 1)

    `define NORMAL_GLOBAL_HISTORY_WIDTH `NORMAL_PC_P1_ADDR_WIDTH
    `define NORMAL_TARGET_CACHE_ADDR_WIDTH (`NORMAL_PC_P1_ADDR_WIDTH + `NORMAL_PC_P2_ADDR_WIDTH)
    `define NORMAL_TARGET_CACHE_SIZE (1 << `NORMAL_TARGET_CACHE_ADDR_WIDTH)
    `define NORMAL_PC_P1_ADDR_MASK ((1 << `NORMAL_PC_P1_ADDR_WIDTH) - 1)
    `define NORMAL_PC_P2_ADDR_MASK ((1 << `NORMAL_PC_P2_ADDR_WIDTH) - 1)
    `define NORMAL_GLOBAL_HISTORY_MASK ((1 << `NORMAL_GLOBAL_HISTORY_WIDTH) - 1)

`endif