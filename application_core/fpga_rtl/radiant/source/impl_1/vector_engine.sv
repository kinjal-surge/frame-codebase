module vector_engine (
	input logic clk,
	input logic reset_n,
	input logic enable,
	output logic [17:0] wr_addr,
    output logic [3:0] wr_data,
    output logic wr_en,
    output logic color_tab_wr_en,
    output logic [3:0] wr_color_idx,
    output logic [9:0] wr_color_code,
    output logic done
);

logic [7:0] stack [0:1023]/* synthesis syn_keep=1 nomerge=""*/;
initial begin
stack[0] = 8'd16; stack[1] = 8'd1; stack[2] = 8'd0; stack[3] = 8'd80; stack[4] = 8'd16; stack[5] = 8'd2; stack[6] = 8'd0; stack[7] = 8'd120;
stack[8] = 8'd17; stack[9] = 8'd0; stack[10] = 8'd200; stack[11] = 8'd1; stack[12] = 8'd24; stack[13] = 8'd24; stack[14] = 8'd0; stack[15] = 8'd19;
stack[16] = 8'd1; stack[17] = 8'd24; stack[18] = 8'd0; stack[19] = 8'd200; stack[20] = 8'd17; stack[21] = 8'd0; stack[22] = 8'd200; stack[23] = 8'd0;
stack[24] = 8'd120; stack[25] = 8'd24; stack[26] = 8'd1; stack[27] = 8'd19; stack[28] = 8'd1; stack[29] = 8'd24; stack[30] = 8'd0; stack[31] = 8'd200;
stack[32] = 8'd25;
end

logic [3:0] color_code;
logic [9:0] x_pos;
logic [9:0] y_pos;
logic xy_to_addr_en;
xy_to_addr xy_to_addr_inst (
	.clk(clk),
	.rst_n(reset_n),
	.x_pos(x_pos),
	.y_pos(y_pos),
	.color_i(color_code),
	.en(xy_to_addr_en),
	.wr_en(wr_en),
	.wr_data(wr_data),
	.wr_addr(wr_addr)
);

logic line_en, line_rdy;
logic [9:0] line_x0;
logic [9:0] line_x1;
logic [8:0] line_y0;
logic [8:0] line_y1;
logic [9:0] line_x_pos;
logic [8:0] line_y_pos;
line line_inst (
    .clk(clk),
    .enable(line_en),
    .reset_n(reset_n),
    .x0(line_x0),
    .x1(line_x1),
    .y0(line_y0),
    .y1(line_y1),
    .horizontal(line_x_pos),
    .vertical(line_y_pos),
    .ready(line_rdy)
);

logic curve_en, curve_rdy;
logic [9:0] curve_x0;
logic [9:0] curve_x1;
logic [9:0] curve_x2;
logic [9:0] curve_x3;
logic [8:0] curve_y0;
logic [8:0] curve_y1;
logic [8:0] curve_y2;
logic [8:0] curve_y3;
logic [9:0] curve_x_pos;
logic [8:0] curve_y_pos;
curve_cubic curve_inst (
    .clk(clk),
    .enable(curve_en),
    .reset_n(reset_n),
    .x0(curve_x0),
    .x1(curve_x1),
    .x2(curve_x2),
    .x3(curve_x3),
    .y0(curve_y0),
    .y1(curve_y1),
    .y2(curve_y2),
    .y3(curve_y3),
    .horizontal(curve_x_pos),
    .vertical(curve_y_pos),
    .ready(curve_rdy)
);

// instructions
localparam SET_COLOR_PAL = 8'h10,
    MOVE = 8'h11,
    LINE = 8'h13,
    QUAD_CURVE = 8'h14,
    CUB_CURVE = 8'h15,
    SET_COLOR_IDX = 8'h18,
    SHOW = 8'h19;

// state
localparam 
    INIT = 6'd0,
    DECODE = 6'd1,
    WAIT = 6'd2,
    LOOP = 6'd3,
    SET_COLOUR = 6'd4,
    DONE = 6'd5;

logic [5:0] instruction_state;
logic [7:0] instruction_counter;
logic [7:0] instruction;
logic [9:0] currentX;
logic [8:0] currentY;
logic [9:0] offset;
logic [7:0] next_offset;

always @(posedge clk) begin
	if(!reset_n | !enable) begin
		line_en <= 0;
        curve_en <= 0;
		instruction_state <= INIT;
        color_code <= 0;
	end
	
	else if (reset_n & enable) begin
		case(instruction_state)
            INIT: begin // init and clear
                line_en <= 0;
                curve_en <= 0;
                instruction_counter <= 0;
                instruction_state <= DECODE;
                offset <= 0;
                instruction <= stack[0];
                xy_to_addr_en <= 1;
                done <= 0;
            end
            DECODE : begin // decode and initate
                case (instruction)
                    SET_COLOR_PAL : begin
                        wr_color_idx <= stack[offset+1];
                        wr_color_code <= {stack[offset+2][1:0], stack[offset+3]};
                        color_tab_wr_en <= 1;
                        next_offset <= 'd4;
                        instruction_state <= SET_COLOUR;
                    end
                    MOVE : begin // move pen
                        currentX <= {stack[offset+1], stack[offset+2]};
                        currentY <= {stack[offset+3], stack[offset+4]};
                        next_offset <= 'd5;
                        instruction_state <= LOOP;
                    end
                    LINE : begin // draw line
                        line_x0 <= currentX;
                        line_y0 <= currentY;
                        line_x1 <= {stack[offset+1], stack[offset+2]};
                        line_y1 <= {stack[offset+3], stack[offset+4]};
                        next_offset <= 'd5;
                        line_en <= 1;
                        if (line_en) instruction_state <= WAIT;
                    end
                    CUB_CURVE : begin // draw cubic curve
                        curve_x0 <= currentX;
                        curve_y0 <= currentY;
                        curve_x1 <= {stack[offset+1], stack[offset+2]};
                        curve_y1 <= {stack[offset+3], stack[offset+4]};
                        curve_x2 <= {stack[offset+5], stack[offset+6]};
                        curve_y2 <= {stack[offset+7], stack[offset+8]};
                        curve_x3 <= {stack[offset+9], stack[offset+10]};
                        curve_y3 <= {stack[offset+11], stack[offset+12]};
                        next_offset <= 'd13;
                        curve_en <= 1;
                        if (curve_en) instruction_state <= WAIT;
                    end
                    SET_COLOR_IDX : begin // set color pallete index
                        color_code <= stack[offset+1];
                        next_offset <= 'd2;
                        instruction_state <= LOOP;
                    end
                    SHOW : begin
                        instruction_state <= DONE;
                    end
                endcase
            end
            WAIT : begin // wait for drawing to complete
                case (instruction)
                    LINE: begin
                        x_pos <= line_x_pos;
                        y_pos <= line_y_pos;
                        if (line_rdy) begin
                            line_en <= 0;
                            currentX <= line_x1;
                            currentY <= line_y1;
                            instruction_state <= LOOP;
                        end
                    end
                    CUB_CURVE: begin
                        x_pos <= curve_x_pos;
                        y_pos <= curve_y_pos;
                        if (curve_rdy) begin
                            curve_en <= 0;
                            currentX <= curve_x3;
                            currentY <= curve_y3;
                            instruction_state <= LOOP;
                        end
                    end
                endcase
            end
            LOOP : begin // increment counters, loop/continue
                instruction_counter <= instruction_counter + 1;
                offset <= offset + next_offset;
                instruction <= stack[offset + next_offset];
                instruction_state <= DECODE;
            end
            SET_COLOUR : begin // finish setting colour offset
                color_tab_wr_en <= 0;
                instruction_state <= LOOP;
            end
            DONE : begin
                xy_to_addr_en <= 0;
                done <= 1;
            end
        endcase
    end
end

endmodule