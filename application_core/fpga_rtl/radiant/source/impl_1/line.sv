module line (
    input logic clk,
    input logic enable,
    input logic reset_n,
    input logic [9:0] x0,
    input logic [9:0] x1,
    input logic [8:0] y0,
    input logic [8:0] y1,
    output logic [9:0] horizontal,
    output logic [8:0] vertical,
    output logic ready
);

integer dx;
integer dy;
logic [9:0] x;
logic [8:0] y;
logic xPositive;
logic yPositive;
integer error;
integer error2; 
logic delay;

always @(posedge clk) begin
    if (!reset_n) begin 
        horizontal <= 0;
        vertical <= 0;
        ready <= 1;
    end
    else begin
        if (!enable) begin
            horizontal <= 0;
            vertical <= 0;
            ready <= 1;
        end
        if (enable && ready) begin // start condition
            x <= x0;
            y <= y0;

            if ((x1>x0) && (y1>y0)) begin
                dx <= x1 - x0;
                xPositive <= 1;
                dy <= -(y1 - y0);
                yPositive <= 1;
                error <= x1 - x0 - y1 + y0;
                error2 <= (x1 - x0 - y1 + y0) << 1;
            end
            else if ((x1>x0) && !(y1>y0)) begin
                dx <= x1 - x0;
                xPositive <= 1;
                dy <= -(y0 - y1);
                yPositive <= 0;
                error <= x1 - x0 - y0 + y1;
                error2 <= (x1 - x0 - y0 + y1) << 1;
            end
            else if (!(x1>x0) && (y1>y0)) begin
                dx <= x0 - x1;
                xPositive <= 0;
                dy <= -(y1 - y0);
                yPositive <= 1;
                error <= x0 - x1 - y1 + y0;
                error2 <= (x0 - x1 - y1 + y0) << 1;
            end
            else if (!(x1>x0) && !(y1>y0)) begin
                dx <= x0 - x1;
                xPositive <= 0;
                dy <= -(y0 - y1);
                yPositive <= 0;
                error <= x0 - x1 - y0 + y1;
                error2 <= (x0 - x1 - y0 + y1) << 1;
            end
            ready <= 0;
        end
        if (enable && !ready) begin
            horizontal <= x;
            vertical <= y;
            if ((x == x1) && (y == y1)) ready <= 1;
            else begin 
                if (error2 >= dy) begin
                    if (xPositive)  x <= x + 1;
                    else            x <= x - 1;
                    if (error2 <= dx) begin
                        if (yPositive)  y <= y + 1;
                        else            y <= y - 1;
                        error <= error + dy + dx;
                        error2 <= (error + dy + dx) << 1;
                    end
                    else begin
                        error <= error + dy;
                        error2 <= (error + dy) << 1;
                    end
                end else begin
                    if (error2 <= dx) begin
                        error <= error + dx;
                        error2 <= (error + dx) << 1;
                        if (yPositive)  y <= y + 1;
                        else            y <= y - 1;
                    end
                end
            end
        end
    end
end

endmodule