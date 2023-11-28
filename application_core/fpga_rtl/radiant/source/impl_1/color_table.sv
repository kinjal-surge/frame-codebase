module color_table (
    input logic clk,
    input logic reset_n,
    input logic [3:0] wr_color_idx,
    input logic [9:0] wr_color_code,
    input logic wr_en,
    input logic [3:0] rd_color_idx,
    output logic [9:0] rd_color_code
);

logic [9:0] color_table [15:0]/* synthesis syn_keep=1 nomerge=""*/;

assign rd_color_code = color_table[rd_color_idx];

always @(posedge clk) begin
    if (!reset_n) begin
        color_table[0] <= 'b0001100100; // black
        color_table[1] <= 'b0100010111; // blue
    end
    else begin
        if (wr_en) color_table[wr_color_idx] <= wr_color_code;
    end
end

// 'd0:begin
//     // black
//     y <= 'b0001;
//     cr <= 'b100;
//     cb <= 'b100;
// end
// 'd1:begin
//     // blue
//     y <= 'b0100;
//     cr <= 'b010;
//     cb <= 'b111;
// end
// 'd2:begin	
//     // red
//     y <= 'b0010;
//     cr <= 'b110;
//     cb <= 'b000;
// end
// 'd3:begin
//     // green
//     y <= 'b0;
//     cr <= 'b0;
//     cb <= 'b0;
// end
// 'd4:begin
//     // white
//     y <= 'b1001;
//     cr <= 'b100;
//     cb <= 'b100;
// end
// default:begin
//     // black
//     y <= 'b0001;
//     cr <= 'b100;
//     cb <= 'b100;
// end

endmodule