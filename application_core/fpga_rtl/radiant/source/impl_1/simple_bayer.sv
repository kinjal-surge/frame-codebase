module simple_bayer #(
    HSIZE = 'd1288,
    ONELINE = 0 // debug output oneline (640p)
)(
    input logic clk,
    input logic pixel_clk,
    input logic reset_n,
    input logic [9:0] x_offset,
    input logic [8:0] y_offset,
    input logic [9:0] x_size,
    input logic [8:0] y_size,
    input logic [9:0] pixel_data,
    input logic lv,
    input logic fv,
    output logic [29:0] rgb30,
	output logic [9:0] rgb10,
	output logic [7:0] rgb8,
	output logic [3:0] gray4,
    output logic wr_en,
	output logic fv_o
);

// TODO: do we need 2 extra pixels to prevent weird
// overflow issues with array indexing ? 
logic [9:0] line0 [HSIZE:0];
logic [9:0] line1 [HSIZE:0];

logic [15:0] rd_pix_counter;
logic [15:0] wr_pix_counter;
logic [15:0] line_counter;

logic [9:0] r;
logic [9:0] g;
logic [9:0] b;

assign rgb30 = wr_en ? {r, g, b} : 'b0;
assign rgb10 = wr_en ? {r[9:7], g[9:6], b[9:7]} : 'b0; // rgb343
assign rgb8 = wr_en ? {r[9:7], g[9:7], b[9:8]} : 'b0; // rgb332
assign gray4 = wr_en ? g[2:0] + r[1:0] + b[1:0] : 'b0; // g/2 + r/4 + B/4

logic lv_d, pending;
logic [1:0] pixel_clk_;

always @(posedge clk) begin
    if (!reset_n | !fv) begin
        rd_pix_counter <= 0;
        wr_pix_counter <= 0;
        line_counter <= 0;
        wr_en <= 0;
        r <= 0;
        g <= 0;
        b <= 0;
		pending <= 0;
		fv_o <= 0;
    end 

    else begin
		fv_o <= 1;
        // track last lv val
        lv_d <= lv; 
		pixel_clk_ <= {pixel_clk_[0], pixel_clk};

        // on lv write to alternating row buffers
        if (lv && pixel_clk_ == 'b01) begin
            if (line_counter[0]) line1[rd_pix_counter] <= pixel_data;
            else line0[rd_pix_counter] <= pixel_data;
            rd_pix_counter <= rd_pix_counter +1;
			wr_en <= 0;
        end

        // demosaic and write to ram when not recieving pixels
        if (!lv && pending) begin
            if (wr_pix_counter < HSIZE) begin
                r <= line1[wr_pix_counter+1];
                g <= (line0[wr_pix_counter+1]>>1) + (line1[wr_pix_counter]>>1);
                b <= line0[wr_pix_counter];
                wr_pix_counter <= wr_pix_counter + 'd2;
				if (
					(wr_pix_counter >= x_offset) && (wr_pix_counter < x_size+x_offset) &&
					(line_counter >= y_offset) && (line_counter <= y_size+y_offset)
				) begin
					wr_en <= 1;
				end else begin
					wr_en <= 0;
				end
            end
            // done with all pixels, stop writing
            else begin
                wr_en <= 0;
            end
        end

        // on falling edge of lv - switch line
        if (lv_d & !lv & pixel_clk) begin
            rd_pix_counter <= 0;
			wr_pix_counter <= 0;
            line_counter <= line_counter+1;
			
            // if line1 just filled, start demosaicing
            if (line_counter[0]) begin
				pending <= 1;
			end
            else begin 
                pending <= 0;
            end
        end
    end
end

endmodule