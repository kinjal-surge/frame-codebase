module vector_engine (
	input logic clk,
	input logic reset_n,
	input logic enable,
	output logic [17:0] wr_addr,
    output logic [3:0] wr_data,
    output logic wr_en,
    output logic done
);

logic [7:0] stack [0:1023]/* synthesis syn_keep=1 nomerge=""*/;
initial begin
stack[0] = 8'd16; stack[1] = 8'd0; stack[2] = 8'd255; stack[3] = 8'd255; stack[4] = 8'd255; stack[5] = 8'd16; stack[6] = 8'd1; stack[7] = 8'd255;
stack[8] = 8'd38; stack[9] = 8'd0; stack[10] = 8'd16; stack[11] = 8'd2; stack[12] = 8'd52; stack[13] = 8'd168; stack[14] = 8'd83; stack[15] = 8'd16;
stack[16] = 8'd3; stack[17] = 8'd66; stack[18] = 8'd133; stack[19] = 8'd244; stack[20] = 8'd24; stack[21] = 8'd0; stack[22] = 8'd17; stack[23] = 8'd0;
stack[24] = 8'd190; stack[25] = 8'd0; stack[26] = 8'd190; stack[27] = 8'd24; stack[28] = 8'd1; stack[29] = 8'd21; stack[30] = 8'd0; stack[31] = 8'd196;
stack[32] = 8'd0; stack[33] = 8'd223; stack[34] = 8'd0; stack[35] = 8'd186; stack[36] = 8'd0; stack[37] = 8'd226; stack[38] = 8'd0; stack[39] = 8'd160;
stack[40] = 8'd0; stack[41] = 8'd200; stack[42] = 8'd24; stack[43] = 8'd1; stack[44] = 8'd21; stack[45] = 8'd0; stack[46] = 8'd134; stack[47] = 8'd0;
stack[48] = 8'd174; stack[49] = 8'd0; stack[50] = 8'd135; stack[51] = 8'd0; stack[52] = 8'd160; stack[53] = 8'd0; stack[54] = 8'd165; stack[55] = 8'd0;
stack[56] = 8'd160; stack[57] = 8'd24; stack[58] = 8'd1; stack[59] = 8'd21; stack[60] = 8'd0; stack[61] = 8'd195; stack[62] = 8'd0; stack[63] = 8'd160;
stack[64] = 8'd0; stack[65] = 8'd219; stack[66] = 8'd0; stack[67] = 8'd177; stack[68] = 8'd0; stack[69] = 8'd235; stack[70] = 8'd0; stack[71] = 8'd210;
stack[72] = 8'd24; stack[73] = 8'd1; stack[74] = 8'd21; stack[75] = 8'd0; stack[76] = 8'd251; stack[77] = 8'd0; stack[78] = 8'd243; stack[79] = 8'd0;
stack[80] = 8'd240; stack[81] = 8'd0; stack[82] = 8'd255; stack[83] = 8'd0; stack[84] = 8'd200; stack[85] = 8'd0; stack[86] = 8'd245; stack[87] = 8'd24;
stack[88] = 8'd1; stack[89] = 8'd21; stack[90] = 8'd0; stack[91] = 8'd160; stack[92] = 8'd0; stack[93] = 8'd235; stack[94] = 8'd0; stack[95] = 8'd131;
stack[96] = 8'd0; stack[97] = 8'd215; stack[98] = 8'd0; stack[99] = 8'd115; stack[100] = 8'd0; stack[101] = 8'd185; stack[102] = 8'd24; stack[103] = 8'd1;
stack[104] = 8'd21; stack[105] = 8'd0; stack[106] = 8'd99; stack[107] = 8'd0; stack[108] = 8'd155; stack[109] = 8'd0; stack[110] = 8'd109; stack[111] = 8'd0;
stack[112] = 8'd140; stack[113] = 8'd0; stack[114] = 8'd145; stack[115] = 8'd0; stack[116] = 8'd140; stack[117] = 8'd24; stack[118] = 8'd1; stack[119] = 8'd21;
stack[120] = 8'd0; stack[121] = 8'd181; stack[122] = 8'd0; stack[123] = 8'd140; stack[124] = 8'd0; stack[125] = 8'd212; stack[126] = 8'd0; stack[127] = 8'd154;
stack[128] = 8'd0; stack[129] = 8'd235; stack[130] = 8'd0; stack[131] = 8'd180; stack[132] = 8'd24; stack[133] = 8'd1; stack[134] = 8'd21; stack[135] = 8'd1;
stack[136] = 8'd2; stack[137] = 8'd0; stack[138] = 8'd206; stack[139] = 8'd1; stack[140] = 8'd9; stack[141] = 8'd0; stack[142] = 8'd232; stack[143] = 8'd0;
stack[144] = 8'd255; stack[145] = 8'd0; stack[146] = 8'd255; stack[147] = 8'd24; stack[148] = 8'd1; stack[149] = 8'd21; stack[150] = 8'd0; stack[151] = 8'd245;
stack[152] = 8'd1; stack[153] = 8'd22; stack[154] = 8'd0; stack[155] = 8'd210; stack[156] = 8'd1; stack[157] = 8'd20; stack[158] = 8'd0; stack[159] = 8'd150;
stack[160] = 8'd0; stack[161] = 8'd250; stack[162] = 8'd24; stack[163] = 8'd1; stack[164] = 8'd21; stack[165] = 8'd0; stack[166] = 8'd90; stack[167] = 8'd0;
stack[168] = 8'd224; stack[169] = 8'd0; stack[170] = 8'd72; stack[171] = 8'd0; stack[172] = 8'd183; stack[173] = 8'd0; stack[174] = 8'd95; stack[175] = 8'd0;
stack[176] = 8'd130; stack[177] = 8'd24; stack[178] = 8'd1; stack[179] = 8'd21; stack[180] = 8'd0; stack[181] = 8'd118; stack[182] = 8'd0; stack[183] = 8'd77;
stack[184] = 8'd0; stack[185] = 8'd167; stack[186] = 8'd0; stack[187] = 8'd80; stack[188] = 8'd0; stack[189] = 8'd240; stack[190] = 8'd0; stack[191] = 8'd140;
stack[192] = 8'd17; stack[193] = 8'd1; stack[194] = 8'd14; stack[195] = 8'd0; stack[196] = 8'd80; stack[197] = 8'd24; stack[198] = 8'd2; stack[199] = 8'd21;
stack[200] = 8'd1; stack[201] = 8'd54; stack[202] = 8'd0; stack[203] = 8'd80; stack[204] = 8'd1; stack[205] = 8'd74; stack[206] = 8'd0; stack[207] = 8'd94;
stack[208] = 8'd1; stack[209] = 8'd74; stack[210] = 8'd0; stack[211] = 8'd120; stack[212] = 8'd24; stack[213] = 8'd2; stack[214] = 8'd21; stack[215] = 8'd1;
stack[216] = 8'd74; stack[217] = 8'd0; stack[218] = 8'd146; stack[219] = 8'd1; stack[220] = 8'd54; stack[221] = 8'd0; stack[222] = 8'd160; stack[223] = 8'd1;
stack[224] = 8'd14; stack[225] = 8'd0; stack[226] = 8'd160; stack[227] = 8'd24; stack[228] = 8'd2; stack[229] = 8'd19; stack[230] = 8'd1; stack[231] = 8'd14;
stack[232] = 8'd0; stack[233] = 8'd80; stack[234] = 8'd17; stack[235] = 8'd1; stack[236] = 8'd14; stack[237] = 8'd0; stack[238] = 8'd160; stack[239] = 8'd24;
stack[240] = 8'd3; stack[241] = 8'd21; stack[242] = 8'd1; stack[243] = 8'd54; stack[244] = 8'd0; stack[245] = 8'd160; stack[246] = 8'd1; stack[247] = 8'd74;
stack[248] = 8'd0; stack[249] = 8'd174; stack[250] = 8'd1; stack[251] = 8'd74; stack[252] = 8'd0; stack[253] = 8'd200; stack[254] = 8'd24; stack[255] = 8'd3;
stack[256] = 8'd21; stack[257] = 8'd1; stack[258] = 8'd74; stack[259] = 8'd0; stack[260] = 8'd226; stack[261] = 8'd1; stack[262] = 8'd54; stack[263] = 8'd0;
stack[264] = 8'd240; stack[265] = 8'd1; stack[266] = 8'd14; stack[267] = 8'd0; stack[268] = 8'd240; stack[269] = 8'd24; stack[270] = 8'd3; stack[271] = 8'd19;
stack[272] = 8'd1; stack[273] = 8'd14; stack[274] = 8'd0; stack[275] = 8'd160; stack[276] = 8'd17; stack[277] = 8'd0; stack[278] = 8'd40; stack[279] = 8'd0;
stack[280] = 8'd70; stack[281] = 8'd24; stack[282] = 8'd0; stack[283] = 8'd19; stack[284] = 8'd1; stack[285] = 8'd104; stack[286] = 8'd0; stack[287] = 8'd70;
stack[288] = 8'd24; stack[289] = 8'd0; stack[290] = 8'd19; stack[291] = 8'd1; stack[292] = 8'd104; stack[293] = 8'd1; stack[294] = 8'd44; stack[295] = 8'd24;
stack[296] = 8'd0; stack[297] = 8'd19; stack[298] = 8'd0; stack[299] = 8'd40; stack[300] = 8'd1; stack[301] = 8'd44; stack[302] = 8'd24; stack[303] = 8'd0;
stack[304] = 8'd19; stack[305] = 8'd0; stack[306] = 8'd40; stack[307] = 8'd0; stack[308] = 8'd70; stack[309] = 8'd25;
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
                        // TODO: fix colors
                        // colour_offset <= stack[offset+1];
                        // color_y <= stack[offset+2];
                        // color_cr <= stack[offset+3];
                        // color_cb <= stack[offset+4];
                        next_offset <= 'd5;
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
                        // TODO: fix colors
                        color_code = stack[offset+1] +1; // Hack to avoid black, fixme
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
                // colours[colour_offset] <= {red[7:3], green[7:2], blue[7:3]};
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