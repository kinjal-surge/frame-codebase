/*******************************************************************************
    Verilog netlist generated by IPGEN Lattice Radiant Software (64-bit)
    2023.1.1.200.1
    Soft IP Version: 1.2.0
    2023 11 20 15:26:15
*******************************************************************************/
/*******************************************************************************
    Wrapper Module generated per user settings.
*******************************************************************************/
module ram_ip (clk_i, dps_i, rst_i, wr_clk_en_i, rd_clk_en_i, wr_en_i,
    wr_data_i, wr_addr_i, rd_addr_i, rd_data_o, lramready_o, rd_datavalid_o)/* synthesis syn_black_box syn_declare_black_box=1 */;
    input  clk_i;
    input  dps_i;
    input  rst_i;
    input  wr_clk_en_i;
    input  rd_clk_en_i;
    input  wr_en_i;
    input  [7:0]  wr_data_i;
    input  [15:0]  wr_addr_i;
    input  [15:0]  rd_addr_i;
    output  [7:0]  rd_data_o;
    output  lramready_o;
    output  rd_datavalid_o;
endmodule