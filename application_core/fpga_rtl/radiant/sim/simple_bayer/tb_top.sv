`timescale 1 ps / 1 ps

module tb_top();
	
localparam IMG_H_SIZE = 16'd1280;
localparam IMG_V_SIZE = 16'd4;
localparam WC = IMG_H_SIZE*10/8; // RAW10 to byte

reg CLK_GSR  = 0;
reg USER_GSR = 1;
GSR GSR_INST (.GSR_N(USER_GSR), .CLK(CLK_GSR));

logic hf_clk90 = 1;
logic pll_lock_dphy, pll_lock;
logic sync_clk96, pixel_clk36, pixel_clk72, pixel_clk, spi_clk40;
pll_ip pll_ip_inst (
	.clki_i(hf_clk90),
	.clkos_o(spi_clk40),
	.clkos2_o(pixel_clk72),
	.clkos3_o(sync_clk96),
	.clkos4_o(pixel_clk36), 
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
assign reset_n = pll_lock & reset_counter[3];

logic reset_n_sync;
reset_sync reset_sync_sync(
	.clk(sync_clk96),
	.async_reset_n(reset_n_main_pll),
	.sync_reset_n(reset_n_sync)
);
wire pixel_lv, pixel_fv, pixel_en;
wire [9:0] pixel_data;

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

logic [29:0] rgb10;
logic wr_en;
logic [17:0] wr_addr;
simple_bayer bayer (
    .clk(pixel_clk),
    .reset_n(reset_n_pixel),
    .pixel_data(pixel_data),
    .lv(pixel_lv),
    .fv(pixel_fv),
    .rgb10(rgb10),
    .address(wr_addr),
    .wr_en(wr_en)
);

logic [29:0] rd_data;
logic [11:0] rd_addr;
logic rd_en;
ram_inferred #(
	.ADDR(12),
	.DATA(30)
) ram_inst (
	.clk(pixel_clk),
	.rst_n(reset_n_pixel),
	.wr_addr(wr_addr),
	.rd_addr(rd_addr),
	.wr_data(rgb10),
	.rd_data(rd_data),
	.wr_en(wr_en & !rd_en),
	.rd_en(rd_en)
);

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

logic [7:0] debug8;
spi spi_inst (
	.clk(pixel_clk),
	.reset(~reset_n_spi),
    .rd_en(rd_en),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
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
		fv_ <= pixel_fv;

		if (!reset_n_pixel) begin
			fv_counter <= 0;
			start_spi <= 0;
		end
		else begin
			if (fv_ & !pixel_fv) begin
				fv_counter <= fv_counter +1;
				if (fv_counter == 'd1) start_spi <= 1;
			end
		end
	end
	
endmodule