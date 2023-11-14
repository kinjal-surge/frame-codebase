/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

module display (
    input logic clk,
	input logic reset_n,
    output logic hsync,
    output logic vsync,
    output logic [3:0] y,
    output logic [2:0] cr,
    output logic [2:0] cb
);

assign y = 4'b1001;
assign cr = 3'b001;
assign cb = 3'b001;

logic [15:0] hsync_counter = 0;
logic [15:0] vsync_counter = 0;

always @(posedge clk) begin
	if (!reset_n) begin
		hsync <= 0;
		vsync <= 0;
		hsync_counter <= 0;
		vsync_counter <= 0;
	end
	else begin
		if (hsync_counter < 'd857) hsync_counter <= hsync_counter + 1;

		else begin 

			hsync_counter <= 0;

			if (vsync_counter < 'd524) vsync_counter <= vsync_counter + 1;

			else vsync_counter <= 0;

		end

		// Output the horizontal sync signal based on column number
		if (hsync_counter < 'd64) hsync <= 0;

		else hsync <= 1;

		// Output the vertical sync signal based on line number
		if (vsync_counter < 'd6) vsync <= 0;

		else vsync <= 1;
	end
end

endmodule