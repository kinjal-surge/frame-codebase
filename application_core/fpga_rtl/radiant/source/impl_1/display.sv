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
	output logic clock_out,
    output logic y0,
    output logic y1,
    output logic y2,
    output logic y3,
    output logic cr0,
    output logic cr1,
    output logic cr2,
    output logic cb0,
    output logic cb1,
    output logic cb2
);

logic [15:0] hsync_counter = 0;
logic [15:0] vsync_counter = 0;

assign clock_out = clk & reset_n;

always @(posedge clk) begin
	if (!reset_n) begin
		vsync <= 0;
		hsync <= 0;
		hsync_counter <= 0;
		vsync_counter <= 0;
	end
	else begin
		y0 <= 1;
		y1 <= 1;
		y2 <= 1;
		y3 <= 1;
		cr0 <= 1;
		cr1 <= 1;
		cr2 <= 1;
		cb0 <= 1;
		cb1 <= 1;
		cb2 <= 1;

		if (hsync_counter < 857) hsync_counter <= hsync_counter + 1;

		else begin 

			hsync_counter <= 0;

			if (vsync_counter < 524) vsync_counter <= vsync_counter + 1;

			else vsync_counter <= 0;

		end

		// Output the horizontal sync signal based on column number
		if (hsync_counter < 64) hsync <= 0;

		else hsync <= 1;

		// Output the vertical sync signal based on line number
		if (vsync_counter < 6) vsync <= 0;

		else vsync <= 1;
	end
end

endmodule