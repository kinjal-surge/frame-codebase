`timescale 1 ns / 1 ns

`include "lram_mem_model.v"
`include "lscc_rstclk_gen.v"
`include "lram_mem_master.v"

`ifndef _TB_TOP_
`define _TB_TOP_

module tb_top();

`include "dut_params.v"

localparam CLK_PERIOD = 100;
localparam RST_DELAY  = 35;
localparam RST_SYNC   = "sync";
localparam TIMEOUT    = 100000000;

// ----------------------
// ----- IP signals -----
// ----------------------

wire clk_i;
wire dps_i;
wire rst_i;

wire errdet_o;
wire lramready_o;

wire                    wr_clk_en_i;
wire                    wr_en_i;
wire [WDATA_WIDTH-1:0]  wr_data_i;
wire [WADDR_WIDTH-1:0]  wr_addr_i;
wire [BYTE_WIDTH-1:0]   ben_i;


wire                    rd_clk_en_i;
wire                    rdout_clken_i;
wire [RADDR_WIDTH-1:0]  rd_addr_i;
wire [3:0]              unaligned_i;

wire [RDATA_WIDTH-1:0]  rd_data_o;
wire                    rd_datavalid_o;
wire [1:0]              ecc_errdet_o;

// -------------------------
// ----- Model signals -----
// -------------------------

`include "dut_inst.v"

GSR GSR_INST( .GSR_N(1'b1), .CLK(1'b0));

generate
    localparam B_BWID = (RDATA_WIDTH/8) < 1 ? 1 : (RDATA_WIDTH/8);
    wire [B_BWID-1:0] ben_b_w;
    if(UNALIGNED_READ) begin
        assign unaligned_i = ben_b_w;
    end
    wire [RDATA_WIDTH-1:0] mem_rd_data_o;
    wire rst_w;
    assign rst_i = rst_w;
    
    lscc_rstclk_gen # (
        .CLK_PERIOD (CLK_PERIOD),
        .RST_DELAY  (RST_DELAY ),
        .RST_SYNC   (RST_SYNC  ),
        .TIMEOUT    (TIMEOUT   )
    ) clk_rst_gen (
        .clk_o   (clk_i),
        .rst_o   (rst_w),
        .rst_n_o ()
    );
    
    lram_mem_master # (
        .MEM_TYPE         ("lram_dp"  ),
        .ADDR_DEPTH_A     (WADDR_DEPTH     ),
        .DATA_WIDTH_A     (WDATA_WIDTH     ),
        .ADDR_DEPTH_B     (RADDR_DEPTH     ),
        .DATA_WIDTH_B     (RDATA_WIDTH     ),
        .REGMODE_A        ("noreg"         ),
        .REGMODE_B        (REGMODE         ),
        .RESETMODE        (RESETMODE       ),
        .RESET_RELEASE    (RESET_RELEASE   ),
        .BYTE_ENABLE_A    (BYTE_ENABLE     ),
        .BYTE_ENABLE_B    (0),             
        .WRITE_MODE_A     ("normal"        ),
        .WRITE_MODE_B     ("normal"        ),
        .UNALIGNED_READ   (UNALIGNED_READ  ),
        .INIT_MODE        (INIT_MODE       ),
        .INIT_FILE        (INIT_FILE       ),
        .INIT_FILE_FORMAT (INIT_FILE_FORMAT),
        .BYTE_WIDTH_A     (BYTE_WIDTH      ),
        .BYTE_WIDTH_B     (B_BWID          )
    ) mem_master (
    // --------------------------
    // ----- Common Signals -----
    // --------------------------
        .clk_i           (clk_i),
        .dps_i           (dps_i),
    // --------------------------
    // ----- Port A signals -----
    // --------------------------
        .rst_a_i         (rst_i),
        .clk_en_a_i      (wr_clk_en_i),
        .rdout_clken_a_i (),
        .wr_en_a_i       (wr_en_i),
        .wr_data_a_i     (wr_data_i),
        .addr_a_i        (wr_addr_i),
        .ben_a_i         (ben_i), 
    
        .rd_data_a_o     (),
        .mem_data_a_o    (),
    // --------------------------
    // ----- Port B signals -----
    // --------------------------
        .rst_b_i         (rst_i),
        .clk_en_b_i      (rd_clk_en_i),
        .rdout_clken_b_i (rdout_clken_i),
        .wr_en_b_i       (),
        .wr_data_b_i     (),
        .addr_b_i        (rd_addr_i),
        .ben_b_i         (ben_b_w), 
    
        .rd_data_b_o     (rd_data_o),
        .mem_data_b_o    (mem_rd_data_o)
    );
    
    lram_mem_model # (
        .ADDR_DEPTH_A     (WADDR_DEPTH     ),
        .DATA_WIDTH_A     (WDATA_WIDTH     ),
        .ADDR_DEPTH_B     (RADDR_DEPTH     ),
        .DATA_WIDTH_B     (RDATA_WIDTH     ),
        .REGMODE_A        ("noreg"         ),
        .REGMODE_B        (REGMODE         ),
        .RESETMODE        (RESETMODE       ),
        .RESET_RELEASE    (RESET_RELEASE   ),

        .BYTE_ENABLE_A    (BYTE_ENABLE     ),
        .BYTE_ENABLE_B    (0),             
        .WRITE_MODE_A     ("normal"        ),
        .WRITE_MODE_B     ("normal"        ),
        .UNALIGNED_READ   (UNALIGNED_READ  ),
        .INIT_MODE        (INIT_MODE       ),
        .INIT_FILE        (INIT_FILE       ),
        .INIT_FILE_FORMAT (INIT_FILE_FORMAT),

        .BYTE_WIDTH_A     (BYTE_WIDTH      ),
        .BYTE_WIDTH_B     (B_BWID          )
    ) mem_model (
    // --------------------------
    // ----- Common Signals -----
    // --------------------------
        .clk_i           (clk_i),
    // --------------------------
    // ----- Port A signals -----
    // --------------------------
        .rst_a_i         (rst_i),
        .clk_en_a_i      (wr_clk_en_i),
        .rdout_clken_a_i (1'b0),
        .wr_en_a_i       (wr_en_i),
        .wr_data_a_i     (wr_data_i),
        .addr_a_i        (wr_addr_i),
        .ben_a_i         (ben_i), 
    
        .rd_data_a_o     (),
    // --------------------------
    // ----- Port B signals -----
    // --------------------------
        .rst_b_i         (rst_i),
        .clk_en_b_i      (rd_clk_en_i),
        .rdout_clken_b_i (rdout_clken_i),
        .wr_en_b_i       (1'b0),
        .wr_data_b_i     ({RDATA_WIDTH{1'b0}}),
        .addr_b_i        (rd_addr_i),
        .ben_b_i         (ben_b_w), 
    
        .rd_data_b_o     (mem_rd_data_o)
    );
endgenerate

endmodule
`endif
