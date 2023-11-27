module xy_to_addr (
	input logic clk,
	input logic rst_n,
	input logic [9:0] x_pos,
	input logic [8:0] y_pos,
	input logic en,
	input logic [3:0] color_i,
	output logic wr_en,
	output logic [3:0] wr_data,
	output logic [17:0] wr_addr
);

always @(posedge clk) begin
	if (!rst_n) begin
		wr_en <= 0;
		wr_addr <= 0;
	end
	else begin
		if (en) begin
			wr_addr <= (y_pos * 'd640) + x_pos;
			wr_en <= 1;
			wr_data <= color_i;
		end
		else wr_en <= 0;
	end
end

endmodule