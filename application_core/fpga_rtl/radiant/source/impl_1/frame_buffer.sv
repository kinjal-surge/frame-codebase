module frame_buffer #(SIM=0) (
	input logic clk,
	input logic rst_n,
	input logic [17:0] rd_addr,
	input logic [17:0] wr_addr,
	input logic [3:0] wr_data,
	output logic [3:0] rd_data,
	input logic wr_en,
	output logic ready
);

logic [3:0] fb0_rd_data;
logic [3:0] fb1_rd_data;
logic [16:0] fb0_rd_addr;
logic [16:0] fb1_rd_addr;
logic [3:0] fb0_wr_data;
logic [3:0] fb1_wr_data;
logic [16:0] fb0_wr_addr;
logic [16:0] fb1_wr_addr;
logic fb0_wr_en, fb1_wr_en;
logic fb0_rdy, fb1_rdy;
logic fb0_valid, fb1_valid;

assign ready = fb0_rdy & fb1_rdy;

always @(*) begin
	if (rd_addr < 'd128000) begin
		rd_data <= fb0_rd_data;
		fb0_rd_addr <= rd_addr[16:0];
		fb1_rd_addr <= 0;
	end
	else begin
		rd_data <= fb1_rd_data;
		fb0_rd_addr <= 0;
		fb1_rd_addr <= rd_addr-'d128000;
	end
	
end

always @(posedge clk) begin
	if (wr_addr < 'd128000) begin
		fb0_wr_addr <= wr_addr[16:0];
		fb0_wr_data <= wr_data;
		fb0_wr_en <= wr_en;
		fb1_wr_addr <= 0;
		fb1_wr_data <= 0;
		fb1_wr_en <= 0;
	end
	else begin
		fb0_wr_addr <= 0;
		fb0_wr_data <= 0;
		fb0_wr_en <= 0;
		fb1_wr_addr <= wr_addr-'d128000;
		fb1_wr_data <= wr_data;
		fb1_wr_en <= wr_en;
	end
end

generate 
	if(SIM) begin
		ram_inferred # (
				.ADDR(18),
				.DATA(4)
		) fb0 (
				.clk(clk),
				.rst_n(rst_n),
				.wr_en(fb0_wr_en),
				.wr_data(fb0_wr_data),
				.rd_addr(fb0_rd_addr),
				.wr_addr(fb0_wr_addr),
				.rd_data(fb0_rd_data)
		);
		assign fb0_rdy = 1;
		
		ram_inferred # (
				.ADDR(18),
				.DATA(4)
		) fb1 (
				.clk(clk),
				.rst_n(rst_n),
				.wr_en(fb1_wr_en),
				.wr_data(fb1_wr_data),
				.rd_addr(fb1_rd_addr),
				.wr_addr(fb1_wr_addr),
				.rd_data(fb1_rd_data)
		);
		assign fb1_rdy = 1;
	end
	else begin
		frame_buffer_ram fb0(
				.clk_i(clk),
				.dps_i(1'b0),
				.rst_i(~rst_n),
				.wr_clk_en_i(rst_n),
				.rd_clk_en_i(rst_n),
				.wr_en_i(fb0_wr_en),
				.wr_data_i(fb0_wr_data),
				.rd_addr_i(fb0_rd_addr),
				.wr_addr_i(fb0_wr_addr),
				.rd_data_o(fb0_rd_data),
				.lramready_o(fb0_rdy),
				.rd_datavalid_o(fb0_valid)
				//.ben_i(4'b1111)
		);

		frame_buffer_ram fb1(
				.clk_i(clk),
				.dps_i(1'b0),
				.rst_i(~rst_n),
				.wr_clk_en_i(rst_n),
				.rd_clk_en_i(rst_n),
				.wr_en_i(fb1_wr_en),
				.wr_data_i(fb1_wr_data),
				.rd_addr_i(fb1_rd_addr),
				.wr_addr_i(fb1_wr_addr),
				.rd_data_o(fb1_rd_data),
				.lramready_o(fb1_rdy),
				.rd_datavalid_o(fb1_valid)
				//.ben_i(4'b1111)
		);
	end
endgenerate

endmodule

