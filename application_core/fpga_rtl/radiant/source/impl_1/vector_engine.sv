module vector_engine (
	input logic clk,
	input logic reset_n,
	input logic enable,
	input logic [7:0] stack_rd_data,
	output logic stack_rd_en,
	output logic [17:0] wr_addr,
    output logic [3:0] wr_data,
    output logic wr_en,
    output logic color_tab_wr_en,
    output logic [3:0] wr_color_idx,
    output logic [9:0] wr_color_code,
    output logic done,
	input logic fifo_empty
);

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
	COMMAND_INSTRUCTION = 6'd1,
	COPY_INSTRUCTIONS = 6'd2,
    DECODE = 6'd3,
    WAIT = 6'd4,
    LOOP = 6'd5,
    SET_COLOUR = 6'd6,
    DONE = 6'd7;

logic [5:0] instruction_state;
logic [7:0] instruction_counter;
logic [7:0] instruction;
logic [9:0] currentX;
logic [8:0] currentY;
logic [7:0] num_bytes_to_copy;
logic [7:0] stack_wr_idx/* synthesis syn_keep=1 nomerge=""*/;

logic [7:0] stack [0:15]/* synthesis syn_keep=1 nomerge=""*/; 
// fix stack copy logic
always @(posedge clk) begin
	if(!reset_n) begin
		line_en <= 0;
        curve_en <= 0;
		instruction <= 0;
		instruction_state <= INIT;
        color_code <= 0;
		stack_rd_en <= 0;
		currentX <= 0;
		currentY <= 0;
	end
	
	else begin
		//if (stack_wr_en) stack[stack_addr] <= stack_data;
		if (enable) begin
			case(instruction_state)
				INIT : begin // init and clear
					line_en <= 0;
					curve_en <= 0;
					instruction_counter <= 0;
					num_bytes_to_copy <= 0;
					xy_to_addr_en <= 0;
					if (!fifo_empty) begin 
						instruction_state <= COMMAND_INSTRUCTION;
						stack_rd_en <= 1;
						done <= 0;
					end
					else begin
						stack_rd_en <= 0;
						done <= 1;
					end
				end
				COMMAND_INSTRUCTION : begin
					stack[0] <= stack_rd_data;
					instruction <= stack_rd_data;
					stack_wr_idx <= 'd1;
					case (stack_rd_data)
						SET_COLOR_PAL : begin
							num_bytes_to_copy <= 'd3;
							instruction_state <= COPY_INSTRUCTIONS;
						end
						MOVE : begin
							num_bytes_to_copy <= 'd4;
							instruction_state <= COPY_INSTRUCTIONS;
						end
						LINE : begin
							num_bytes_to_copy <= 'd4;
							instruction_state <= COPY_INSTRUCTIONS;
						end
						CUB_CURVE : begin
							num_bytes_to_copy <= 'd12;
							instruction_state <= COPY_INSTRUCTIONS;
						end
						SET_COLOR_IDX : begin
							num_bytes_to_copy <= 'd1;
							instruction_state <= COPY_INSTRUCTIONS;
						end
						SHOW : begin
							// no more to copy in this case
							num_bytes_to_copy <= 'd0;
							stack_rd_en <= 0;
							instruction_state <= DECODE;
						end
					endcase
				end	
				COPY_INSTRUCTIONS : begin
					// more to copy
					if (!fifo_empty && stack_wr_idx != num_bytes_to_copy) begin
						stack[stack_wr_idx] <= stack_rd_data;
						stack_wr_idx <= stack_wr_idx + 1;
					end
					
					// finished copying whole packet
					if (!fifo_empty && stack_wr_idx == num_bytes_to_copy) begin
						stack[stack_wr_idx] <= stack_rd_data;
						instruction_state <= DECODE;
						stack_rd_en <= 0;
					end 
					
					// else wait for data to arrive
				end
				DECODE : begin // decode and initate
					case (instruction)
						SET_COLOR_PAL : begin
							wr_color_idx <= stack[1];
							wr_color_code <= {stack[2][1:0], stack[3]};
							color_tab_wr_en <= 1;
							instruction_state <= SET_COLOUR;
						end
						MOVE : begin // move pen
							currentX <= {stack[1], stack[2]};
							currentY <= {stack[3], stack[4]};
							instruction_state <= LOOP;
						end
						LINE : begin // draw line
							line_x0 <= currentX;
							line_y0 <= currentY;
							line_x1 <= {stack[1], stack[2]};
							line_y1 <= {stack[3], stack[4]};
							line_en <= 1;
							xy_to_addr_en <= 1;
							if (line_en) instruction_state <= WAIT;
						end
						CUB_CURVE : begin // draw cubic curve
							curve_x0 <= currentX;
							curve_y0 <= currentY;
							curve_x1 <= {stack[1], stack[2]};
							curve_y1 <= {stack[3], stack[4]};
							curve_x2 <= {stack[5], stack[6]};
							curve_y2 <= {stack[7], stack[8]};
							curve_x3 <= {stack[9], stack[10]};
							curve_y3 <= {stack[11], stack[12]};
							curve_en <= 1;
							xy_to_addr_en <= 1;
							// wait one clock
							if (curve_en) instruction_state <= WAIT;
						end
						SET_COLOR_IDX : begin // set color pallete index
							color_code <= stack[1];
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
								xy_to_addr_en <= 0;
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
								xy_to_addr_en <= 0;
								currentX <= curve_x3;
								currentY <= curve_y3;
								instruction_state <= LOOP;
							end
						end
					endcase
				end
				LOOP : begin // increment counters, loop/continue
					instruction_counter <= instruction_counter + 1;
					instruction_state <= INIT;
				end
				SET_COLOUR : begin // finish setting colour offset
					color_tab_wr_en <= 0;
					instruction_state <= LOOP;
				end
				DONE : begin
					line_en <= 0;
					curve_en <= 0;
					stack_rd_en <= 0;
					xy_to_addr_en <= 0;
					done <= 1;
					instruction_state <= INIT;
				end
			endcase
		end
		else begin
			// same as reset state
			line_en <= 0;
			curve_en <= 0;
			instruction_state <= INIT;
			color_code <= 0;
		end
	end
end

endmodule