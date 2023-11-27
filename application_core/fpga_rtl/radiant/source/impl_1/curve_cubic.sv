module curve_cubic (
    input logic clk,
    input logic reset_n,
    input logic enable,
    input logic [9:0] x0,
    input logic [9:0] x1,
    input logic [9:0] x2,
    input logic [9:0] x3,
    input logic [8:0] y0,
    input logic [8:0] y1,
    input logic [8:0] y2,
    input logic [8:0] y3,
    output logic [9:0] horizontal,
    output logic [8:0] vertical,
    output logic ready
);

logic [7:0] state;
logic [23:0] x1_3, y1_3, x2_3, y2_3, u, u_inv, uxu_inv, u_inv_2, u_2, temp_x0, temp_x1, temp_x2, temp_x3, temp_y0, temp_y1, temp_y2, temp_y3, temp_x0_, temp_x1_, temp_x2_, temp_x3_, temp_y0_, temp_y1_, temp_y2_, temp_y3_;
logic [23:0] x0_fp, y0_fp, x1_fp, y1_fp, x2_fp, y2_fp, x3_fp, y3_fp;
logic [23:0] xu, yu, xu_1, yu_1, xu_2, yu_2;

logic [23:0] mult1_a, mult1_b;
logic [23:0] mult1_r;
logic mult1_o;
logic [23:0] mult2_a, mult2_b;
logic [23:0] mult2_r;
logic mult2_o;
logic [23:0] mult3_a, mult3_b;
logic [23:0] mult3_r;
logic mult3_o;
logic [23:0] mult4_a, mult4_b;
logic [23:0] mult4_r;
logic mult4_o;

fp_mult mult1 (.a(mult1_a), .b(mult1_b), .result(mult1_r), .overflow(mult1_o));
fp_mult mult2 (.a(mult2_a), .b(mult2_b), .result(mult2_r), .overflow(mult2_o));
fp_mult mult3 (.a(mult3_a), .b(mult3_b), .result(mult3_r), .overflow(mult3_o));
fp_mult mult4 (.a(mult4_a), .b(mult4_b), .result(mult4_r), .overflow(mult4_o));

// Convert coordinates to fixed point
assign x0_fp = {3'b0, x0, 10'b0};
assign x1_fp = {3'b0, x1, 10'b0};
assign x2_fp = {3'b0, x2, 10'b0};
assign x3_fp = {3'b0, x3, 10'b0};
assign y0_fp = {5'b0, y0, 10'b0};
assign y1_fp = {5'b0, y1, 10'b0};
assign y2_fp = {5'b0, y2, 10'b0};
assign y3_fp = {5'b0, y3, 10'b0};

assign horizontal = xu[19:10];
assign vertical = yu[19:10];

assign ready = (state == 'd8);

always @(posedge clk) begin
    if (!reset_n) begin
        state <= 'd8;
    end
    else begin
        if (ready && enable) begin
            state <= 'd0;
        end
        case (state)
            'd0 : begin
                u <= 1;
                u_inv <= 'b0_1111111111;

                // x1_3 <= x1 * 3;
                mult1_a <= x1_fp;
                mult1_b <= 'b11_0000000000;
                
                // x2_3 <= x2 * 3;
                mult2_a <= x2_fp;
                mult2_b <= 'b11_0000000000;
                
                // y1_3 <= y1 * 3;
                mult3_a <= y1_fp;
                mult3_b <= 'b11_0000000000;

                // y2_3 <= y2 * 3;
                mult4_a <= y2_fp;
                mult4_b <= 'b11_0000000000;

                // Go to first point
                xu <= x0_fp;
                yu <= y0_fp;

                if (enable) state <= state + 1;
                else state <= 'd8;
            end

            'd1 : begin
                // Only on the first loop
                if (u == 'h0_01) begin
                    x1_3 <= mult1_r;
                    x2_3 <= mult2_r;
                    y1_3 <= mult3_r;
                    y2_3 <= mult4_r;
                end

                // u_inv_2 <= u_inv * u_inv;
                mult1_a <= u_inv;
                mult1_b <= u_inv;

                // temp_x0 <= u_inv * x0;
                mult2_a <= u_inv;
                mult2_b <= x0_fp;

                // temp_y0 <= u_inv * y0;
                mult3_a <= u_inv;
                mult3_b <= y0_fp;

                // temp_x1 <= x1_3 * u;
                if (u == 'b1) begin
                    mult4_a <= mult1_r;
                end else mult4_a <= x1_3;
                mult4_b <= u;

                state <= state + 1;
            end

            'd2 : begin
                u_inv_2 <= mult1_r;
                temp_x0 <= mult2_r;
                temp_y0 <= mult3_r;
                temp_x1 <= mult4_r;

                // temp_y1 <= y1_3 * u;
                mult1_a <= y1_3;
                mult1_b <= u;

                // uxu_inv <= u * u_inv;
                mult2_a <= u;
                mult2_b <= u_inv;

                // temp_x2 <= x2_3 * u;
                mult3_a <= x2_3;
                mult3_b <= u;

                // temp_y2 <= y2_3 * u;
                mult4_a <= y2_3;
                mult4_b <= u;

                state <= state + 1;
            end

            'd3 : begin
                temp_y1 <= mult1_r;
                uxu_inv <= mult2_r;
                temp_x2 <= mult3_r;
                temp_y2 <= mult4_r;

                // u_2 <= u * u;
                mult1_a <= u;
                mult1_b <= u;

                // temp_x3 <= u * x3;
                mult2_a <= u;
                mult2_b <= x3_fp;

                // temp_y3 <= u * y3;
                mult3_a <= u;
                mult3_b <= y3_fp;

                state <= state + 1;
            end

            'd4 : begin
                u_2 <= mult1_r;
                temp_x3 <= mult2_r;
                temp_y3 <= mult3_r;

                // temp_x0_ <= u_inv_2 * temp_x0;
                mult1_a <= u_inv_2;
                mult1_b <= temp_x0;

                // temp_y0_ <= u_inv_2 * temp_y0;
                mult2_a <= u_inv_2;
                mult2_b <= temp_y0;

                // temp_x1_ <= temp_x1 * u_inv_2;
                mult3_a <= temp_x1;
                mult3_b <= u_inv_2;

                // temp_y1_ <= temp_y1 * u_inv_2;
                mult4_a <= temp_y1;
                mult4_b <= u_inv_2;

                state <= state + 1;
            end

            'd5 : begin
                temp_x0_ <= mult1_r;
                temp_y0_ <= mult2_r;
                temp_x1_ <= mult3_r;
                temp_y1_ <= mult4_r;

                // temp_x2_ <= temp_x2 * uxu_inv;
                mult1_a <= temp_x2;
                mult1_b <= uxu_inv;

                // temp_y2_ <= temp_y2 * uxu_inv;
                mult2_a <= temp_y2;
                mult2_b <= uxu_inv;

                // temp_x3_ <= temp_x3 * u_2;
                mult3_a <= temp_x3;
                mult3_b <= u_2;

                // temp_y3_ <= temp_y3 * u_2;
                mult4_a <= temp_y3;
                mult4_b <= u_2;

                state <= state + 1;
            end

            'd6 : begin
                temp_x2_ <= mult1_r;
                temp_y2_ <= mult2_r;
                temp_x3_ <= mult3_r;
                temp_y3_ <= mult4_r;

                xu <= temp_x0_ + temp_x1_ + mult1_r + mult3_r;
                yu <= temp_y0_ + temp_y1_ + mult2_r + mult4_r;
                state <= state + 1;
            end

            'd7 : begin
                if (u < 'b1_0000000000) begin
                    u <= u + 1;
                    u_inv <= u_inv - 1;
                    state <= 'd1;
                end
                else begin 
                    state <= state + 1;
                end
            end

            'd8 : begin
                xu <= 0;
                yu <= 0;
            end
        endcase
    end
end

endmodule