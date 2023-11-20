localparam FAMILY = "LIFCL";
localparam DEVICE = "LIFCL-17";
localparam TX_INTF = "CSI2";
localparam DPHY_IP = "MIXEL";
localparam NUM_TX_LANE = 1;
localparam GEAR = 8;
localparam DAT_INTLVD = "OFF";
localparam CIL_BYPASS = "CIL_BYPASSED";
localparam PKT_FORMAT = "ON";
localparam PKTHDR_FIFO_IMPL = "EBR";
localparam LMMI = "OFF";
localparam FREQ_CHANGE_TEST = "OFF";
localparam AXI4 = "OFF";
localparam FRAME_CNT_ENABLE = "OFF";
localparam FRAME_CNT_VAL = 1;
localparam LINE_CNT_ENABLE = "OFF";
localparam VCX_EN = "OFF";
localparam EOTP_ENABLE = "OFF";
localparam LPTXESC = "DISABLE";
localparam BTA = "DISABLE";
localparam BYTE_ESC_CLOCKS = "ASYNC";
localparam TX_LINE_RATE_PER_LANE = 360.000000;
localparam DELAYB_DEL_VALUE = "47";
localparam DELAYB_COARSE_DELAY = "0P8NS";
localparam CLK_MODE = "HS_ONLY";
localparam PLL_MODE = "INTERNAL";
localparam REF_CLOCK_FREQ = 96.000000;
localparam HSEL = "DISABLED";
localparam CN = "11000";
localparam CM = "11011100";
localparam CO = "010";
localparam N = 4;
localparam M = 60;
localparam O = 4;
localparam BYTE_CLK_FREQ = 45.000000;
localparam TINIT_COUNT = "OFF";
localparam TINIT_VALUE = 1000;
localparam MISC_ON = "ON";
localparam T_LPX = 3;
localparam T_DATPREP = 3;
localparam T_SKEWCAL_HSZERO = 1;
localparam T_DAT_HSZERO = 2;
localparam T_DATTRAIL = 10;
localparam T_DATEXIT = 6;
localparam T_CLKPREP = 2;
localparam T_CLK_HSZERO = 35;
localparam T_CLKPRE = 1;
localparam T_CLKPOST = 9;
localparam T_CLKTRAIL = 4;
localparam T_CLKEXIT = 6;
localparam T_SKEWCAL_INIT = 4097;
localparam T_SKEWCAL_PERIOD = 129;
`define LIFCL
`define je5d00
`define LIFCL_17