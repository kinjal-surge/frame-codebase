module rgb2yuv (
	input logic clk,
	input logic reset_n,
	input logic [29:0] rgb30,
	input logic wr_en_i,
	
	output logic [7:0] yuv332,
	output logic wr_en_o
);

logic [17:0] mult1_a;
logic [17:0] mult1_b;
logic [35:0] mult1_r;
logic [17:0] mult2_a;
logic [17:0] mult2_b;
logic [35:0] mult2_r;
logic [17:0] mult3_a;
logic [17:0] mult3_b;
logic [35:0] mult3_r;

logic [17:0] r_fp;
logic [17:0] g_fp;
logic [17:0] b_fp;

// convert to signed fixed point
assign r_fp = {[29:20], 8'b0};
assign g_fp = {[19:10], 8'b0};
assign b_fp = {[9:0], 8'b0};

// coefficients
assign r1 = 18'b000000000000100110;
assign g1 = 18'b000000000001001011;
assign b1 = 18'b000000000000001111;
assign r2 = 18'b111111111111101010;
assign g2 = 18'b111111111111010110;
assign b2 = 18'b000000000001000000;
assign r3 = 18'b000000000001000000;
assign g3 = 18'b111111111111001010;
assign b3 = 18'b111111111111110110;

fp_mult (
	.N(18),
	.Q(7)
) mult1 (
	.a(mult1_a), 
	.b(mult1_b), 
	.result(mult1_r), 
	.overflow()
);

fp_mult (
	.N(18),
	.Q(7)
) mult2 (
	.a(mult2_a), 
	.b(mult2_b), 
	.result(mult2_r), 
	.overflow()
);

fp_mult (
	.N(18),
	.Q(7)
) mult3 (
	.a(mult3_a), 
	.b(mult3_b), 
	.result(mult3_r), 
	.overflow()
);

endmodule