module ram_inferred #(
	ADDR = 12,
	DATA = 10
) (
	input logic clk,
	input logic rst_n,
	input logic [ADDR-1:0] wr_addr,
	input logic [ADDR-1:0] rd_addr,
	input logic [DATA-1:0] wr_data,
	output logic [DATA-1:0] rd_data,
	input logic wr_en,
	input logic rd_en
);

(* ram_style="huge" *) logic [DATA-1:0] mem [(2**ADDR)-1:0];

always @(posedge clk) begin
	if (rst_n & wr_en)
		mem[wr_addr] <= wr_data;
end

always @(posedge clk) begin
	if (rst_n & rd_en)
		rd_data <= mem[rd_addr];
end

endmodule

module ram_inferred_65536B (
	input logic clk,
	input logic rst_n,
	input logic [13:0] wr_addr,
	input logic [13:0] rd_addr,
	input logic [31:0] wr_data,
	output logic [31:0] rd_data,
	input logic wr_en
);

(* ram_style="huge" *) reg [31:0] mem [0:16384];

always @(posedge clk) begin
	if (rst_n & wr_en)
		mem[wr_addr] <= wr_data;
end

always @(posedge clk) begin
	if (rst_n & !wr_en)
		rd_data <= mem[rd_addr];
end

endmodule