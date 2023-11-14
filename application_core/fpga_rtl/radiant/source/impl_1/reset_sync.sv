/* Synchronize an async active low reset into a clock domain */
// From venkat's project, TODO license

module reset_sync (
	input  wire clk        ,
	input  wire async_reset_n,
	output reg sync_reset_n
);

	logic reset_n_meta;
	always @(posedge clk or negedge async_reset_n) begin
		if (~async_reset_n) begin
			sync_reset_n <= 0;
			reset_n_meta <= 0;
		end else begin
			reset_n_meta <= async_reset_n;
			sync_reset_n <= reset_n_meta;
		end
	end

endmodule