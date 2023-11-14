    dphy_rx_ip u_dphy_rx_ip(.clk_byte_o(clk_byte_o),
        .clk_byte_hs_o(clk_byte_hs_o),
        .clk_byte_fr_i(clk_byte_fr_i),
        .reset_n_i(reset_n_i),
        .reset_byte_fr_n_i(reset_byte_fr_n_i),
        .clk_p_io(clk_p_io),
        .clk_n_io(clk_n_io),
        .d_p_io(d_p_io),
        .d_n_io(d_n_io),
        .lp_d_rx_p_o(lp_d_rx_p_o),
        .lp_d_rx_n_o(lp_d_rx_n_o),
        .bd_o(bd_o),
        .cd_clk_o(cd_clk_o),
        .cd_d0_o(cd_d0_o),
        .hs_d_en_o(hs_d_en_o),
        .hs_sync_o(hs_sync_o),
        .lp_hs_state_clk_o(lp_hs_state_clk_o),
        .lp_hs_state_d_o(lp_hs_state_d_o),
        .term_clk_en_o(term_clk_en_o),
        .term_d_en_o(term_d_en_o),
        .payload_en_o(payload_en_o),
        .payload_o(payload_o),
        .dt_o(dt_o),
        .vc_o(vc_o),
        .wc_o(wc_o),
        .ecc_o(ecc_o),
        .ref_dt_i(ref_dt_i),
        .tx_rdy_i(tx_rdy_i),
        .pd_dphy_i(pd_dphy_i),
        .sp_en_o(sp_en_o),
        .lp_en_o(lp_en_o),
        .lp_av_en_o(lp_av_en_o),
        .rxdatsyncfr_state_o(rxdatsyncfr_state_o),
        .rxemptyfr0_o(rxemptyfr0_o),
        .rxemptyfr1_o(rxemptyfr1_o),
        .rxfullfr0_o(rxfullfr0_o),
        .rxfullfr1_o(rxfullfr1_o),
        .rxque_curstate_o(rxque_curstate_o),
        .rxque_empty_o(rxque_empty_o),
        .rxque_full_o(rxque_full_o),
        .fifo_dly_err_o(fifo_dly_err_o),
        .fifo_undflw_err_o(fifo_undflw_err_o),
        .fifo_ovflw_err_o(fifo_ovflw_err_o));
