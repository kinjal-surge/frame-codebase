/*******************************************************************************
    Verilog netlist generated by IPGEN Lattice Radiant Software (64-bit)
    2023.1.1.200.1
    Soft IP Version: 1.6.0
    2023 11 09 12:50:48
*******************************************************************************/
/*******************************************************************************
    Wrapper Module generated per user settings.
*******************************************************************************/
module byte2pixel_ip (reset_byte_n_i, clk_byte_i, sp_en_i, dt_i, lp_av_en_i,
    payload_en_i, payload_i, wc_i, reset_pixel_n_i, clk_pixel_i, fv_o, lv_o,
    pd_o, p_odd_o, write_cycle_o, mem_we_o, mem_re_o, read_cycle_o,
    fifo_empty_o, fifo_full_o, pixcnt_c_o, pix_out_cntr_o, wc_pix_sync_o)/* synthesis syn_black_box syn_declare_black_box=1 */;
    input  reset_byte_n_i;
    input  clk_byte_i;
    input  sp_en_i;
    input  [5:0]  dt_i;
    input  lp_av_en_i;
    input  payload_en_i;
    input  [7:0]  payload_i;
    input  [15:0]  wc_i;
    input  reset_pixel_n_i;
    input  clk_pixel_i;
    output  fv_o;
    output  lv_o;
    output  [9:0]  pd_o;
    output  [1:0]  p_odd_o;
    output  [3:0]  write_cycle_o;
    output  mem_we_o;
    output  mem_re_o;
    output  [1:0]  read_cycle_o;
    output  fifo_empty_o;
    output  fifo_full_o;
    output  [18:0]  pixcnt_c_o;
    output  [15:0]  pix_out_cntr_o;
    output  [15:0]  wc_pix_sync_o;
endmodule