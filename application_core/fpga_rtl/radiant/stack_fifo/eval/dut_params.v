localparam WADDR_DEPTH = 1024;
localparam WDATA_WIDTH = 8;
localparam RADDR_DEPTH = 1024;
localparam RDATA_WIDTH = 8;
localparam FIFO_CONTROLLER = "HARD_IP";
localparam FORCE_FAST_CONTROLLER = 1;
localparam IMPLEMENTATION = "EBR";
localparam WADDR_WIDTH = 10;
localparam RADDR_WIDTH = 10;
localparam REGMODE = "noreg";
localparam RESETMODE = "async";
localparam ENABLE_ALMOST_FULL_FLAG = "TRUE";
localparam ALMOST_FULL_ASSERTION = "static-single";
localparam ALMOST_FULL_ASSERT_LVL = 1023;
localparam ALMOST_FULL_DEASSERT_LVL = 1022;
localparam ENABLE_ALMOST_EMPTY_FLAG = "TRUE";
localparam ALMOST_EMPTY_ASSERTION = "static-single";
localparam ALMOST_EMPTY_ASSERT_LVL = 1;
localparam ALMOST_EMPTY_DEASSERT_LVL = 2;
localparam ENABLE_DATA_COUNT_WR = "FALSE";
localparam ENABLE_DATA_COUNT_RD = "FALSE";
localparam FAMILY = "LIFCL";
`define LIFCL
`define je5d00
`define LIFCL_17
