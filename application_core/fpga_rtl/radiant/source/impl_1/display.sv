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
    output logic [3:0] y,
    output logic [2:0] cr,
    output logic [2:0] cb,
	output logic [17:0] rd_addr,
	input [3:0] color
);

logic [15:0] hsync_counter;
logic [15:0] vsync_counter;

assign clock_out = clk & reset_n;

always @(posedge clk) begin
	if (!reset_n) begin
		vsync <= 0;
		hsync <= 0;
		hsync_counter <= 0;
		vsync_counter <= 0;
		rd_addr <= 0;
	end
	else begin
		if (hsync_counter < 857) hsync_counter <= hsync_counter + 1;

		else begin 

			hsync_counter <= 0;

			if (vsync_counter < 524) vsync_counter <= vsync_counter + 1;

			else begin
				vsync_counter <= 0;
				rd_addr <= 0;
			end

		end

		// Output the horizontal sync signal based on column number
		if (hsync_counter < 64) hsync <= 0;

		else hsync <= 1;

		// Output the vertical sync signal based on line number
		if (vsync_counter < 6) vsync <= 0;

		else vsync <= 1;

		// if ((hsync_counter >= 122) && (hsync_counter < 762) && (vsync_counter >= 38) && (vsync_counter <= 438)) begin
		if ((hsync_counter >= 122) && (hsync_counter < 762) && (vsync_counter >= 38) && (vsync_counter < 438)) begin
			rd_addr <= rd_addr + 1;
			case(color)
			'd0:begin
				// blue
				 y <= 'b0100;
				 cr <= 'b010;
				 cb <= 'b111;
			end
			'd1:begin	
				// red
				y <= 'b0010;
				cr <= 'b110;
				cb <= 'b000;
			end
			'd2:begin
				// pink
				y <= 'b1111;
				cr <= 'b111;
				cb <= 'b111;
			end
			default:begin
				// ??
				y <= 'b0;
				cr <= 'b0;
				cb <= 'b0;
			end
			endcase
		end
	end
end

endmodule