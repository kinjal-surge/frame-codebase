module frame_buffer #(
    ADDR = 12,
    DATA = 10
) (
	input logic wr_clk,
	input logic rd_clk,
	input logic rst_n,
	input logic [ADDR-1:0] rd_addr,
	input logic [DATA-1:0] wr_data,
	output logic [DATA-1:0] rd_data,
    input logic lv,
    input logic fv,
    input logic rd_en
);

logic [ADDR-1:0] wr_addr;
logic [DATA-1:0] wr_data_d;
logic wr_en;

// ram_inferred #(
//     .ADDR(ADDR),
//     .DATA(DATA)
// ) ram_inferred_inst (
//     .wr_clk(wr_clk),
//     .rd_clk(rd_clk),
//     .rst_n(rst_n),
//     .wr_en(wr_en),
//     .rd_en(rd_en),
//     .wr_data(wr_data),
//     .wr_addr(wr_addr),
//     .rd_addr(rd_addr),
//     .rd_data(rd_data)
// );

ram_ip ram_ip_inst (
		.clk_i(wr_clk),
        .dps_i(1'b0),
        .rst_i(~rst_n),
        .wr_clk_en_i(wr_en),
        .rd_clk_en_i(rd_en),
        .wr_en_i(wr_en),
        .wr_data_i(wr_data_d),
        .wr_addr_i(wr_addr),
        .rd_addr_i(rd_addr),
        .rd_data_o(rd_data),
        .lramready_o( ),
        .rd_datavalid_o( ));

logic line, lv_d;
always @(posedge wr_clk) begin
    if (!rst_n | !fv | rd_en) begin
        wr_addr <= 0;
		wr_en <= 0;
		line <= 0;
    end 
    else begin
		lv_d <= lv;
		wr_data_d <= wr_data;
		if (lv) begin
			wr_en <= 1;
			if (lv_d) wr_addr <= wr_addr +1; // only start increment after the first pixel
		end
		
		else begin
			wr_en <= 0;
			if (lv_d) begin
				wr_addr <= line ? 'd1280 : 0;
			end
		end
    end
end

endmodule

