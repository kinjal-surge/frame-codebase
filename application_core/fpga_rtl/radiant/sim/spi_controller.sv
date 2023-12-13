module spi_controller (
    input logic clk, 
    input logic reset_n,
    output logic copi,
    input logic cipo,
    output logic sck,
    output logic cs,
    input logic [7:0] command,
    input logic [15:0] read_byte_count,
    output logic done
);

logic [7:0] bit_counter = 0;
logic [15:0] byte_counter = 0;
logic [31:0] cipo_reg;

logic [3:0] clk_counter;

always @(posedge clk) begin
    if (!reset_n) begin
        clk_counter <= 0;
        bit_counter <= 0;
        byte_counter <= 0;
        cs <= 1;
        sck <= 0;
        copi <= 0;
        done <= 0;
    end else if (!done) begin
        if (cs) begin 
            copi <= command[7];
            cs <= 0;
        end
        if (clk_counter == 'd4) begin
            clk_counter <= 0;
            sck <= ~sck;
            if (sck) begin
                if (bit_counter == 'd7) begin
                    copi <= command[7];
                    bit_counter <= 0;
                    byte_counter <= byte_counter +1;
                    if (byte_counter == read_byte_count) done <= 1;

                end
                else begin
                    bit_counter <= bit_counter +1;
                    copi <= command[6-bit_counter]; // MSB is already setup
                end
            end
        end
        else clk_counter <= clk_counter +1;

        if (sck && clk_counter == 0) begin
            cipo_reg <= {cipo_reg[30:0], cipo};
        end
    end
end

endmodule