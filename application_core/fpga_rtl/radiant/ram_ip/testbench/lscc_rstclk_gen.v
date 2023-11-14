`ifndef _LSCC_RSTCLK_GEN
`define _LSCC_RSTCLK_GEN

module lscc_rstclk_gen # (
    parameter CLK_PERIOD = 100,
    parameter RST_DELAY  = 35,
    parameter RST_SYNC   = "sync",
    parameter TIMEOUT    = 1000000
)(
    output reg clk_o,
    output reg rst_o,
    output reg rst_n_o
);

localparam HALF_PERIOD = CLK_PERIOD/2;

initial begin
    clk_o <= 1'b0;
    forever #HALF_PERIOD clk_o <= ~clk_o;
end

initial begin
    rst_o   <= 1'b1;
    rst_n_o <= 1'b0;
    #RST_DELAY;
    if(RST_SYNC == "sync") @(posedge clk_o);
    rst_o   <= 1'b0;
    rst_n_o <= 1'b1;
end

initial begin
    #TIMEOUT;
    $display(" ------ Testbench Simulation TIME-OUT reached ------");
    $finish;
end

endmodule
`endif