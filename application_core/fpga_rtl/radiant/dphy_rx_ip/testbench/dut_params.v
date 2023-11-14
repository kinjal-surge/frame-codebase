localparam FAMILY = "LIFCL";
localparam RX_TYPE = "CSI2";
localparam DPHY_RX_IP = "MIXEL";
localparam NUM_RX_LANE = 1;
localparam RX_GEAR = 8;
localparam CIL_BYPASS = "CIL_BYPASSED";
localparam LMMI = "OFF";
localparam AXI4 = "OFF";
localparam DESKEW_EN = "DISABLED";
localparam HSEL = "DISABLED";
localparam TEST_PATTERN = "0b10000000001000000000000000000000";
localparam RX_CLK_MODE = "HS_ONLY";
localparam BYTECLK_MHZ = 45;
localparam BYTECLK_MHZ_FLOAT = 45.000000;
localparam SYNCCLK_MHZ = 60.000000;
localparam DATA_SETTLE_CYC = 5;
localparam T_DATA_SETTLE = "0b000111";
localparam T_CLK_SETTLE = "0b001001";
localparam PARSER = "ON";
localparam LANE_ALIGN = "OFF";
localparam FIFO_DEPTH = 4;
localparam FIFO_TYPE = "EBR";
localparam RX_FIFO = "ON";
localparam RX_FIFO_IMPL = "EBR";
localparam RX_FIFO_DEPTH = 2048;
localparam NUM_QUE_ENT = 4;
localparam RX_FIFO_TYPE = "PINGPONG";
localparam RX_FIFO_PKT_DLY = 8;
localparam RX_FIFO_CTR_WIDTH = 4;
localparam FR_FIFO_CLKMODE = "DC";
localparam FIFO_IF = "CENTERED";
localparam RX_FIFO_MISC = "ON";
`define LIFCL
`define je5d00
`define LIFCL_17
