module top (
	output logic cam_clk24,
	input logic sck,
	input logic copi,
	output logic cipo,
	input logic cs,
	inout wire mipi_clk_p,
	inout wire mipi_clk_n,
	inout wire mipi_data_p,
	inout wire mipi_data_n,
    output logic display_clk_o,
    output logic display_hsync,
    output logic display_vsync,
    output logic [3:0] display_y,
    output logic [2:0] display_cr,
    output logic [2:0] display_cb
);

logic hf_clk90;
osc_ip osc_ip_inst (
	.hf_out_en_i(1'b1),
    .hf_clk_out_o(hf_clk90)
);

logic if_clk360, display_clk27, pll_lock;
logic sync_clk96, pixel_clk, pixelx4_clk;
pll_ip pll_ip_inst (
	.clki_i(hf_clk90),
	.clkop_o(cam_clk24),
	.clkos_o(display_clk27),
	.clkos2_o(pixelx4_clk),
	.clkos3_o(sync_clk96),
	.clkos4_o(pixel_clk),
	.clkos5_o(if_clk360),
	.lock_o(pll_lock)
);

logic [8:0] counter = 0;

// reset delay delay 
always @(posedge if_clk360) begin
	if (counter[5] == 0) counter <= counter + 1;
end

logic global_reset_n;
assign global_reset_n = pll_lock && counter[5];

logic reset_n_cam;
reset_sync reset_sync_cam(
	.clk(cam_clk24),
	.async_reset_n(global_reset_n),
	.sync_reset_n(reset_n_cam)
);

logic reset_n_display;
reset_sync reset_sync_display(
	.clk(display_clk27),
	.async_reset_n(global_reset_n),
	.sync_reset_n(reset_n_display)
);

logic reset_n_pixel;
reset_sync reset_sync_pixel(
	.clk(pixel_clk),
	.async_reset_n(global_reset_n),
	.sync_reset_n(reset_n_pixel)
);

logic reset_n_sync;
reset_sync reset_sync_sync(
	.clk(sync_clk96),
	.async_reset_n(global_reset_n),
	.sync_reset_n(reset_n_sync)
);

logic byte_clk, byte_clk_hs, reset_n_byte;
reset_sync reset_sync_byte(
	.clk(byte_clk_hs),
	.async_reset_n(global_reset_n),
	.sync_reset_n(reset_n_byte)
);

logic [9:0] pd /* synthesis syn_keep=1 nomerge=""*/;
logic payload_en, sp_en, sp_en_d, lp_av_en, lp_en, lp_av_en_d /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] payload;
logic [15:0] wc;
logic [1:0] vc;
logic [5:0] dt;
logic [7:0] ecc;

/*
dphy_rx_ip dphy_rx_ip_inst(
    .sync_clk_i(sync_clk96),
    .sync_rst_i(reset_n_sync),
    .clk_byte_o(byte_clk),
    .clk_byte_hs_o(byte_clk_hs),
    .clk_byte_fr_i(byte_clk_hs),
    .reset_n_i(global_reset_n), // this one is async
    .reset_byte_fr_n_i(reset_n_byte),
    .clk_p_io(mipi_clk_p),
    .clk_n_io(mipi_clk_n),
    .d_p_io(mipi_data_p),
    .d_n_io(mipi_data_n),
    .bd_o( ), // raw data out
    .payload_en_o(payload_en),
    .payload_o(payload),
    .dt_o(dt),
    .vc_o(vc),
    .wc_o(wc),
    .ecc_o(ecc),
    .ref_dt_i(6'h2B), // RAW10 packet code
    .tx_rdy_i(1'b1),
    .pd_dphy_i(~global_reset_n),
    .sp_en_o(sp_en),
    .lp_en_o(lp_en),
    .lp_av_en_o(lp_av_en)
);
*/

logic hs_sync, hs_d_en, term_clk_en, term_d_en;
logic [1:0] lp_hs_state_clk;
logic [1:0] lp_hs_state_d;
dphy_rx_ip dphy_rx_ip_inst (
    .clk_byte_o( ),
    .clk_byte_hs_o(byte_clk_hs),
    .clk_byte_fr_i(byte_clk_hs),
    .reset_n_i(global_reset_n),
    .reset_byte_fr_n_i(reset_n_byte),
    .clk_p_io(mipi_clk_p),
    .clk_n_io(mipi_clk_n),
    .d_p_io(mipi_data_p),
    .d_n_io(mipi_data_n),
    .lp_d_rx_p_o( ),
    .lp_d_rx_n_o( ),
    .cd_clk_o( ),
    .cd_d0_o( ),
    .hs_d_en_o(hs_d_en),
    .hs_sync_o(hs_sync),
    .lp_hs_state_clk_o(lp_hs_state_clk),
    .lp_hs_state_d_o(lp_hs_state_d),
    .term_clk_en_o(term_clk_en),
    .term_d_en_o(term_d_en),
    .payload_en_o(payload_en),
    .payload_o(payload),
    .tx_rdy_i(1'b1),
    .pd_dphy_i(~global_reset_n),
    .rxdatsyncfr_state_o( ),
    .rxemptyfr0_o( ),
    .rxemptyfr1_o( ),
    .rxfullfr0_o( ),
    .rxfullfr1_o( ),
    .rxque_curstate_o( ),
    .rxque_empty_o( ),
    .rxque_full_o( ),
    .fifo_dly_err_o( ),
    .fifo_undflw_err_o( ),
    .fifo_ovflw_err_o( ),
    .dt_o(dt),
    .vc_o(vc),
    .wc_o(wc),
    .ecc_o( ),
    .ref_dt_i(6'h2B), // RAW10 packet code
    .sp_en_o(sp_en),
    .lp_en_o(lp_en),
    .lp_av_en_o(lp_av_en)
);
	
logic [7:0] debug8 = 0;	
logic [31:0] debug32 = 'h00000000;

always @(posedge byte_clk_hs or negedge reset_n_byte) begin
	if (~reset_n_byte) begin
		lp_av_en_d <= 0;
		sp_en_d <= 0;
	end
	else begin
		lp_av_en_d <= lp_av_en;
		sp_en_d <= sp_en;
	end
end

logic payload_en_1d, payload_en_2d, payload_en_3d;
logic [7:0] payload_1d;
logic [7:0] payload_2d;
logic [7:0] payload_3d;
always @(posedge byte_clk_hs or negedge reset_n_byte) begin
	if (~reset_n_byte) begin
		payload_en_1d <= 0;
		payload_en_2d <= 0;
		payload_en_3d <= 0;

		payload_1d <= 0;
		payload_2d <= 0;
		payload_3d <= 0;
	end
	else begin
		payload_en_1d <= payload_en;
		payload_en_2d <= payload_en_1d;
		payload_en_3d <= payload_en_2d;

		payload_1d <= payload;
		payload_2d <= payload_1d;
		payload_3d <= payload_2d;
	end
end

logic fv /* synthesis syn_keep=1 nomerge=""*/;
logic lv /* synthesis syn_keep=1 nomerge=""*/;
logic fifo_full;
logic fifo_empty;
byte2pixel_ip byte2pixel_ip_inst (
    .reset_byte_n_i(reset_n_byte),
    .clk_byte_i(byte_clk_hs),
    .sp_en_i(sp_en_d),
    .dt_i(dt),
    .lp_av_en_i(lp_av_en_d),
    .payload_en_i(payload_en_3d),
    .payload_i(payload_3d),
    .wc_i(wc),
    .reset_pixel_n_i(reset_n_pixel),
    .clk_pixel_i(pixel_clk),
    .fv_o(fv), // frame valid
    .lv_o(lv), // line valid
    .pd_o(pd), // pixel data
    .p_odd_o( ),
    // Debug ports
    .fifo_full_o(fifo_full),
    .fifo_empty_o(fifo_empty)
);


logic [29:0] rgb30;
logic [9:0] rgb10;
logic wr_en;
logic [15:0] wr_addr;
logic [31:0] dbg;
simple_bayer 
//#(
    //.HSIZE('d256),
    //.X_OFFSET(0),
    //.Y_OFFSET(0),
    //.X('d256),
    //.Y('d8)
//) 
bayer (
    .clk(pixelx4_clk),
	.pixel_clk(pixel_clk),
    .reset_n(reset_n_pixel),
    .pixel_data(pd),
    .lv(lv),
    .fv(fv),
    .rgb10(rgb10),
	.rgb30(rgb30),
    .address(wr_addr),
    .wr_en(wr_en),
	.dbg(dbg)
);

logic [29:0] rd_data;
logic [15:0] rd_addr;
logic rd_en;

/*
ram_inferred #(
	.ADDR(16),
	.DATA(30)
) ram_inst (
	.clk(pixelx4_clk),
	.rst_n(reset_n_pixel),
	.wr_addr(wr_addr),
	.rd_addr(rd_addr),
	.wr_data(rgb30),
	.rd_data(rd_data),
	.wr_en(wr_en & !rd_en),
	.rd_en(rd_en)
);
*/

/*
ram_inferred_500B ram_inst (
	.clk(pixelx4_clk),
	.rst_n(reset_n_pixel),
	.wr_addr(wr_addr),
	.rd_addr(rd_addr),
	.wr_data(rgb10),
	.rd_data(rd_data),
	.wr_en(wr_en & !rd_en),
	.rd_en(rd_en)
);
*/

ram_ip ram_inst (
		.clk_i(pixelx4_clk),
        .dps_i(1'b0),
        .rst_i(~reset_n_pixel),
        .wr_clk_en_i(reset_n_pixel),
        .rd_clk_en_i(reset_n_pixel),
        .wr_en_i(wr_en),
        .wr_data_i(rgb30),
        .wr_addr_i(wr_addr),
        .rd_addr_i(rd_addr),
        .rd_data_o(rd_data),
        .lramready_o( ),
        .rd_datavalid_o( )
);

spi spi_inst (
	.clk(pixelx4_clk),
	.reset(~reset_n_pixel),
    .rd_en(rd_en),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
	.debug32(dbg),
	.*
);

display display_inst (
    .clk(display_clk27),
	.reset_n(reset_n_display),
    .hsync(hsync),
    .vsync(vsync),
    .y(display_Y),
    .cr(display_cr),
    .cb(display_cb)
);

assign display_clk_o = display_clk27 & reset_n_display;

// DEBUG SECTION
logic [3:0] fv_;
always @(posedge pixel_clk) begin
	fv_ <= {fv_[2:0], fv};
	if (!reset_n_pixel) debug8 <= 0;
	else begin
		if (fv_ == 'b0011)
			debug8 <= debug8 + 1;
	end
end

logic [31:0] rx_pixel_counter;
always @(posedge pixel_clk) begin
	if (!lv) begin
		if (rx_pixel_counter > 'd0) $display("rx %d pixels", rx_pixel_counter);
		rx_pixel_counter <= 0;
	end
	else begin
		if (fv & lv) begin
			rx_pixel_counter <= rx_pixel_counter+1;
			if (rx_pixel_counter > debug32) debug32 <= rx_pixel_counter;
		end
	end
end


endmodule
