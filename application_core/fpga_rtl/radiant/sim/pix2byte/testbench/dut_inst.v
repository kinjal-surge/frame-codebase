    pix2byte u_pix2byte(.rst_n_i(rst_n_i),
        .pix_clk_i(pix_clk_i),
        .byte_clk_i(byte_clk_i),
        .fv_i(fv_i),
        .lv_i(lv_i),
        .dvalid_i(dvalid_i),
        .pix_data0_i(pix_data0_i),
        .c2d_ready_i(c2d_ready_i),
        .txfr_en_i(txfr_en_i),
        .fv_start_o(fv_start_o),
        .fv_end_o(fv_end_o),
        .lv_start_o(lv_start_o),
        .lv_end_o(lv_end_o),
        .txfr_req_o(txfr_req_o),
        .byte_en_o(byte_en_o),
        .byte_data_o(byte_data_o),
        .data_type_o(data_type_o),
        .fifo_overflow_o(fifo_overflow_o),
        .fifo_underflow_o(fifo_underflow_o),
        .fifo_full_o(fifo_full_o),
        .fifo_empty_o(fifo_empty_o));
