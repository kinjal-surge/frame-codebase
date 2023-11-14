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

logic [DATA-1:0] mem [(2**ADDR)-1:0] /* synthesis syn_keep=1 nomerge=""*/;

always @(posedge clk) begin
	if (rst_n & wr_en)
		mem[wr_addr] <= wr_data;
end

always @(posedge clk) begin
	if (rst_n & rd_en)
		rd_data <= mem[rd_addr];
end

endmodule

module ram_inferred_500B (
	input logic clk,
	input logic rst_n,
	input logic [8:0] wr_addr,
	input logic [8:0] rd_addr,
	input logic [9:0] wr_data,
	output logic [9:0] rd_data,
	input logic wr_en,
	input logic rd_en
);

logic [9:0] mem [511:0] /* synthesis syn_keep=1 nomerge=""*/;

always @(posedge clk) begin
	if (rst_n & wr_en)
		mem[wr_addr] <= wr_data;
end

always @(posedge clk) begin
	if (rst_n & rd_en)
		rd_data <= mem[rd_addr];
end

endmodule