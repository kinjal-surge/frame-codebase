// =========================================================================
// Filename: vid_timing_gen_driver.v
// Copyright(c) 2017 Lattice Semiconductor Corporation. All rights reserved.
// =========================================================================
`ifndef VID_TIMING_GEN_DRIVER
`define VID_TIMING_GEN_DRIVER

`include "dut_defines.v" 
`include "tb_include/tb_params.vh"  

module vid_timing_gen_driver (
                        clk,
                        reset,

                        vid_cntl_tgen_active,                  // active high - indicate vid is st_active
                        byte_log_en,

                        `ifdef TX_DSI
                        tgen_vid_hsync,
                        tgen_vid_vsync,
                        tgen_vid_de,
                        `endif
                        `ifdef TX_CSI2
                        tgen_vid_fv,
                        tgen_vid_lv,
                        `endif
						`ifdef AXI_ENABLED
						tgen_vid_axi_data,
						axim_tready_i,
						axis_tvalid_o,
						`elsif AXI4M_ONLY_ENABLED
						axim_tready_i,
						tgen_vid_data0,
                        tgen_vid_data1,
                        tgen_vid_data2,
                        tgen_vid_data3,
                        tgen_vid_data4,
                        tgen_vid_data5,
                        tgen_vid_data6,
                        tgen_vid_data7,
                        tgen_vid_data8,
                        tgen_vid_data9,
						`elsif AXI4S_ONLY_ENABLED
						tgen_vid_axi_data,
						axis_tvalid_o,
						`else
                        tgen_vid_data0,
                        tgen_vid_data1,
                        tgen_vid_data2,
                        tgen_vid_data3,
                        tgen_vid_data4,
                        tgen_vid_data5,
                        tgen_vid_data6,
                        tgen_vid_data7,
                        tgen_vid_data8,
                        tgen_vid_data9,
						`endif
                        tgen_end_of_line,
                        tgen_end_of_frame
                  );
// **************************************************************
parameter WORD_WIDTH                   =  24;
parameter NUM_LANE                     =  1;
//parameter DSI_FORMAT    = `csi_dsi; //pavan
parameter DSI_FORMAT = 1;
input           clk,
                reset;

input           vid_cntl_tgen_active;
input           byte_log_en;

`ifdef AXI_ENABLED
	output [WORD_WIDTH*NUM_LANE-1:0] tgen_vid_axi_data;
	input axim_tready_i;
	output axis_tvalid_o;
`elsif AXI4M_ONLY_ENABLED
	input axim_tready_i;
	output [WORD_WIDTH-1:0]   tgen_vid_data0,
                         tgen_vid_data1,
                         tgen_vid_data2,
                         tgen_vid_data3,
                         tgen_vid_data4,
                         tgen_vid_data5,
                         tgen_vid_data6,
                         tgen_vid_data7,
                         tgen_vid_data8,
                         tgen_vid_data9;	
`elsif AXI4S_ONLY_ENABLED
	output [WORD_WIDTH*NUM_LANE-1:0] tgen_vid_axi_data;
	output axis_tvalid_o;
`else
	output [WORD_WIDTH-1:0]   tgen_vid_data0,
                         tgen_vid_data1,
                         tgen_vid_data2,
                         tgen_vid_data3,
                         tgen_vid_data4,
                         tgen_vid_data5,
                         tgen_vid_data6,
                         tgen_vid_data7,
                         tgen_vid_data8,
                         tgen_vid_data9;	
`endif


`ifdef TX_DSI
output          tgen_vid_hsync,
                tgen_vid_vsync,
                tgen_vid_de;
`endif
`ifdef TX_CSI2
output          tgen_vid_fv,
                tgen_vid_lv;
`endif
output          tgen_end_of_line,
                tgen_end_of_frame;
// *************************************************************
reg [WORD_WIDTH-1:0]      tgen_vid_data0,
                         tgen_vid_data1,
                         tgen_vid_data2,
                         tgen_vid_data3,
                         tgen_vid_data4,
                         tgen_vid_data5,
                         tgen_vid_data6,
                         tgen_vid_data7,
                         tgen_vid_data8,
                         tgen_vid_data9;

reg [WORD_WIDTH*NUM_LANE-1:0] tgen_vid_axi_data;
wire axis_tvalid_o;

reg one=1'b1;
reg zero=1'b0;

wire            tgen_vid_hsync,
                tgen_vid_vsync,
                tgen_vid_de,
                tgen_vid_lv;
reg             tgen_vid_fv;
reg             fv_cnt;

wire            end_of_line,
                end_of_frame;

wire            vid_cntl_tgen_start_of_frame = 'b0;            
reg[11:0]       next_h_value,
                h_counter;
wire [11:0]     h_reload_count,
                hsync_high_to_low_count,
                hde_start,
                hde_end,
                hsync_low_to_high_count;
                
reg[10:0]       next_v_value,
                v_counter;
wire[10:0]      v_reload_count,
                vsync_high_to_low_count,
                vde_start,
                vde_end,
                vsync_low_to_high_count;

wire            h_match,
                v_match;

reg[2:0]        h_state,
                v_state;

// ******************************************************************
//  Drive data variables
// *******************************************************************
   reg [7:0] byte0;
   reg [7:0] byte1;
   reg [7:0] byte2;
   reg [7:0] byte3;
   reg [7:0] byte4;
   reg [7:0] byte5;
   reg [7:0] byte6;
   reg [7:0] byte7;
   reg [7:0] byte8;
   reg [7:0] byte9;
   reg [7:0] byte10;
   reg [7:0] byte11;
   reg [7:0] byte12;
   reg [7:0] byte13;
   reg [7:0] byte14;
   reg [7:0] byte15;
   reg [7:0] byte16;
   reg [7:0] byte17;
   reg [7:0] byte18;
   reg [7:0] byte19;
   reg [7:0] byte20;
   reg [7:0] byte21;
   reg [7:0] byte22;
   reg [7:0] byte23;
   reg [7:0] byte24;
            
   reg [WORD_WIDTH-1:0] pix_data_19_buf;
   reg [WORD_WIDTH-1:0] pix_data_18_buf;
   reg [WORD_WIDTH-1:0] pix_data_17_buf;
   reg [WORD_WIDTH-1:0] pix_data_16_buf;
   reg [WORD_WIDTH-1:0] pix_data_15_buf;
   reg [WORD_WIDTH-1:0] pix_data_14_buf;
   reg [WORD_WIDTH-1:0] pix_data_13_buf;
   reg [WORD_WIDTH-1:0] pix_data_12_buf;
   reg [WORD_WIDTH-1:0] pix_data_11_buf;
   reg [WORD_WIDTH-1:0] pix_data_10_buf;

   reg [WORD_WIDTH-1:0] pix_data_9_buf;
   reg [WORD_WIDTH-1:0] pix_data_8_buf;
   reg [WORD_WIDTH-1:0] pix_data_7_buf;
   reg [WORD_WIDTH-1:0] pix_data_6_buf;
   reg [WORD_WIDTH-1:0] pix_data_5_buf;
   reg [WORD_WIDTH-1:0] pix_data_4_buf;
   reg [WORD_WIDTH-1:0] pix_data_3_buf;
   reg [WORD_WIDTH-1:0] pix_data_2_buf;
   reg [WORD_WIDTH-1:0] pix_data_1_buf;
   reg [WORD_WIDTH-1:0] pix_data_0_buf;

// ***************************************************************

parameter test_hsync_front_porch       =  7'd2;
parameter test_hsync_width             =  12'd10;
parameter test_hsync_back_porch        =  12'd04;
parameter test_h_width                 =  12'd64;
//parameter test_h_total                 =  12'd80;
parameter test_h_total                 =  test_hsync_front_porch + test_hsync_width + test_hsync_back_porch + test_h_width;

parameter test_v_height                =  11'd48;
parameter test_vsync_front_porch       =  11'd2;
parameter test_vsync_width             =  3'd2;
parameter test_vsync_back_porch        =  11'd3;
//parameter test_v_total                 =  11'd55;
parameter test_v_total                 =  test_v_height + test_vsync_front_porch + test_vsync_width + test_vsync_back_porch;



parameter hsync_high_state             =  3'b1_0_0; 
parameter hsync_back_porch             =  3'b0_0_0;
parameter h_de                         =  3'b0_1_0;
parameter hsync_front_porch            =  3'b0_0_1;
                                       
parameter vsync_high_state             =  3'b1_0_0; 
parameter vsync_back_porch             =  3'b0_0_0;
parameter v_de                         =  3'b0_1_0;
parameter vsync_front_porch            =  3'b0_0_1;

// ******************************************************************
// [20200805] Enhancement: Added for SYNC checker
//assign tgen_vid_hsync = h_state[2] ;
//assign tgen_vid_vsync =  v_state[2] ;
assign tgen_vid_hsync =  (reset) ? 0 : h_state[2] ;
assign tgen_vid_vsync =  (reset) ? 0 : v_state[2] ;
assign tgen_vid_de = h_state[1] & v_state[1] ;
assign tgen_vid_lv = h_state[1] & v_state[1] ;
always @(tgen_vid_vsync or v_match or reset) begin
   if(reset) begin
      tgen_vid_fv = 1'b0;
      fv_cnt = 0;
   end
   else if(~fv_cnt & v_match) begin
      tgen_vid_fv = 1'b1;
      fv_cnt = fv_cnt+1;
   end
   else if(fv_cnt & tgen_vid_vsync)
      tgen_vid_fv = 1'b0;
   else if(fv_cnt & ~tgen_vid_vsync)
      tgen_vid_fv = 1'b1;
end

// time multiplexed comparator, atleast 1 period wide durations are a must
assign h_match = (h_counter == next_h_value); 
assign v_match = (v_counter == next_v_value); 

//++++++++++++++++++ generate 1 clock wide pulses+++++++++++++++++
assign end_of_line = h_match & (h_state == hsync_front_porch); 
assign end_of_frame = v_match & end_of_line & (v_state == vsync_high_state);
assign tgen_end_of_frame = end_of_frame;
assign tgen_end_of_line = end_of_line;

// mux to generate next_h_value
always @ ( h_state or hsync_high_to_low_count or hde_start or hde_end or hsync_low_to_high_count)
begin
case (h_state)
        hsync_high_state: next_h_value = hsync_high_to_low_count;
        hsync_back_porch: next_h_value = hde_start;
        h_de: next_h_value = hde_end;
        hsync_front_porch: next_h_value = hsync_low_to_high_count;
        default: next_h_value = hsync_high_to_low_count; 
endcase
end

// mux to generate next_v_value
always @ ( v_state or vsync_high_to_low_count or vde_start or vde_end or vsync_low_to_high_count )
begin
case (v_state)
        vsync_back_porch : next_v_value = vde_start;
        v_de :             next_v_value = vde_end;
        vsync_front_porch: next_v_value = vsync_low_to_high_count;
        vsync_high_state : next_v_value = vsync_high_to_low_count;
        default:            next_v_value = vsync_high_to_low_count;
endcase
end


assign           h_reload_count = test_h_total-1'b1; 
assign           v_reload_count = test_v_total-1'b1; 

assign           hsync_high_to_low_count = test_h_total - test_hsync_width ;
assign           hde_start = test_h_total - (test_hsync_back_porch+test_hsync_width) ;
assign           hde_end = test_h_total - (test_hsync_width+test_hsync_back_porch+test_h_width);
assign           hsync_low_to_high_count = 12'h000 ;

assign           vde_start = (test_v_total - test_vsync_back_porch);
assign           vde_end = test_v_total - (test_vsync_back_porch + test_v_height);
assign           vsync_low_to_high_count = test_v_total - (test_vsync_back_porch + test_v_height + test_vsync_front_porch );
assign           vsync_high_to_low_count = 11'b000_0000_0000 ;

// ******************************************************************

`ifdef AXI_ENABLED
if(DSI_FORMAT==1) begin
	assign axis_tvalid_o = tgen_vid_de;
end
else begin
	assign axis_tvalid_o = tgen_vid_lv;
end
`elsif AXI4S_ONLY_ENABLED
if(DSI_FORMAT==1) begin
	assign axis_tvalid_o = tgen_vid_de;
end
else begin
	assign axis_tvalid_o = tgen_vid_lv;
end
`endif

always @ ( negedge clk or posedge reset )
begin
if ( reset )
        begin
        h_counter <= 12'h000 ;
        //v_counter <= 11'b000_0000_0000 ;
        v_counter <= test_vsync_back_porch + next_v_value;
        h_state <= hsync_high_state;
        v_state <= vsync_back_porch;
        end
else
        begin

        // horizontal state machine
        case (h_state)
        hsync_high_state : begin
                        if (h_match & vid_cntl_tgen_active )
                                h_state <= hsync_back_porch;
                        else
                                h_state <= h_state;
                        end
        hsync_back_porch : begin
                        if (h_match & vid_cntl_tgen_active )
                                h_state <= h_de;
                        else
                                h_state <= h_state;
                        end
        h_de:          begin
                        if (h_match & vid_cntl_tgen_active )
                                h_state <= hsync_front_porch;
                        else
                                h_state <= h_state;
                        end
        hsync_front_porch: begin
                        if (h_match & vid_cntl_tgen_active )
                                h_state <= hsync_high_state;
                        else
                                h_state <= h_state;
                        end
        default: h_state <= hsync_high_state;
        endcase

        // vertical state machine
        case (v_state)
        vsync_back_porch : begin
                        if (v_match & vid_cntl_tgen_active & end_of_line )
                                v_state <= v_de;
                        else
                                v_state <= v_state;
                        end
        v_de:          begin
                        if (v_match & vid_cntl_tgen_active &  end_of_line)
                                v_state <= vsync_front_porch;
                        else
                                v_state <= v_state;
                        end
        vsync_front_porch: begin
                        if (v_match & vid_cntl_tgen_active & end_of_line)
                                v_state <= vsync_high_state;
                        else
                                v_state <= v_state;
                        end
        vsync_high_state: begin
                           if ( v_match & vid_cntl_tgen_active & end_of_line)
                                v_state <= vsync_back_porch;
                           else
                                v_state <= v_state;
                           end
        default: v_state <= vsync_back_porch;
        endcase


        // h_counter load or decrementing
        case ({vid_cntl_tgen_start_of_frame,end_of_line,vid_cntl_tgen_active})
        3'b 1_0_0 : h_counter <= h_reload_count;
        3'b 0_1_1 : h_counter <= h_reload_count;
        3'b 0_0_1 : h_counter <= h_counter - 1'b1 ;
        default:    h_counter <= h_reload_count;
        endcase

        // v_counter load or decrementing 
        case ({vid_cntl_tgen_start_of_frame,end_of_frame,end_of_line})
        3'b 1_0_0 : v_counter <= v_reload_count;
        3'b 0_1_1 : v_counter <= v_reload_count;
        3'b 0_0_1 : v_counter <= v_counter - 1'b1 ;
        3'b 0_0_0 : v_counter <= v_counter ;
        default:    v_counter <= 11'h 2da;
        endcase

        end
end
// ******************************************************************
//  Drive data
// *******************************************************************

   task drive_pixel;
	`ifdef AXI_ENABLED
		input [WORD_WIDTH*NUM_LANE-1:0] axis_tdata_i;
	`elsif AXI4S_ONLY_ENABLED
		input [WORD_WIDTH*NUM_LANE-1:0] axis_tdata_i;
	`else
	 `ifdef NUM_PIX_LANE_10
         input [WORD_WIDTH-1:0] pix_data9_i;
         input [WORD_WIDTH-1:0] pix_data8_i;
         input [WORD_WIDTH-1:0] pix_data7_i;
         input [WORD_WIDTH-1:0] pix_data6_i;
         input [WORD_WIDTH-1:0] pix_data5_i;
         input [WORD_WIDTH-1:0] pix_data4_i;
         input [WORD_WIDTH-1:0] pix_data3_i;
         input [WORD_WIDTH-1:0] pix_data2_i;
         input [WORD_WIDTH-1:0] pix_data1_i;
     `elsif NUM_PIX_LANE_8
         input [WORD_WIDTH-1:0] pix_data7_i;
         input [WORD_WIDTH-1:0] pix_data6_i;
         input [WORD_WIDTH-1:0] pix_data5_i;
         input [WORD_WIDTH-1:0] pix_data4_i;
         input [WORD_WIDTH-1:0] pix_data3_i;
         input [WORD_WIDTH-1:0] pix_data2_i;
         input [WORD_WIDTH-1:0] pix_data1_i;
     `elsif NUM_PIX_LANE_6
         input [WORD_WIDTH-1:0] pix_data5_i;
         input [WORD_WIDTH-1:0] pix_data4_i;
         input [WORD_WIDTH-1:0] pix_data3_i;
         input [WORD_WIDTH-1:0] pix_data2_i;
         input [WORD_WIDTH-1:0] pix_data1_i;
     `elsif NUM_PIX_LANE_4
         input [WORD_WIDTH-1:0] pix_data3_i;
         input [WORD_WIDTH-1:0] pix_data2_i;
         input [WORD_WIDTH-1:0] pix_data1_i;
     `elsif NUM_PIX_LANE_2
         input [WORD_WIDTH-1:0] pix_data1_i;
     `endif
         input [WORD_WIDTH-1:0] pix_data0_i;
    `endif		 

      begin
        //Drive data at negedge, to make data centre aligned with pixel clock  
        //@ (negedge clk); 
		`ifdef AXI_ENABLED
				tgen_vid_axi_data = axis_tdata_i;
		`elsif AXI4S_ONLY_ENABLED
				tgen_vid_axi_data = axis_tdata_i;
		`else
			`ifdef NUM_PIX_LANE_10
				tgen_vid_data9 = pix_data9_i;
				tgen_vid_data8 = pix_data8_i;
				tgen_vid_data7 = pix_data7_i;
				tgen_vid_data6 = pix_data6_i;
				tgen_vid_data5 = pix_data5_i;
				tgen_vid_data4 = pix_data4_i;
				tgen_vid_data3 = pix_data3_i;
				tgen_vid_data2 = pix_data2_i;
				tgen_vid_data1 = pix_data1_i;
			`endif 
			`ifdef NUM_PIX_LANE_8
				tgen_vid_data7 = pix_data7_i;
				tgen_vid_data6 = pix_data6_i;
				tgen_vid_data5 = pix_data5_i;
				tgen_vid_data4 = pix_data4_i;
				tgen_vid_data3 = pix_data3_i;
				tgen_vid_data2 = pix_data2_i;
				tgen_vid_data1 = pix_data1_i;
			`endif 
			`ifdef NUM_PIX_LANE_6
				tgen_vid_data5 = pix_data5_i;
				tgen_vid_data4 = pix_data4_i;
				tgen_vid_data3 = pix_data3_i;
				tgen_vid_data2 = pix_data2_i;
				tgen_vid_data1 = pix_data1_i;
			`endif 
			`ifdef NUM_PIX_LANE_4
				tgen_vid_data3 = pix_data3_i;
				tgen_vid_data2 = pix_data2_i;
				tgen_vid_data1 = pix_data1_i;
			`endif 
			`ifdef NUM_PIX_LANE_2
				tgen_vid_data1 = pix_data1_i;
			`endif
				tgen_vid_data0 = pix_data0_i;
		`endif

        @ (negedge clk); 

        //Check for de to drive further data
        check_for_de;

      end
   endtask

   task check_for_de;
      begin
        if(~tgen_vid_de) begin
            @(posedge tgen_vid_de);
        end
      end
   endtask

   initial begin
     forever begin
       @(clk);
       fork
         begin : data_gen_loop
           @(clk or reset or vid_cntl_tgen_active);
           if(reset)
           begin
			   tgen_vid_axi_data = 'h0;
               tgen_vid_data0 = 'h0;
               tgen_vid_data1 = 'h0;
               tgen_vid_data2 = 'h0;
               tgen_vid_data3 = 'h0;
               tgen_vid_data4 = 'h0;
               tgen_vid_data5 = 'h0;
               tgen_vid_data6 = 'h0;
               tgen_vid_data7 = 'h0;
               tgen_vid_data8 = 'h0;
               tgen_vid_data9 = 'h0;
               pix_data_0_buf = 'h0;
               pix_data_1_buf = 'h0;
               pix_data_2_buf = 'h0;
               pix_data_3_buf = 'h0;
               pix_data_4_buf = 'h0;
               pix_data_5_buf = 'h0;
               pix_data_6_buf = 'h0;
               pix_data_7_buf = 'h0;
               pix_data_8_buf = 'h0;
               pix_data_9_buf = 'h0;
               pix_data_10_buf = 'h0;
               pix_data_11_buf = 'h0;
               pix_data_12_buf = 'h0;
               pix_data_13_buf = 'h0;
               pix_data_14_buf = 'h0;
               pix_data_15_buf = 'h0;
               pix_data_16_buf = 'h0;
               pix_data_17_buf = 'h0;
               pix_data_18_buf = 'h0;
               pix_data_19_buf = 'h0;
               byte0 = 'h0;
               byte1 = 'h0;
               byte2 = 'h0;
               byte3 = 'h0;
               byte4 = 'h0;
               byte5 = 'h0;
               byte6 = 'h0;
               byte7 = 'h0;
               byte8 = 'h0;
               byte9 = 'h0;
               byte10 = 'h0;
               byte11 = 'h0;
               byte12 = 'h0;
               byte13 = 'h0;
               byte14 = 'h0;
               byte15 = 'h0;
               byte16 = 'h0;
               byte17 = 'h0;
               byte18 = 'h0;
               byte19 = 'h0;
               byte20 = 'h0;
               byte21 = 'h0;
               byte22 = 'h0;
               byte23 = 'h0;
               byte24 = 'h0;
           end    

           if(~vid_cntl_tgen_active)
             @(posedge vid_cntl_tgen_active);

           while(vid_cntl_tgen_active) begin
		   `ifdef AXI_ENABLED
		     if(v_state[1] && ((h_state == 'h2 && (h_match & vid_cntl_tgen_active ))) && axim_tready_i) begin
                 @ (negedge clk);
             end
		   `elsif AXI4S_ONLY_ENABLED
             if(v_state[1] && ((h_state == 'h2 && (h_match & vid_cntl_tgen_active )))) begin
                 @ (negedge clk);
             end
		   `else
             if(v_state[1] && ((h_state == 'h2 && (h_match & vid_cntl_tgen_active )))) begin
                 @ (negedge clk);
             end
		   `endif
             else
			 `ifdef AXI_ENABLED
				if(v_state[1] && (h_state[1] || (h_state == 'h0 && (h_match & vid_cntl_tgen_active ))) && axim_tready_i) begin
							
							`ifdef RGB666
							drive_rgb666_data;
							`elsif RGB888
							drive_rgb888_data;
							`elsif RGB444
							drive_rgb444_data;
							`elsif RGB555
							drive_rgb555_data;
							`elsif RGB565
							drive_rgb565_data;
							`elsif RAW8 //CSI, 1 /2 lanes
							drive_raw8_csi_data;
							`elsif YUV420_8 // CSI 1/2 lanes
							drive_yuv420_8_csi_data;
							`elsif YUV422_8 // CSI 1/2 lanes
							drive_yuv422_8_csi_data;
							`elsif YUV420_10 // CSI 1/2 lanes
							drive_yuv420_10_csi_data;
							`elsif YUV422_10 // CSI 1/2 lanes
							drive_yuv422_10_csi_data;
							`elsif RAW14 // CSI 1/2 lanes
							drive_raw14_csi_data;
							`elsif RAW16 // CSI 1/2 lanes
							drive_raw16_csi_data;
							`elsif RAW10 // CSI 1/2/3/6/8/10lanes
							`ifdef NUM_PIX_LANE_10
								drive_raw10_10lane_csi_data;
							`elsif NUM_PIX_LANE_8
								drive_raw10_8lane_csi_data;
							`elsif NUM_PIX_LANE_6
								drive_raw10_6lane_csi_data;
							`elsif NUM_PIX_LANE_4
								drive_raw10_4lane_csi_data;
							`elsif NUM_PIX_LANE_2
								drive_raw10_2lane_csi_data;
							`else   
								drive_raw10_1lane_csi_data;
							`endif
							`elsif RAW12 // CSI 1/2/3/6/8/10lanes
							`ifdef NUM_PIX_LANE_10
								drive_raw12_10lane_csi_data;
							`elsif NUM_PIX_LANE_8
								drive_raw12_8lane_csi_data;
							`elsif NUM_PIX_LANE_6
								drive_raw12_6lane_csi_data;
							`elsif NUM_PIX_LANE_4
								drive_raw12_4lane_csi_data;
							`elsif NUM_PIX_LANE_2
								drive_raw12_2lane_csi_data;
							`else   
								drive_raw12_1lane_csi_data;
							`endif
							`endif
				end    
				else begin
					@ (negedge clk);
				end
			 `elsif AXI4S_ONLY_ENABLED
				if(v_state[1] && (h_state[1] || (h_state == 'h0 && (h_match & vid_cntl_tgen_active )))) begin
							`ifdef RGB666
							drive_rgb666_data;
							`elsif RGB888
							drive_rgb888_data;
							`elsif RGB444
							drive_rgb444_data;
							`elsif RGB555
							drive_rgb555_data;
							`elsif RGB565
							drive_rgb565_data;
							`elsif RAW8 //CSI, 1 /2 lanes
							drive_raw8_csi_data;
							`elsif YUV420_8 // CSI 1/2 lanes
							drive_yuv420_8_csi_data;
							`elsif YUV422_8 // CSI 1/2 lanes
							drive_yuv422_8_csi_data;
							`elsif YUV420_10 // CSI 1/2 lanes
							drive_yuv420_10_csi_data;
							`elsif YUV422_10 // CSI 1/2 lanes
							drive_yuv422_10_csi_data;
							`elsif RAW14 // CSI 1/2 lanes
							drive_raw14_csi_data;
							`elsif RAW16 // CSI 1/2 lanes
							drive_raw16_csi_data;
							`elsif RAW10 // CSI 1/2/3/6/8/10lanes
							`ifdef NUM_PIX_LANE_10
								drive_raw10_10lane_csi_data;
							`elsif NUM_PIX_LANE_8
								drive_raw10_8lane_csi_data;
							`elsif NUM_PIX_LANE_6
								drive_raw10_6lane_csi_data;
							`elsif NUM_PIX_LANE_4
								drive_raw10_4lane_csi_data;
							`elsif NUM_PIX_LANE_2
								drive_raw10_2lane_csi_data;
							`else   
								drive_raw10_1lane_csi_data;
							`endif
							`elsif RAW12 // CSI 1/2/3/6/8/10lanes
							`ifdef NUM_PIX_LANE_10
								drive_raw12_10lane_csi_data;
							`elsif NUM_PIX_LANE_8
								drive_raw12_8lane_csi_data;
							`elsif NUM_PIX_LANE_6
								drive_raw12_6lane_csi_data;
							`elsif NUM_PIX_LANE_4
								drive_raw12_4lane_csi_data;
							`elsif NUM_PIX_LANE_2
								drive_raw12_2lane_csi_data;
							`else   
								drive_raw12_1lane_csi_data;
							`endif
							`endif
				end    
				else begin
					@ (negedge clk);
				end
			 `else
				if(v_state[1] && (h_state[1] || (h_state == 'h0 && (h_match & vid_cntl_tgen_active )))) begin
							`ifdef RGB666
							drive_rgb666_data;
							`elsif RGB888
							drive_rgb888_data;
							`elsif RGB444
							drive_rgb444_data;
							`elsif RGB555
							drive_rgb555_data;
							`elsif RGB565
							drive_rgb565_data;
							`elsif RAW8 //CSI, 1 /2 lanes
							drive_raw8_csi_data;
							`elsif YUV420_8 // CSI 1/2 lanes
							drive_yuv420_8_csi_data;
							`elsif YUV422_8 // CSI 1/2 lanes
							drive_yuv422_8_csi_data;
							`elsif YUV420_10 // CSI 1/2 lanes
							drive_yuv420_10_csi_data;
							`elsif YUV422_10 // CSI 1/2 lanes
							drive_yuv422_10_csi_data;
							`elsif RAW14 // CSI 1/2 lanes
							drive_raw14_csi_data;
							`elsif RAW16 // CSI 1/2 lanes
							drive_raw16_csi_data;
							`elsif RAW10 // CSI 1/2/3/6/8/10lanes
							`ifdef NUM_PIX_LANE_10
								drive_raw10_10lane_csi_data;
							`elsif NUM_PIX_LANE_8
								drive_raw10_8lane_csi_data;
							`elsif NUM_PIX_LANE_6
								drive_raw10_6lane_csi_data;
							`elsif NUM_PIX_LANE_4
								drive_raw10_4lane_csi_data;
							`elsif NUM_PIX_LANE_2
								drive_raw10_2lane_csi_data;
							`else   
								drive_raw10_1lane_csi_data;
							`endif
							`elsif RAW12 // CSI 1/2/3/6/8/10lanes
							`ifdef NUM_PIX_LANE_10
								drive_raw12_10lane_csi_data;
							`elsif NUM_PIX_LANE_8
								drive_raw12_8lane_csi_data;
							`elsif NUM_PIX_LANE_6
								drive_raw12_6lane_csi_data;
							`elsif NUM_PIX_LANE_4
								drive_raw12_4lane_csi_data;
							`elsif NUM_PIX_LANE_2
								drive_raw12_2lane_csi_data;
							`else   
								drive_raw12_1lane_csi_data;
							`endif
							`endif
				end    
				else begin
					@ (negedge clk);
				end
			`endif
           end
         end
         @(posedge reset) disable data_gen_loop;
       join
     end
   end

   task drive_rgb666_data;
       begin
           byte0 = $random;
           byte1 = $random;
           byte2 = $random;
           byte3 = $random;
           byte4 = $random;
           byte5 = $random;
           byte6 = $random;
           byte7 = $random;
           byte8 = $random;

           pix_data_0_buf = {byte2[1:0], byte1[7:0], byte0[7:0]};
           pix_data_1_buf = {byte4[3:0], byte3[7:0], byte2[7:2]};
           pix_data_2_buf = {byte6[5:0], byte5[7:0], byte4[7:4]};
           pix_data_3_buf = {byte8[7:0], byte7[7:0], byte6[7:6]};

           write_to_file("input_data.log", byte0);		
           write_to_file("input_data.log", byte1);      
           write_to_file("input_data.log", byte2[1:0]); 
		   write_to_file("input_data.log", byte2[7:2]); 
           write_to_file("input_data.log", byte3);      
           write_to_file("input_data.log", byte4[3:0]); 
		   write_to_file("input_data.log", byte4[7:4]); 
           write_to_file("input_data.log", byte5);      
           write_to_file("input_data.log", byte6[5:0]); 
		   write_to_file("input_data.log", byte6[7:6]); 
           write_to_file("input_data.log", byte7);      
           write_to_file("input_data.log", byte8);      
		   
		   `ifdef AXI_ENABLED
		    `ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
			`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `elsif AXI4S_ONLY_ENABLED
			`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
			`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `else
		    `ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
			`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `endif
       end
   endtask
   
   task drive_rgb444_data;
       begin
           byte0 = $random;
           byte1 = $random;
           byte2 = $random;
           byte3 = $random;
           byte4 = $random;
           byte5 = $random;

           pix_data_0_buf = {byte1[3:0], byte0[7:0]};
           pix_data_1_buf = {byte2[7:0], byte1[7:4]};
           pix_data_2_buf = {byte4[3:0], byte3[7:0]};
           pix_data_3_buf = {byte5[7:0], byte4[7:4]};

           /*write_to_file("input_data.log", byte0[7:0]);		
           write_to_file("input_data.log", byte1[3:0]);      
           write_to_file("input_data.log", byte1[7:4]); 
		   write_to_file("input_data.log", byte2[7:0]); 
           write_to_file("input_data.log", byte3[7:0]);      
           write_to_file("input_data.log", byte4[3:0]); 
		   write_to_file("input_data.log", byte4[7:4]); 
           write_to_file("input_data.log", byte5[7:0]);*/
		   
		   write_to_file("input_data.log", one);            
		   write_to_file("input_data.log", byte0[3:0]);     
		   write_to_file("input_data.log", zero);           
		   write_to_file("input_data.log", one);		    
           write_to_file("input_data.log", byte0[7:4]);     
		   write_to_file("input_data.log", one);            
           write_to_file("input_data.log", byte1[3:0]);     //pixel 1 upto here
		   write_to_file("input_data.log", one);            
		   write_to_file("input_data.log", byte1[7:4]);     
		   write_to_file("input_data.log", zero);           
		   write_to_file("input_data.log", one);		    
           write_to_file("input_data.log", byte2[3:0]);     
		   write_to_file("input_data.log", one);            
           write_to_file("input_data.log", byte2[7:4]);     //pixel 2 upto here    
		   write_to_file("input_data.log", one);            
		   write_to_file("input_data.log", byte3[3:0]);     
		   write_to_file("input_data.log", zero);           
		   write_to_file("input_data.log", one);		    
           write_to_file("input_data.log", byte3[7:4]);     
		   write_to_file("input_data.log", one);            
           write_to_file("input_data.log", byte4[3:0]);     //pixel 3 upto here   
		   write_to_file("input_data.log", one);            
		   write_to_file("input_data.log", byte4[7:4]);     
		   write_to_file("input_data.log", zero);           
		   write_to_file("input_data.log", one);		    
           write_to_file("input_data.log", byte5[3:0]);     
		   write_to_file("input_data.log", one);            
           write_to_file("input_data.log", byte5[7:4]);     //pixel 4 upto here
		   
		   `ifdef AXI_ENABLED
		    `ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
			`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `elsif AXI4S_ONLY_ENABLED
		    `ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
			`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `else
		    `ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
			`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `endif
       end
   endtask
   
   task drive_rgb555_data;
       begin
           byte0 = $random;
           byte1 = $random;
           byte2 = $random;
           byte3 = $random;
           byte4 = $random;
           byte5 = $random;
		   byte6 = $random;
		   byte7 = $random;

           pix_data_0_buf = {byte1[6:0], byte0[7:0]};
           pix_data_1_buf = {byte3[5:0], byte2[7:0], byte1[7]};
           pix_data_2_buf = {byte5[4:0], byte4[7:0], byte3[7:6]};
           pix_data_3_buf = {byte7[3:0], byte6[7:0], byte5[7:5]};

           /*write_to_file("input_data.log", byte0[4:0]);		
           write_to_file("input_data.log", zero);   
		   write_to_file("input_data.log", {byte1[1:0],byte0[7:5]}); 
		   write_to_file("input_data.log", byte1[6:2]);

		   write_to_file("input_data.log", {byte2[3:0],byte1[7]});		   
           write_to_file("input_data.log", zero);   
		   write_to_file("input_data.log", {byte3[0],byte2[7:4]});
           write_to_file("input_data.log", byte3[5:1]);
		   
		   write_to_file("input_data.log", {byte4[2:0],byte3[7:6]});		
           write_to_file("input_data.log", zero);;
           write_to_file("input_data.log", byte4[7:3]); 
		   write_to_file("input_data.log", byte5[4:0]);
		   
		   write_to_file("input_data.log", {byte6[1:0],byte5[7:5]});		
           write_to_file("input_data.log", zero);;
           write_to_file("input_data.log", byte6[6:2]); 
		   write_to_file("input_data.log", {byte7[3:0],byte6[7]});*/
		   
		   write_to_file("input_data.log", byte0[4:0]);		
           write_to_file("input_data.log", zero);   
		   write_to_file("input_data.log", byte0[7:5]); 
		   write_to_file("input_data.log", byte1[1:0]);
		   write_to_file("input_data.log", byte1[6:2]);  //pixel 1 upto here

		   write_to_file("input_data.log", byte1[7]);
		   write_to_file("input_data.log", byte2[3:0]);		   
           write_to_file("input_data.log", zero);   
		   write_to_file("input_data.log", byte2[7:4]);
		   write_to_file("input_data.log", byte3[0]);
           write_to_file("input_data.log", byte3[5:1]);  //pixel 2 upto here
		   
		   write_to_file("input_data.log", byte3[7:6]);
		   write_to_file("input_data.log", byte4[2:0]);
           write_to_file("input_data.log", zero);
           write_to_file("input_data.log", byte4[7:3]); 
		   write_to_file("input_data.log", byte5[4:0]);  //pixel 3 upto here
		   
		   write_to_file("input_data.log", byte5[7:5]);
		   write_to_file("input_data.log", byte6[1:0]);
           write_to_file("input_data.log", zero);
           //write_to_file("input_data.log", byte6[6:2]);
		   write_to_file("input_data.log", byte6[7:2]);
		   //write_to_file("input_data.log", byte6[7]);
		   write_to_file("input_data.log", byte7[3:0]);  //pixel 4 upto here

		   
		   
		   `ifdef AXI_ENABLED
		    `ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
			`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
			`elsif AXI4S_ONLY_ENABLED
		    `ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
			`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `else
		    `ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
			`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
			`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
			`endif
		   `endif
       end
   endtask
   
//input data writing into file only for RGB565			
`ifdef RGB565
always@(posedge clk) begin
`ifdef AXI_ENABLED
if(axis_tvalid_o==1'b1) begin
	`ifdef NUM_PIX_LANE_1
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	`elsif NUM_PIX_LANE_2
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);	
	`elsif NUM_PIX_LANE_4
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);
	write_to_file("input_data.log", tgen_vid_axi_data[39:32]);
	write_to_file("input_data.log", tgen_vid_axi_data[47:40]);
	write_to_file("input_data.log", tgen_vid_axi_data[55:48]);
	write_to_file("input_data.log", tgen_vid_axi_data[63:56]);
	`endif
end
`elsif AXI4S_ONLY_ENABLED
if(axis_tvalid_o==1'b1) begin
	`ifdef NUM_PIX_LANE_1
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	`elsif NUM_PIX_LANE_2
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);	
	`elsif NUM_PIX_LANE_4
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);
	write_to_file("input_data.log", tgen_vid_axi_data[39:32]);
	write_to_file("input_data.log", tgen_vid_axi_data[47:40]);
	write_to_file("input_data.log", tgen_vid_axi_data[55:48]);
	write_to_file("input_data.log", tgen_vid_axi_data[63:56]);
	`endif
end
`else
if(tgen_vid_lv==1'b1) begin
	`ifdef NUM_PIX_LANE_1
	write_to_file("input_data.log", tgen_vid_data0[7:0]);
	write_to_file("input_data.log", tgen_vid_data0[15:8]);
	`elsif NUM_PIX_LANE_2
	write_to_file("input_data.log", tgen_vid_data0[7:0]);
	write_to_file("input_data.log", tgen_vid_data0[15:8]);
	write_to_file("input_data.log", tgen_vid_data1[7:0]);
	write_to_file("input_data.log", tgen_vid_data1[15:8]);	
	`elsif NUM_PIX_LANE_4
	write_to_file("input_data.log", tgen_vid_data0[7:0]);
	write_to_file("input_data.log", tgen_vid_data0[15:8]);
	write_to_file("input_data.log", tgen_vid_data1[7:0]);
	write_to_file("input_data.log", tgen_vid_data1[15:8]);
	write_to_file("input_data.log", tgen_vid_data2[7:0]);
	write_to_file("input_data.log", tgen_vid_data2[15:8]);
	write_to_file("input_data.log", tgen_vid_data3[7:0]);
	write_to_file("input_data.log", tgen_vid_data3[15:8]);
	`endif
end
`endif
end
`endif

   task drive_rgb565_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;

            pix_data_0_buf = {byte1, byte0};
            pix_data_1_buf = {byte3, byte2};
            pix_data_2_buf = {byte5, byte4};
            pix_data_3_buf = {byte7, byte6};

			//INPUT DATA WRITING LOGIC IS WRITTEN IN TB_TOP.V FOR RGB565
            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);*/

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
       end
   endtask

   task drive_rgb888_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;
            byte8 = $random;
            byte9 = $random;
            byte10= $random;
            byte11= $random;

            pix_data_0_buf = {byte2, byte1, byte0};
            pix_data_1_buf = {byte5, byte4, byte3};
            pix_data_2_buf = {byte8, byte7, byte6};
            pix_data_3_buf = {byte11, byte10, byte9};

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            write_to_file("input_data.log", byte8);
            write_to_file("input_data.log", byte9);
            write_to_file("input_data.log", byte10);
            write_to_file("input_data.log", byte11);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
       end
   endtask

   task drive_raw12_1lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;

            pix_data_0_buf = {byte0[7:0], byte2[3:0]};
            pix_data_1_buf = {byte1[7:0], byte2[7:4]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);*/
			write_to_file("input_data.log", byte2[3:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte2[7:4]);
			write_to_file("input_data.log", byte1);

            `ifdef NUM_PIX_LANE_1
            drive_pixel(pix_data_0_buf);
            drive_pixel(pix_data_1_buf);
            `endif
      end
   endtask

   task drive_raw12_2lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;

            pix_data_0_buf = {byte0[7:0], byte2[3:0]};
            pix_data_1_buf = {byte1[7:0], byte2[7:4]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);*/
			write_to_file("input_data.log", byte2[3:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte2[7:4]);
			write_to_file("input_data.log", byte1);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw12_4lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;

            pix_data_0_buf = {byte0[7:0], byte2[3:0]};
            pix_data_1_buf = {byte1[7:0], byte2[7:4]};
            pix_data_2_buf = {byte3[7:0], byte5[3:0]};
            pix_data_3_buf = {byte4[7:0], byte5[7:4]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);*/
			write_to_file("input_data.log", byte2[3:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte2[7:4]);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte5[3:0]);
            write_to_file("input_data.log", byte3);
			write_to_file("input_data.log", byte5[7:4]);
            write_to_file("input_data.log", byte4);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw12_6lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;
            byte8 = $random;

            pix_data_0_buf = {byte0[7:0], byte2[3:0]};
            pix_data_1_buf = {byte1[7:0], byte2[7:4]};
            pix_data_2_buf = {byte3[7:0], byte5[3:0]};
            pix_data_3_buf = {byte4[7:0], byte5[7:4]};
            pix_data_4_buf = {byte6[7:0], byte8[3:0]};
            pix_data_5_buf = {byte7[7:0], byte8[7:4]};

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            write_to_file("input_data.log", byte8);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_6
				drive_pixel({pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_6
				drive_pixel({pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_6
				drive_pixel(pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw12_8lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;
            byte8 = $random;
            byte9 = $random;
            byte10 = $random;
            byte11 = $random;

            pix_data_0_buf = {byte0[7:0], byte2[3:0]};
            pix_data_1_buf = {byte1[7:0], byte2[7:4]};
            pix_data_2_buf = {byte3[7:0], byte5[3:0]};
            pix_data_3_buf = {byte4[7:0], byte5[7:4]};
            pix_data_4_buf = {byte6[7:0], byte8[3:0]};
            pix_data_5_buf = {byte7[7:0], byte8[7:4]};
            pix_data_6_buf = {byte9[7:0], byte11[3:0]};
            pix_data_7_buf = {byte10[7:0], byte11[7:4]};

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            write_to_file("input_data.log", byte8);
            write_to_file("input_data.log", byte9);
            write_to_file("input_data.log", byte10);
            write_to_file("input_data.log", byte11);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_8
				drive_pixel({pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_8
				drive_pixel({pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_8
				drive_pixel(pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				`endif
			`endif
      end
   endtask   

   task drive_raw12_10lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;
            byte8 = $random;
            byte9 = $random;
            byte10 = $random;
            byte11 = $random;
            byte12 = $random;
            byte13 = $random;
            byte14 = $random;

            pix_data_0_buf = {byte0[7:0], byte2[3:0]};
            pix_data_1_buf = {byte1[7:0], byte2[7:4]};
            pix_data_2_buf = {byte3[7:0], byte5[3:0]};
            pix_data_3_buf = {byte4[7:0], byte5[7:4]};
            pix_data_4_buf = {byte6[7:0], byte8[3:0]};
            pix_data_5_buf = {byte7[7:0], byte8[7:4]};
            pix_data_6_buf = {byte9[7:0], byte11[3:0]};
            pix_data_7_buf = {byte10[7:0], byte11[7:4]};
            pix_data_8_buf = {byte12[7:0], byte14[3:0]};
            pix_data_9_buf = {byte13[7:0], byte14[7:4]};

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            write_to_file("input_data.log", byte8);
            write_to_file("input_data.log", byte9);
            write_to_file("input_data.log", byte10);
            write_to_file("input_data.log", byte11);
            write_to_file("input_data.log", byte12);
            write_to_file("input_data.log", byte13);
            write_to_file("input_data.log", byte14);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_10
				drive_pixel({pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_10
				drive_pixel({pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_10
				drive_pixel(pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw8_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;

            pix_data_0_buf = byte0;
            pix_data_1_buf = byte1;
            pix_data_2_buf = byte2;
            pix_data_3_buf = byte3;

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw10_1lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);*/
			write_to_file("input_data.log", byte4[1:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte4[3:2]);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte4[5:4]);
			write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte4[7:6]);
            write_to_file("input_data.log", byte3);
			

            `ifdef NUM_PIX_LANE_1
            drive_pixel(pix_data_0_buf);
            drive_pixel(pix_data_1_buf);
            drive_pixel(pix_data_2_buf);
            drive_pixel(pix_data_3_buf);
            `endif
      end
   endtask

   task drive_raw10_2lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);*/
			write_to_file("input_data.log", byte4[1:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte4[3:2]);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte4[5:4]);
			write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte4[7:6]);
            write_to_file("input_data.log", byte3);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw10_4lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);*/
			write_to_file("input_data.log", byte4[1:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte4[3:2]);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte4[5:4]);
			write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte4[7:6]);
            write_to_file("input_data.log", byte3);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw10_6lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;
            byte8 = $random;
            byte9 = $random;
            byte10 = $random;
            byte11 = $random;
            byte12 = $random;
            byte13 = $random;
            byte14 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};
            pix_data_4_buf = {byte5[7:0],byte9[1:0]};
            pix_data_5_buf = {byte6[7:0],byte9[3:2]};
            pix_data_6_buf = {byte7[7:0],byte9[5:4]};
            pix_data_7_buf = {byte8[7:0],byte9[7:6]};
            pix_data_8_buf = {byte10[7:0],byte14[1:0]};
            pix_data_9_buf = {byte11[7:0],byte14[3:2]};
            pix_data_10_buf = {byte12[7:0],byte14[5:4]};
            pix_data_11_buf = {byte13[7:0],byte14[7:6]};

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            write_to_file("input_data.log", byte8);
            write_to_file("input_data.log", byte9);
            write_to_file("input_data.log", byte10);
            write_to_file("input_data.log", byte11);
            write_to_file("input_data.log", byte12);
            write_to_file("input_data.log", byte13);
            write_to_file("input_data.log", byte14);

			`ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_6
				drive_pixel({pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_11_buf, pix_data_10_buf,
							pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_6
				drive_pixel({pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_11_buf, pix_data_10_buf,
							pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_6
				drive_pixel(pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_11_buf, pix_data_10_buf,
							pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw10_8lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;
            byte8 = $random;
            byte9 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};
            pix_data_4_buf = {byte5[7:0],byte9[1:0]};
            pix_data_5_buf = {byte6[7:0],byte9[3:2]};
            pix_data_6_buf = {byte7[7:0],byte9[5:4]};
            pix_data_7_buf = {byte8[7:0],byte9[7:6]};

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            write_to_file("input_data.log", byte8);
            write_to_file("input_data.log", byte9);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_8
				drive_pixel({pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_8
				drive_pixel({pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_8
				drive_pixel(pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				`endif
			`endif
      end
   endtask

   task drive_raw10_10lane_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;
            byte8 = $random;
            byte9 = $random;
            byte10 = $random;
            byte11 = $random;
            byte12 = $random;
            byte13 = $random;
            byte14 = $random;
            byte15 = $random;
            byte16 = $random;
            byte17 = $random;
            byte18 = $random;
            byte19 = $random;
            byte20 = $random;
            byte21 = $random;
            byte22 = $random;
            byte23 = $random;
            byte24 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};
            pix_data_4_buf = {byte5[7:0],byte9[1:0]};
            pix_data_5_buf = {byte6[7:0],byte9[3:2]};
            pix_data_6_buf = {byte7[7:0],byte9[5:4]};
            pix_data_7_buf = {byte8[7:0],byte9[7:6]};
            pix_data_8_buf = {byte10[7:0],byte14[1:0]};
            pix_data_9_buf = {byte11[7:0],byte14[3:2]};
            pix_data_10_buf = {byte12[7:0],byte14[5:4]};
            pix_data_11_buf = {byte13[7:0],byte14[7:6]};
            pix_data_12_buf = {byte15[7:0],byte19[1:0]};
            pix_data_13_buf = {byte16[7:0],byte19[3:2]};
            pix_data_14_buf = {byte17[7:0],byte19[5:4]};
            pix_data_15_buf = {byte18[7:0],byte19[7:6]};
            pix_data_16_buf = {byte20[7:0],byte24[1:0]};
            pix_data_17_buf = {byte21[7:0],byte24[3:2]};
            pix_data_18_buf = {byte22[7:0],byte24[5:4]};
            pix_data_19_buf = {byte23[7:0],byte24[7:6]};

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            write_to_file("input_data.log", byte8);
            write_to_file("input_data.log", byte9);
            write_to_file("input_data.log", byte10);
            write_to_file("input_data.log", byte11);
            write_to_file("input_data.log", byte12);
            write_to_file("input_data.log", byte13);
            write_to_file("input_data.log", byte14);
            write_to_file("input_data.log", byte15);
            write_to_file("input_data.log", byte16);
            write_to_file("input_data.log", byte17);
            write_to_file("input_data.log", byte18);
            write_to_file("input_data.log", byte19);
            write_to_file("input_data.log", byte20);
            write_to_file("input_data.log", byte21);
            write_to_file("input_data.log", byte22);
            write_to_file("input_data.log", byte23);
            write_to_file("input_data.log", byte24);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_10
				drive_pixel({pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_19_buf, pix_data_18_buf,
							pix_data_17_buf, pix_data_16_buf,
							pix_data_15_buf, pix_data_14_buf,
							pix_data_13_buf, pix_data_12_buf,
							pix_data_11_buf, pix_data_10_buf});
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_10
				drive_pixel({pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_19_buf, pix_data_18_buf,
							pix_data_17_buf, pix_data_16_buf,
							pix_data_15_buf, pix_data_14_buf,
							pix_data_13_buf, pix_data_12_buf,
							pix_data_11_buf, pix_data_10_buf});
				`endif
			`else
				`ifdef NUM_PIX_LANE_10
				drive_pixel(pix_data_9_buf, pix_data_8_buf,
							pix_data_7_buf, pix_data_6_buf,
							pix_data_5_buf, pix_data_4_buf,
							pix_data_3_buf, pix_data_2_buf,
							pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_19_buf, pix_data_18_buf,
							pix_data_17_buf, pix_data_16_buf,
							pix_data_15_buf, pix_data_14_buf,
							pix_data_13_buf, pix_data_12_buf,
							pix_data_11_buf, pix_data_10_buf);
				`endif
			`endif
      end
   endtask

   task drive_yuv422_8_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;

            pix_data_0_buf = byte0;
            pix_data_1_buf = byte1;
            pix_data_2_buf = byte2;
            pix_data_3_buf = byte3;

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
      end
   endtask

   task drive_yuv422_10_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);*/
			write_to_file("input_data.log", byte4[1:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte4[3:2]);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte4[5:4]);
			write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte4[7:6]);
            write_to_file("input_data.log", byte3);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
      end
   endtask

// [20201009] Added for new data type
   task drive_raw14_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[5:0]};
            pix_data_1_buf = {byte1[7:0],byte5[3:0],byte4[7:6]};
            pix_data_2_buf = {byte2[7:0],byte6[1:0],byte5[7:4]};
            pix_data_3_buf = {byte3[7:0],byte6[7:2]};

			
			write_to_file("input_data.log", byte4[5:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte4[7:6]);
            write_to_file("input_data.log", byte5[3:0]);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte5[7:4]);
            write_to_file("input_data.log", byte6[1:0]);
			write_to_file("input_data.log", byte2);
			write_to_file("input_data.log", byte6[7:2]);
			write_to_file("input_data.log", byte3);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
      end
   endtask

//input data writing into file only for RAW16			
`ifdef RAW16
always@(posedge clk) begin
`ifdef AXI_ENABLED
if(axis_tvalid_o==1'b1) begin
	`ifdef NUM_PIX_LANE_1
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	`elsif NUM_PIX_LANE_2
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	`elsif NUM_PIX_LANE_4
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	write_to_file("input_data.log", tgen_vid_axi_data[47:40]);
	write_to_file("input_data.log", tgen_vid_axi_data[39:32]);
	write_to_file("input_data.log", tgen_vid_axi_data[63:56]);
	write_to_file("input_data.log", tgen_vid_axi_data[55:48]);
	`endif
end
`elsif AXI4S_ONLY_ENABLED
if(axis_tvalid_o==1'b1) begin
	`ifdef NUM_PIX_LANE_1
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	`elsif NUM_PIX_LANE_2
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	`elsif NUM_PIX_LANE_4
	write_to_file("input_data.log", tgen_vid_axi_data[15:8]);
	write_to_file("input_data.log", tgen_vid_axi_data[7:0]);
	write_to_file("input_data.log", tgen_vid_axi_data[31:24]);
	write_to_file("input_data.log", tgen_vid_axi_data[23:16]);
	write_to_file("input_data.log", tgen_vid_axi_data[47:40]);
	write_to_file("input_data.log", tgen_vid_axi_data[39:32]);
	write_to_file("input_data.log", tgen_vid_axi_data[63:56]);
	write_to_file("input_data.log", tgen_vid_axi_data[55:48]);
	`endif
end
`else
if(tgen_vid_lv==1'b1) begin
	`ifdef NUM_PIX_LANE_1
	write_to_file("input_data.log", tgen_vid_data0[15:8]);
	write_to_file("input_data.log", tgen_vid_data0[7:0]);
	`elsif NUM_PIX_LANE_2
	write_to_file("input_data.log", tgen_vid_data0[15:8]);
	write_to_file("input_data.log", tgen_vid_data0[7:0]);
	write_to_file("input_data.log", tgen_vid_data1[15:8]);
	write_to_file("input_data.log", tgen_vid_data1[7:0]);	
	`elsif NUM_PIX_LANE_4
	write_to_file("input_data.log", tgen_vid_data0[15:8]);
	write_to_file("input_data.log", tgen_vid_data0[7:0]);
	write_to_file("input_data.log", tgen_vid_data1[15:8]);
	write_to_file("input_data.log", tgen_vid_data1[7:0]);
	write_to_file("input_data.log", tgen_vid_data2[15:8]);
	write_to_file("input_data.log", tgen_vid_data2[7:0]);
	write_to_file("input_data.log", tgen_vid_data3[15:8]);
	write_to_file("input_data.log", tgen_vid_data3[7:0]);
	`endif
end
`endif
end
`endif

   task drive_raw16_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;
            byte5 = $random;
            byte6 = $random;
            byte7 = $random;

            pix_data_0_buf = {byte0,byte1};
            pix_data_1_buf = {byte2,byte3};
            pix_data_2_buf = {byte4,byte5};
            pix_data_3_buf = {byte6,byte7};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            `ifdef NUM_PIX_LANE_4
            write_to_file("input_data.log", byte4);
            write_to_file("input_data.log", byte5);
            write_to_file("input_data.log", byte6);
            write_to_file("input_data.log", byte7);
            `endif*/
			

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf,pix_data_2_buf,pix_data_1_buf,pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf,pix_data_0_buf});
				drive_pixel({pix_data_3_buf,pix_data_2_buf}); //change by pavan
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf,pix_data_2_buf,pix_data_1_buf,pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf,pix_data_0_buf);
				drive_pixel(pix_data_3_buf,pix_data_2_buf);  //added by pavan
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif

      end
   endtask

// EndOfEdit

   task drive_yuv420_8_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;

            pix_data_0_buf = byte0;
            pix_data_1_buf = byte1;
            pix_data_2_buf = byte2;
            pix_data_3_buf = byte3;

            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
      end
   endtask

   task drive_yuv420_10_csi_data;
       begin
            byte0 = $random;
            byte1 = $random;
            byte2 = $random;
            byte3 = $random;
            byte4 = $random;

            pix_data_0_buf = {byte0[7:0],byte4[1:0]};
            pix_data_1_buf = {byte1[7:0],byte4[3:2]};
            pix_data_2_buf = {byte2[7:0],byte4[5:4]};
            pix_data_3_buf = {byte3[7:0],byte4[7:6]};

            /*write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte3);
            write_to_file("input_data.log", byte4);*/
			write_to_file("input_data.log", byte4[1:0]);
            write_to_file("input_data.log", byte0);
            write_to_file("input_data.log", byte4[3:2]);
            write_to_file("input_data.log", byte1);
            write_to_file("input_data.log", byte4[5:4]);
			write_to_file("input_data.log", byte2);
            write_to_file("input_data.log", byte4[7:6]);
            write_to_file("input_data.log", byte3);

            `ifdef AXI_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`elsif AXI4S_ONLY_ENABLED
				`ifdef NUM_PIX_LANE_4
				drive_pixel({pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf});
				`elsif NUM_PIX_LANE_2
				drive_pixel({pix_data_1_buf, pix_data_0_buf});
				drive_pixel({pix_data_3_buf, pix_data_2_buf});
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`else
				`ifdef NUM_PIX_LANE_4
				drive_pixel(pix_data_3_buf, pix_data_2_buf, pix_data_1_buf, pix_data_0_buf);
				`elsif NUM_PIX_LANE_2
				drive_pixel(pix_data_1_buf, pix_data_0_buf);
				drive_pixel(pix_data_3_buf, pix_data_2_buf);
				`elsif NUM_PIX_LANE_1
				drive_pixel(pix_data_0_buf);
				drive_pixel(pix_data_1_buf);
				drive_pixel(pix_data_2_buf);
				drive_pixel(pix_data_3_buf);
				`endif
			`endif
      end
   endtask

   task write_to_file (input [1024*8-1:0] str_in, input [7:0] data);
      integer filedesc;
      if(byte_log_en == 1)
      begin
         filedesc = $fopen(str_in,"a");
         $fwrite(filedesc, "%b\n", data);
         $fclose(filedesc);
      end
   endtask

endmodule
`endif