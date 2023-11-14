    csi_tx u_csi_tx(.ref_clk_i(ref_clk_i),
        .reset_n_i(reset_n_i),
        .usrstdby_i(usrstdby_i),
        .pd_dphy_i(pd_dphy_i),
        .byte_or_pkt_data_i(byte_or_pkt_data_i),
        .byte_or_pkt_data_en_i(byte_or_pkt_data_en_i),
        .ready_o(ready_o),
        .vc_i(vc_i),
        .dt_i(dt_i),
        .wc_i(wc_i),
        .clk_hs_en_i(clk_hs_en_i),
        .d_hs_en_i(d_hs_en_i),
        .pll_lock_o(pll_lock_o),
        .pix2byte_rstn_o(pix2byte_rstn_o),
        .pkt_format_ready_o(pkt_format_ready_o),
        .d_hs_rdy_o(d_hs_rdy_o),
        .byte_clk_o(byte_clk_o),
        .c2d_ready_o(c2d_ready_o),
        .phdr_xfr_done_o(phdr_xfr_done_o),
        .ld_pyld_o(ld_pyld_o),
        .clk_p_io(clk_p_io),
        .clk_n_io(clk_n_io),
        .d_p_io(d_p_io),
        .d_n_io(d_n_io),
        .sp_en_i(sp_en_i),
        .lp_en_i(lp_en_i));
