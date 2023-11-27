module fp_mult #(
    parameter N = 24,   // Full size
    parameter Q = 10     // Fractional size
) 
(
    input wire [N-1:0] a,
    input wire [N-1:0] b,
    output wire [N-1:0] result,
    output wire overflow
);

wire [2*N-1:0]	full_result;

assign full_result = a[N-1:0] * b[N-1:0];
assign result = full_result[N-1+Q:Q];
assign overflow = (full_result[2*N-2:N-1+Q] > 0) ? 1'b1 : 1'b0;

endmodule