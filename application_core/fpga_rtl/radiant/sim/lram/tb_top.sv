`timescale 1ps/1ps

module tb_top ();
    reg CLK_GSR  = 1;
    reg USER_GSR = 1;
    GSR GSR_INST (.GSR_N(USER_GSR), .CLK(CLK_GSR));

    logic clk, rst_n;
    logic [15:0] wr_addr;
    logic [15:0] rd_addr;
    logic [31:0] wr_data;
    logic [31:0] rd_data;
    logic wr_en;
    logic lramready;

    lram_fb fb0(
        .clk_i(clk),
        .dps_i(1'b0),
        .rst_i(~rst_n),
        .ben_i(4'b0001),
        .wr_clk_en_i(rst_n),
        .rd_clk_en_i(rst_n),
        .wr_en_i(wr_en),
        .wr_data_i(wr_data),
        .rd_addr_i(rd_addr),
        .wr_addr_i(wr_addr),
        .rd_data_o(rd_data),
        .lramready_o(rdy),
        .rd_datavalid_o(lramready)
    )/* synthesis syn_keep=1 nomerge=""*/;

    initial begin
        clk=0;
        forever begin
            #1 clk=~clk;
        end
    end

    logic i;
    initial begin
        rst_n = 0;
        #512000 rst_n = 1;
        #2;
        wr_addr = 'h4753;
        wr_data = 'hffff;
        wr_en = 1;
        rd_addr = 'h4753;
        #2;
        #2;
        #2;
        wr_en = 0;
    end

endmodule