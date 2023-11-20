`timescale 1 ps / 1 ps

module tb_top();
	
localparam IMG_H_SIZE = 16'd256;
localparam IMG_V_SIZE = 16'd8;
localparam WC = IMG_H_SIZE*10/8; // RAW10 to byte

reg CLK_GSR  = 0;
reg USER_GSR = 1;
GSR GSR_INST (.GSR_N(USER_GSR), .CLK(CLK_GSR));

logic hf_clk90 = 1;
logic pll_lock_dphy, pll_lock;
logic sync_clk96, pixel_clk36, pixel_clk;

pll_ip pll_ip_inst (
	.clki_i(hf_clk90),
	.clkop_o(),
	.clkos_o(pixel_clk36),
	.clkos2_o(pixelx4_clk),
	.clkos3_o(),
	.clkos4_o(sync_clk),
	// .clkos5_o(if_clk),
	.lock_o(pll_lock)
);

// use 36M to be same as the camera
assign pixel_clk = pixel_clk36;

wire reset_n;
wire reset_n_main_pll = pll_lock;

logic [3:0] reset_counter;

always @(posedge hf_clk90) begin
	if (!reset_n_main_pll) reset_counter <= 0;
	else begin
		if (!reset_counter[3]) reset_counter <= reset_counter +1;
	end
end
assign reset_n = pll_lock & pll_lock_dphy & reset_counter[3];

logic reset_n_sync;
reset_sync reset_sync_sync(
	.clk(sync_clk96),
	.async_reset_n(reset_n_main_pll),
	.sync_reset_n(reset_n_sync)
);
wire pixel_lv, pixel_fv, pixel_en;
wire [9:0] pixel_data;
/*
colorbar_gen #(.v_active(11'd5)) i_colorbar_gen (
 	.rstn (reset_n),
 	.clk  (pixel_clk),
 	.de   (pixel_en),
 	.data (pixel_data),
 	.fv   (pixel_fv),
 	.lv   (pixel_lv)
);
*/

image_gen #(
	.HPIX (IMG_H_SIZE),
	.VPIX (IMG_V_SIZE)
) i_image_gen (
	.reset_n (reset_n),
	.clk  (pixel_clk),
	.fv   (pixel_fv),
	.lv   (),
	.pix_data (pixel_data),
	.pix_en (pixel_lv) 
	// byte2pix expects pix_en to be on all the time, instead linevalid becomes enable
);

wire byte_clk;
reg reset_n_byte;
reset_sync reset_sync_byte(
	.clk(byte_clk),
	.async_reset_n(reset_n),
	.sync_reset_n(reset_n_byte)
);

reg reset_n_pixel;
reset_sync reset_sync_pixel(
	.clk(pixel_clk),
	.async_reset_n(reset_n),
	.sync_reset_n(reset_n_pixel)
);

logic reset_n_spi;
reset_sync reset_sync_spi(
	.clk(spi_clk40),
	.async_reset_n(reset_n),
	.sync_reset_n(reset_n_spi)
);

wire c2d_ready, tx_d_hs_en, byte_data_en;
wire [5:0] dt;
wire [7:0] byte_data;
reg r_sp_en;
reg r_lp_en;
reg [5:0] r_dt;
reg [15:0] r_tx_wc;
reg r_byte_data_en_1d, r_byte_data_en_2d, r_byte_data_en_3d;
reg [7:0] r_byte_data_1d, r_byte_data_2d, r_byte_data_3d;
wire [1:0] vc;
assign vc = 2'b00;
wire fv_start, fv_end, lv_start, lv_end;

always @(posedge byte_clk or negedge reset_n_byte) begin
	if (~reset_n_byte) begin
		r_sp_en <= 0;
		r_lp_en <= 0;
	end
	else begin
		r_sp_en <= fv_start | fv_end;
		r_lp_en <= lv_start;
	end
end

always @(posedge byte_clk or negedge reset_n_byte) begin
	if (~reset_n_byte) begin
		r_dt <= 0;
	end
	else if (fv_start) begin
		r_dt <= 6'h00;
	end
	else if (fv_end) begin
		r_dt <= 6'h01;
	end
	else if (lv_start)
		r_dt <= 6'h2b;
end

always @(posedge byte_clk or negedge reset_n_byte) begin
	if (~reset_n_byte) begin
		r_tx_wc <= 0;
	end
	else if (fv_start) begin
		r_tx_wc <= 0;
	end
	else if (fv_end) begin
		r_tx_wc <= 0;
	end
	else if (lv_start) begin
		r_tx_wc <= WC;
	end
end

reg txfr_en, txfr_en_1d;
always @(posedge byte_clk or negedge reset_n_byte) begin
	if (~reset_n_byte) begin
		r_byte_data_en_1d <= 0;
		r_byte_data_en_2d <= 0;
		r_byte_data_en_3d <= 0;

		r_byte_data_1d <= 0;
		r_byte_data_2d <= 0;
		r_byte_data_3d <= 0;
		txfr_en_1d     <= 0;
	end
	else begin
		r_byte_data_en_1d <= byte_data_en;
		r_byte_data_en_2d <= r_byte_data_en_1d;
		r_byte_data_en_3d <= r_byte_data_en_2d;

		r_byte_data_1d <= byte_data;
		r_byte_data_2d <= r_byte_data_1d;
		r_byte_data_3d <= r_byte_data_2d;
		txfr_en_1d     <= txfr_en;
	end
end

pix2byte pix2byte_inst (
        .rst_n_i(reset_n_pixel),
        .pix_clk_i(pixel_clk),
        .byte_clk_i(byte_clk),
        .fv_i(pixel_fv),
        .lv_i(pixel_lv),
        .dvalid_i(1'b1),
        .pix_data0_i(pixel_data),
        .c2d_ready_i(c2d_ready),
        .txfr_en_i(txfr_en_1d),
        .fv_start_o(fv_start),
        .fv_end_o(fv_end),
        .lv_start_o(lv_start),
        .lv_end_o(lv_end),
        .txfr_req_o(tx_d_hs_en),
        .byte_en_o(byte_data_en),
        .byte_data_o(byte_data),
        .data_type_o(dt)
);	

wire packet_recv_ready;

// without CIL

csi_tx csi_tx_inst (
        .ref_clk_i(sync_clk96 & reset_n_sync),
        .reset_n_i(reset_n_sync),
        .usrstdby_i(1'b0),
        .pd_dphy_i(1'b0),
        .byte_or_pkt_data_i(r_byte_data_3d),
        .byte_or_pkt_data_en_i(r_byte_data_en_3d),
        .ready_o(ready),
        .vc_i(vc),
        .dt_i(r_dt),
        .wc_i(r_tx_wc),
        .clk_hs_en_i(tx_d_hs_en),
        .d_hs_en_i(tx_d_hs_en),
        .d_hs_rdy_o(txfr_en),
        .byte_clk_o(byte_clk),
        .c2d_ready_o(c2d_ready),
        .phdr_xfr_done_o( ),
        .ld_pyld_o(packet_recv_ready),
        .clk_p_io(mipi_clk_p),
        .clk_n_io(mipi_clk_n),
        .d_p_io(mipi_data_p),
        .d_n_io(mipi_data_n),
        .sp_en_i(r_sp_en),
        .lp_en_i(r_lp_en),
        .pll_lock_o(pll_lock_dphy)
);

// WITH CIL
/*
csi_tx csi_tx_inst (
        .ref_clk_i(sync_clk96 & reset_n_sync),
        .reset_n_i(reset_n_sync),
        .usrstdby_i(1'b0),
        .pd_dphy_i(1'b0),
        .byte_or_pkt_data_i(r_byte_data_3d),
        .byte_or_pkt_data_en_i(r_byte_data_en_3d),
        .ready_o(ready),
        .vc_i(vc),
        .dt_i(r_dt),
        .wc_i(r_tx_wc),
        .pll_lock_o(pll_lock_dphy),
        .pkt_format_ready_o( ),
        .d_hs_rdy_o(txfr_en),
        .byte_clk_o(byte_clk),
        .c2d_ready_o(c2d_ready),
        .clk_p_io(mipi_clk_p),
        .clk_n_io(mipi_clk_n),
        .d_p_io(mipi_data_p),
        .d_n_io(mipi_data_n),
        .sp_en_i(r_sp_en),
        .lp_en_i(r_lp_en)
);
*/

wire cipo, copi, sck, cs, cam_clk24, spi_done;
logic spi_reset_n;
logic [7:0] spi_cmd;
logic [15:0] spi_byte_count;
spi_controller spi_controller_inst (
	.clk(pixel_clk),
	.read_byte_count(spi_byte_count),
	.command(spi_cmd),
	.reset_n(spi_reset_n),
	.done(spi_done),
	.*
);

logic display_clock, display_hsync, display_vsync;
logic [3:0] display_y;
logic [2:0] display_cr;
logic [2:0] display_cb;
top #(
	.SIM(1)
) dut (
	.*
);
	
	logic start_spi;
	// Clocks
	localparam OSC_CLK_PERIOD = 5555; // 90M
	initial begin
		forever begin
			#OSC_CLK_PERIOD hf_clk90 = ~hf_clk90;
		end
	end

	initial begin
		$display("Starting testbench");
		$display("Image size: %d x %d", IMG_H_SIZE, IMG_V_SIZE);
	end

	always @(posedge spi_clk40) begin
		if (!reset_n_spi | !start_spi) begin
			spi_byte_count <= 0;
			spi_cmd <= 0;
			spi_reset_n <= 0;
		end else begin
			spi_cmd <= 'hBB;
			spi_byte_count <= (IMG_H_SIZE/2)*4;
			if (spi_done) spi_reset_n <= 0;
			else spi_reset_n <= 1;
		end
	end

	logic fv_;
	logic [7:0] fv_counter;
	always @(posedge pixel_clk) begin
		fv_ <= dut.fv;

		if (!reset_n_pixel) begin
			fv_counter <= 0;
			start_spi <= 0;
		end
		else begin
			if (fv_ & !dut.fv) begin
				fv_counter <= fv_counter +1;
				if (fv_counter == 'd1) start_spi <= 1;
			end
		end
	end
	
endmodule