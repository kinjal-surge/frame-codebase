`timescale 1 ps / 1fs
`include "dut_defines.v"
`include "tb_include/tb_params.vh"
`include "vid_timing_gen_driver.v"
`include "byte_out_monitor.v"


module tb_top();	 
`include "dut_params.v"   

   //below parameters are declared in tb_params.vh file

   parameter num_frames    = `NUM_FRAMES;
   parameter num_lines     = `NUM_LINES;
   
   parameter hfront_porch  = `HFRONT;
   parameter hsync_pulse   = `HPULSE;
   parameter hback_porch   = `HBACK;
   parameter vfront_porch  = `VFRONT;
   parameter vsync_pulse   = `VPULSE;
   parameter vback_porch   = `VBACK;
   
   `ifdef USER_DEFINED_PIXEL_COUNT
   parameter manual_pixels = `USER_PIXEL_COUNT;
   `endif
   
   
   //below parameter is defined in dut_defines.v file
    `ifdef  TX_GEAR_16
         parameter GEAR_16 = 1;
    `else 
         parameter GEAR_16 = 0;
    `endif
   `ifndef MISC_ON
//      parameter init_drive_delay = `INIT_DRIVE_DELAY;
   `endif
   
   parameter output_width_in_bytes = (DATA_WIDTH*NUM_TX_LANE*TX_GEAR)/128;  // 16*1*8/128 = 1 byte
   parameter input_width_in_bits = PIX_WIDTH*NUM_PIX_LANE;  // 24*1 = 24 bits i.e. in binary 11000
   parameter input_width_in_bytes = input_width_in_bits[0] ? input_width_in_bits : 
                                    input_width_in_bits[1] ? input_width_in_bits/2 :
                                    input_width_in_bits[2] ? input_width_in_bits/4 :
                                                             input_width_in_bits/8;  // as 0th,1st,2nd bits are zeroes and 3rd and 4th bit are ones, 24 is divided by 8 to get number of bytes i.e. 3 bytes
   parameter multiple_bytes = input_width_in_bytes*output_width_in_bytes;  // 3*1 = 3 multiple bytes
   parameter least_common_multiple_bytes = multiple_bytes[0] ? multiple_bytes*4 : multiple_bytes[1] ? multiple_bytes*2 : multiple_bytes;  // as 3 value in biary is 0011 so multiples_bytes[0]==1, so least_common_multiple_bytes=3*4=12 bytes
   parameter number_of_bytes = (1 + `NUM_BYTES/least_common_multiple_bytes)*least_common_multiple_bytes;  // (1 + 240/12)*12 = 21*12=252 bytes
   parameter total_pix = number_of_bytes*8/PIX_WIDTH;  // 252*8/24 = 84
   parameter act_pix = total_pix/NUM_PIX_LANE; // 84/1=84
   
   parameter total_line     = `NUM_LINES; // 5
   //parameter pixclk_period  = `SIP_PCLK/2; // 7500/2 = 3750
   //parameter byteclk_period = (pixclk_period*DATA_WIDTH*NUM_TX_LANE*TX_GEAR)/(PIX_WIDTH*NUM_PIX_LANE*16); //(3750*16*1*8)/(24*1*16) = 480000/384 = 1250
   parameter pixclk_period  = (1/PIX_CLK_FREQ)*500000; //clk period is in pico seconds
   parameter byteclk_period = (1/BYTE_CLK_FREQ)*500000; //clk period is in pico seconds
   `ifdef RGB444
		`ifdef USER_DEFINED_PIXEL_COUNT
			localparam exp_byte_count = (`NUM_FRAMES * `NUM_LINES * manual_pixels * 16)/8;
		`else
			localparam exp_byte_count = (`NUM_FRAMES * `NUM_LINES * total_pix * 16)/8;
		`endif
	`elsif RGB555
		`ifdef USER_DEFINED_PIXEL_COUNT
			localparam exp_byte_count = (`NUM_FRAMES * `NUM_LINES * manual_pixels * 16)/8;
		`else
			localparam exp_byte_count = (`NUM_FRAMES * `NUM_LINES * total_pix * 16)/8;
		`endif
   `else
			localparam exp_byte_count = `NUM_FRAMES * `NUM_LINES * number_of_bytes; // 3*5*252 = 3780
   `endif
   
   reg        reset_n;
   wire       rst_n_i = reset_n;
   reg        pix_clk_i  = 0; 
   reg        byte_clk_i = 0;
   wire       byte_clk = byte_clk_i;
   reg        mon_en = 0;
   reg        start_vid = 0;
   reg        byte_log_en = 0;

  //below four are for the log file debug
   integer line_cnt  = 0;
   integer frame_cnt = 0;
   integer pixel_cnt = 0;
   integer testfail_cnt = 0;
   integer pix_count_tmp=0;
   integer pix_count=0;
   integer line_count=0;
   integer frame_count=0;
  
 //pavan - how delays are claculated?  
   integer txfr_delay = 100000/byteclk_period;
   integer wc_delay = number_of_bytes/((GEAR_16+1)*NUM_TX_LANE);

// `ifdef TX_DSI
   wire de_i ;
   wire hsync_i ;
   wire vsync_i ;
   
   wire [3:0] axis_tuser_i;
// `endif
// `ifdef TX_CSI2
    wire fv_i;
    wire lv_i;
    reg dvalid_i;
	
	wire axis_tvalid_i;
	
// `endif

   wire eof;
   //as per spec 10 pixels data input ports
   wire [PIX_WIDTH-1:0] pix_data9_i; //24 bit for RGB-888, 18 bit for RGB-666, 16 bit for RAW-16, 14 bit for RAW-14, 12 bit for RAW-12, 10 bit bus for RAW-10/YUV-420/YUV-422 10-bit, 8 bit bus for RAW-8/YUV-420/YUV-422 8-bit
   wire [PIX_WIDTH-1:0] pix_data8_i;
   wire [PIX_WIDTH-1:0] pix_data7_i;
   wire [PIX_WIDTH-1:0] pix_data6_i;
   wire [PIX_WIDTH-1:0] pix_data5_i;
   wire [PIX_WIDTH-1:0] pix_data4_i;
   wire [PIX_WIDTH-1:0] pix_data3_i;
   wire [PIX_WIDTH-1:0] pix_data2_i;
   wire [PIX_WIDTH-1:0] pix_data1_i;
   wire [PIX_WIDTH-1:0] pix_data0_i;
   
   wire [PIX_WIDTH*NUM_PIX_LANE-1:0] axis_tdata_i;

   reg [PIX_WIDTH-1:0] pix_data_9_buf;
   reg [PIX_WIDTH-1:0] pix_data_8_buf;
   reg [PIX_WIDTH-1:0] pix_data_7_buf;
   reg [PIX_WIDTH-1:0] pix_data_6_buf;
   reg [PIX_WIDTH-1:0] pix_data_5_buf;
   reg [PIX_WIDTH-1:0] pix_data_4_buf;
   reg [PIX_WIDTH-1:0] pix_data_3_buf;
   reg [PIX_WIDTH-1:0] pix_data_2_buf;
   reg [PIX_WIDTH-1:0] pix_data_1_buf;
   reg [PIX_WIDTH-1:0] pix_data_0_buf;

   // pavan - why do we need 12 bytes here?
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
  
// pavan - why ifded is commented as the signals are specific to either dsi or csi but not both  
// `ifdef TX_DSI
   wire vsync_start_o;
   wire vsync_end_o;
   wire hsync_start_o;
   wire hsync_end_o;
   wire vsync_start = vsync_start_o;
   wire vsync_end   = vsync_end_o;
   wire hsync_start = hsync_start_o;
   wire hsync_end   = hsync_end_o;
// `endif
// `ifdef TX_CSI2
   wire fv_start_o;
   wire fv_end_o;
   wire lv_start_o;
   wire lv_end_o;
   wire [5:0] data_type_o;    // Output data type
   wire fv_start = fv_start_o;
   wire fv_end   = fv_end_o;
   wire lv_start = lv_start_o;
   wire lv_end   = lv_end_o;
// `endif 

   wire fifo_overflow_o;
   wire fifo_underflow_o ;
   wire fifo_full_o ; 
   wire fifo_empty_o ;  
   integer fifo_overflow_counter=0;
   integer fifo_underflow_counter=0;

   wire odd_line;
   wire [5:0] data_type = data_type_o;    // Output data type
   
   wire c2d_ready_i = 1'b1;
   reg  txfr_en_i;     
   wire txfr_req_o;   
   wire txfr_req = txfr_req_o;
   
   wire axim_tvalid_o;
   wire [(NUM_TX_LANE*TX_GEAR)+24-1:0] axim_tdata_o;
   wire axim_tready_i;
   wire axis_tready_o;
   
   parameter apb_clock_period = 7500; //66.66 MHz clock freq
   reg apb_pclk_i;
   wire apb_presetn_i;
   reg apb_psel_i;
   reg apb_penable_i;
   reg apb_pwrite_i;
   reg [31:0]apb_paddr_i;
   reg [31:0]apb_pwdata_i;
   wire [31:0] apb_prdata_o;
   wire apb_pready_o;
   wire apb_pslverr_o;
   wire [1:0] vc_o;
   wire [15:0] wc_o;
   reg fifo_overflow=1'b0, fifo_underflow=1'b0;
   reg [31:0] vc_data_tmp=32'h0, wc_data_tmp=32'h0;
   reg apb_reg0_chk;
   reg apb_reg1_chk;
   
   integer apb_wr_ready_error_cnt=0;
   integer apb_rd_ready_error_cnt=0;
   integer wr_slv_err_cnt=0;
   integer apb_reg1_count=0;
   integer apb_addr_slverr_cnt=0;
    
   wire byte_en_o;
   wire [NUM_TX_LANE*TX_GEAR-1:0] byte_data_o;
   wire byte_en = byte_en_o;
   wire [63:0] byte_data = byte_data_o;
   //files for input and output data
   integer fileIn;
   integer fileOut;
   reg enable_write_log =1;
   reg [31:0] hsync_start_data_tmp;
   reg [31:0] hsync_end_data_tmp;
   reg [31:0] vsync_start_data_tmp;
   reg [31:0] vsync_end_data_tmp;
   integer sync_fault_count=0;
   //arrays with 3780 locations with 8 bit width for each location
   `ifdef RGB666
   parameter rgb666_input_bytes_per_pixel=12;
   parameter rgb666_output_bytes_per_pixel=9;
   parameter rgb666_input_array_size=(exp_byte_count/rgb666_output_bytes_per_pixel)*rgb666_input_bytes_per_pixel;
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [rgb666_input_array_size:1];
   `elsif RGB444
   parameter rgb444_input_bytes_per_pixel=32;
   parameter rgb444_output_bytes_per_pixel=8; //1pixel(12 bits) has 4 extra bits. so max 4 pixels have 2 extra bytes of padding
   parameter rgb444_input_array_size=(exp_byte_count/rgb444_output_bytes_per_pixel)*rgb444_input_bytes_per_pixel;
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [rgb444_input_array_size:1];
   `elsif RGB555
   parameter rgb555_input_bytes_per_pixel=25;
   parameter rgb555_output_bytes_per_pixel=8; //1pixel(15 bits) has 1 extra bit. so max 4 pixels have 4 extra bits of padding
   parameter rgb555_input_array_size=(exp_byte_count/rgb555_output_bytes_per_pixel)*rgb555_input_bytes_per_pixel;
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [rgb555_input_array_size:1];
   `elsif RAW14
   parameter raw14_input_bytes_per_pixel=10;
   parameter raw14_output_bytes_per_pixel=7;
   parameter raw14_input_array_size=(exp_byte_count/raw14_output_bytes_per_pixel)*raw14_input_bytes_per_pixel;
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [raw14_input_array_size:1];
   `elsif RAW10
   parameter raw10_1lane_input_bytes_per_pixel=8;
   parameter raw10_1lane_output_bytes_per_pixel=5;
   parameter raw10_1lane_input_array_size=(exp_byte_count/raw10_1lane_output_bytes_per_pixel)*raw10_1lane_input_bytes_per_pixel;
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [raw10_1lane_input_array_size:1];
   `elsif RAW12
	 `ifdef NUM_PIX_LANE_4
	 parameter raw12_4lane_input_bytes_per_pixel=8;
	 parameter raw12_4lane_output_bytes_per_pixel=6;
	 parameter raw12_4lane_input_array_size=(exp_byte_count/raw12_4lane_output_bytes_per_pixel)*raw12_4lane_input_bytes_per_pixel;
	 reg [7:0] log_out [exp_byte_count:1];
	 reg [7:0] log_in  [raw12_4lane_input_array_size:1];
	 `else
	 parameter raw12_1lane_input_bytes_per_pixel=4;
	 parameter raw12_1lane_output_bytes_per_pixel=3;
	 parameter raw12_1lane_input_array_size=(exp_byte_count/raw12_1lane_output_bytes_per_pixel)*raw12_1lane_input_bytes_per_pixel;
	 reg [7:0] log_out [exp_byte_count:1];
	 reg [7:0] log_in  [raw12_1lane_input_array_size:1];
	 `endif
   `elsif YUV420_10
   parameter yuv420_10_input_bytes_per_pixel=8;
   parameter yuv420_10_output_bytes_per_pixel=5;
   parameter yuv420_10_input_array_size=(exp_byte_count/yuv420_10_output_bytes_per_pixel)*yuv420_10_input_bytes_per_pixel;
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [yuv420_10_input_array_size:1];
   `elsif YUV422_10
   parameter yuv422_10_input_bytes_per_pixel=8;
   parameter yuv422_10_output_bytes_per_pixel=5;
   parameter yuv422_10_input_array_size=(exp_byte_count/yuv422_10_output_bytes_per_pixel)*yuv422_10_input_bytes_per_pixel;
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [yuv422_10_input_array_size:1];
   `else
   reg [7:0] log_out [exp_byte_count:1];
   reg [7:0] log_in  [exp_byte_count:1];
   `endif
   
   
   //axis_tuser_unused_bits
   `ifdef AXI_ENABLED
		assign axis_tuser_i[1:0] = 'b00;
   `elsif AXI4S_ONLY_ENABLED
		assign axis_tuser_i[1:0] = 'b00;
	`endif
		
   /*`ifdef AXI_ENABLED
		assign axis_tuser_i[1:0] = 'b00;
		if(DSI_FORMAT==1) begin
			assign axis_tvalid_i = de_i;
		end
		else begin
			assign axis_tvalid_i = axis_tuser_i[3];
		end
	`endif*/
   //check to make sure no sync pulse should start or end when payload data is enabled and payload dat is between the two sync pulses
   always@(posedge byte_clk_i) begin
	if(DSI_FORMAT==1) begin
	  `ifdef AXI_ENABLED
		if(hsync_start_o) begin
			hsync_start_data_tmp=axis_tdata_i;
		end
		if(hsync_end_o) begin
			hsync_end_data_tmp=axis_tdata_i;
		end
		if(vsync_start_o) begin
			vsync_start_data_tmp=axis_tdata_i;
		end
		if(vsync_end_o) begin
			vsync_end_data_tmp=axis_tdata_i;
		end
	  `elsif AXI4S_ONLY_ENABLED
		if(hsync_start_o) begin
			hsync_start_data_tmp=axis_tdata_i;
		end
		if(hsync_end_o) begin
			hsync_end_data_tmp=axis_tdata_i;
		end
		if(vsync_start_o) begin
			vsync_start_data_tmp=axis_tdata_i;
		end
		if(vsync_end_o) begin
			vsync_end_data_tmp=axis_tdata_i;
		end
	  `else
	    if(hsync_start_o) begin
			hsync_start_data_tmp=pix_data0_i;
		end
		if(hsync_end_o) begin
			hsync_end_data_tmp=pix_data0_i;
		end
		if(vsync_start_o) begin
			vsync_start_data_tmp=pix_data0_i;
		end
		if(vsync_end_o) begin
			vsync_end_data_tmp=pix_data0_i;
		end
	  `endif
	end
   end
   
   always@(posedge byte_clk_i) begin
	if(DSI_FORMAT==1) begin
		if(de_i) begin
			if((hsync_start_o==1) || (hsync_end_o==1) || (vsync_start_o==1) || (vsync_end_o==1)) begin
				sync_fault_count=sync_fault_count+1;
			end
			`ifdef AXI_ENABLED
				if((hsync_start_data_tmp==axis_tdata_i) || (hsync_end_data_tmp==axis_tdata_i) || (vsync_start_data_tmp==axis_tdata_i) || (vsync_end_data_tmp==axis_tdata_i)) begin
					sync_fault_count=sync_fault_count+1;
				end
			`elsif AXI4S_ONLY_ENABLED
				if((hsync_start_data_tmp==axis_tdata_i) || (hsync_end_data_tmp==axis_tdata_i) || (vsync_start_data_tmp==axis_tdata_i) || (vsync_end_data_tmp==axis_tdata_i)) begin
					sync_fault_count=sync_fault_count+1;
				end
			`else
				if((hsync_start_data_tmp==pix_data0_i) || (hsync_end_data_tmp==pix_data0_i) || (vsync_start_data_tmp==pix_data0_i) || (vsync_end_data_tmp==pix_data0_i)) begin
					sync_fault_count=sync_fault_count+1;
				end
			`endif
		end
	end
   end
   
   //check to make sure frame valid and line valid not asserting on same clock pulse
   if(DSI_FORMAT==0) begin
	`ifdef AXI_ENABLED
		always@(posedge axis_tuser_i[2] or negedge axis_tuser_i[2]) begin
			if(axis_tuser_i[3]==1) begin
				sync_fault_count=sync_fault_count+1;
			end
		end
	`elsif AXI4S_ONLY_ENABLED
		always@(posedge axis_tuser_i[2] or negedge axis_tuser_i[2]) begin
			if(axis_tuser_i[3]==1) begin
				sync_fault_count=sync_fault_count+1;
			end
		end
	`else
		always@(posedge fv_i or negedge fv_i) begin
			if(lv_i==1) begin
				sync_fault_count=sync_fault_count+1;
			end
		end
	`endif
   end
   
   if(DSI_FORMAT==0) begin
	always@(posedge lv_start_o or posedge lv_end_o) begin
		if((fv_start_o==1) || (fv_end_o==1)) begin
			sync_fault_count=sync_fault_count+1;
		end
	end
   end
   
   if(DSI_FORMAT==0) begin
	always@(posedge byte_clk_i) begin
		`ifdef AXI_ENABLED
			if(axim_tvalid_o==1) begin
				if((lv_start_o==1) || (lv_end_o==1) || (fv_start_o==1) || (fv_end_o==1)) begin
					sync_fault_count=sync_fault_count+1;
				end
			end
		`elsif AXI4M_ONLY_ENABLED
			if(axim_tvalid_o==1) begin
				if((lv_start_o==1) || (lv_end_o==1) || (fv_start_o==1) || (fv_end_o==1)) begin
					sync_fault_count=sync_fault_count+1;
				end
			end
		`elsif AXI4S_ONLY_ENABLED
			if(byte_en_o==1) begin
				if((lv_start_o==1) || (lv_end_o==1) || (fv_start_o==1) || (fv_end_o==1)) begin
					sync_fault_count=sync_fault_count+1;
				end
			end
		`else
			if(byte_en_o==1) begin
				if((lv_start_o==1) || (lv_end_o==1) || (fv_start_o==1) || (fv_end_o==1)) begin
					sync_fault_count=sync_fault_count+1;
				end
			end
		`endif
	end
   end
   
   always@(posedge pix_clk_i)
   begin
	if(fifo_overflow==1'b1) begin
		fifo_overflow_counter = fifo_overflow_counter+1;
	end
   end
   
   always@(posedge byte_clk_i)
   begin
	if(fifo_underflow==1'b1) begin
		fifo_underflow_counter = fifo_underflow_counter+1;
	end
   end
   
   
   `ifdef TRANS_TEST
   if (DSI_FORMAT == 1) begin

   initial begin 
      reset_n       = 1'b1;
      start_vid     = 1'b0;
//      `ifdef TXFR_SIG
        txfr_en_i       = 0;
//      `endif

      $display("%0t TEST START\n",$time);

      #(pixclk_period*70)  reset_n = 1'b0; 
      #(pixclk_period*100) reset_n = 1'b1;

      #100;

      @(posedge pix_clk_i);


         byte_log_en = 1;
         start_vid = 1;
         $display(" test_hsync_front_porch : %d \n", hfront_porch);
         $display(" test_hsync_width       : %d \n", hsync_pulse);
         $display(" test_hsync_back_porch  : %d \n", hback_porch);
		 `ifdef USER_DEFINED_PIXEL_COUNT
		 $display(" test_h_width           : %d \n", manual_pixels);
		 `else
		 $display(" test_h_width           : %d \n", act_pix);
		 `endif
         $display(" test_v_height          : %d \n", total_line);
         $display(" test_vsync_front_porch : %d \n", vfront_porch);
         $display(" test_vsync_width       : %d \n", vsync_pulse);
         $display(" test_vsync_back_porch  : %d \n", vback_porch);
         mon_en = 1;
         test_snow_pixel2byte_dsi_trans;   //capture dsi packet data and count number of frames
		 
      
      #100;
      // Below they are checking:
	  //1) checking the actual byte count from monitor(which is counted when byte_en is high) and comparing with the expected byte counted calculated above whose value is 3780 when they are mismatched they are incrementing the test fail count.
	  //2) They are reading input_data.log file into log_in array and checking first location of array if data is present or not. If data is x, they are incrementing the test fail count. If data is present in 1st location of log_in array, then they are starting data comparison.
	  //3) They are checking each location of log_in array and comparing with the same location of log_out array(loaded from output_data.log file). If any mismatches in any location, they are incrementing the test fail count and they are checking like that for all 3780 locations
      check_data; 
      if(sync_fault_count!==0) begin
		$display("SYNC FAULTS OCCURED %d TIMES",sync_fault_count);
	  end
	  else begin
	    $display("NO SYNC FAULTS OCCURED");
	  end	
	  if(fifo_overflow_counter!==0) begin
		$display("FIFO OVERFLOW OCCURED %d TIMES",fifo_overflow_counter);
	  end
	  else begin
	    $display("NO FIFO OVERFLOW OCCURED");
	  end
	  if(fifo_underflow_counter!==0) begin
		$display("FIFO UNDERFLOW OCCURED %d TIMES",fifo_underflow_counter);
	  end
	  else begin
	    $display("NO FIFO UNDERFLOW OCCURED");
	  end
      //final check: testfail_cnt should be 0 at the end of the test.
      if(testfail_cnt == 0) begin
        $display(" Test fail count : %d   \n", testfail_cnt);
        $display("-----------------------------------------------------");
        $display("----------------- SIMULATION PASSED -----------------");
        $display("-----------------------------------------------------");
      end else begin
        $display(" ERROR: Test fail count : %d   \n", testfail_cnt);
        //write testfail_cnt into any one log file, so that auto file comparisons will also fail.
        write_to_file("input_data.log", testfail_cnt);
        //write_to_file("output_data.log", testfail_cnt);
        $display("-----------------------------------------------------");
        $display("!!!!!!!!!!!!!!!!! SIMULATION FAILED !!!!!!!!!!!!!!!!!");
        $display("-----------------------------------------------------");
      end

      $display("%0t TEST END\n",$time);
      $finish;
        
   end

  end
  else begin
  
   initial begin                       
      reset_n       = 1'b1;
      start_vid     = 1'b0;
//      `ifdef TXFR_SIG
        txfr_en_i       = 0;
//      `endif
		dvalid_i      = 1'b1;

      $display("%0t TEST START\n",$time);
      #(pixclk_period*70)  reset_n = 1'b0; 
      #(pixclk_period*100) reset_n = 1'b1;
	  
      #100;
      @(posedge pix_clk_i);

         
         byte_log_en = 1;
         start_vid = 1;
         $display(" test_hsync_front_porch : %d \n", hfront_porch);
         $display(" test_hsync_width       : %d \n", hsync_pulse);
         $display(" test_hsync_back_porch  : %d \n", hback_porch);
         `ifdef USER_DEFINED_PIXEL_COUNT
		 $display(" test_h_width           : %d \n", manual_pixels);
		 `else
		 $display(" test_h_width           : %d \n", act_pix);
		 `endif
         $display(" test_v_height          : %d \n", total_line);
         $display(" test_vsync_front_porch : %d \n", vfront_porch);
         $display(" test_vsync_width       : %d \n", vsync_pulse);
         $display(" test_vsync_back_porch  : %d \n", vback_porch);
         mon_en = 1;
         test_snow_pixel2byte_csi2_trans;  //capture csi packet data and count number of frames
    
      
      #100;
	  // Below they are checking:
	  //1) checking the actual byte count from monitor(which is counted when byte_en is high) and comparing with the expected byte counted calculated above whose value is 3780 when they are mismatched they are incrementing the test fail count.
	  //2) They are reading input_data.log file into log_in array and checking first location of array if data is present or not. If data is x, they are incrementing the test fail count. If data is present in 1st location of log_in array, then they are starting data comparison.
	  //3) They are checking each location of log_in array and comparing with the same location of log_out array(loaded from output_data.log file). If any mismatches in any location, they are incrementing the test fail count and they are checking like that for all 3780 locations
      check_data;
	  if(sync_fault_count!==0) begin
		$display("SYNC FAULTS OCCURED %d TIMES",sync_fault_count);
	  end
	  else begin
	    $display("NO SYNC FAULTS OCCURED");
	  end	
	  if(fifo_overflow_counter!==0) begin
		$display("FIFO OVERFLOW OCCURED %d TIMES",fifo_overflow_counter);
	  end
	  else begin
	    $display("NO FIFO OVERFLOW OCCURED");
	  end
	  if(fifo_underflow_counter!==0) begin
		$display("FIFO UNDERFLOW OCCURED %d TIMES",fifo_underflow_counter);
	  end
	  else begin
	    $display("NO FIFO UNDERFLOW OCCURED");
	  end
      //final check: testfail_cnt should be 0 at the end of the test.
      if(testfail_cnt == 0) begin
        $display(" Test fail count : %d   \n", testfail_cnt);
        $display("-----------------------------------------------------");
        $display("----------------- SIMULATION PASSED -----------------");
        $display("-----------------------------------------------------");
      end else begin
        $display(" ERROR: Test fail count : %d   \n", testfail_cnt);
        $display("-----------------------------------------------------");
        $display("!!!!!!!!!!!!!!!!! SIMULATION FAILED !!!!!!!!!!!!!!!!!");
        $display("-----------------------------------------------------");
      end

      $display("%0t TEST END\n",$time);
      $finish;
        
   end
  end
  `endif

  //task details already mentioned above
  // Below they are checking:
  //1) checking the actual byte count from monitor(which is counted when byte_en is high) and comparing with the expected byte counted calculated above whose value is 3780 when they are mismatched they are incrementing the test fail count.
  //2) They are reading input_data.log file into log_in array and checking first location of array if data is present or not. If data is x, they are incrementing the test fail count. If data is present in 1st location of log_in array, then they are starting data comparison.
  //3) They are checking each location of log_in array and comparing with the same location of log_out array(loaded from output_data.log file). If any mismatches in any location, they are incrementing the test fail count and they are checking like that for all 3780 locations
  task check_data;
    integer actual_byte_count, i,j,k;
  begin
    actual_byte_count = byte_monitor.actual_byte_count;
	$display("exp byte count is %d and actual byte count from monitor is %d",exp_byte_count,actual_byte_count);
  
    if ( exp_byte_count!= actual_byte_count) begin 
      $display("---------------------------------------------");
      $display("*** E R R O R: Actual and Expected byte counts are not equal***");
      $display("**** I N F O : Actual byte Count is %0d", actual_byte_count);
      $display("**** I N F O : Expected byte Count is %0d", exp_byte_count);
      $display("-----------------------------------------------------");
      $display("!!!!!!!!!!!!!!!!! SIMULATION FAILED !!!!!!!!!!!!!!!!!");
      $display("-----------------------------------------------------");
      testfail_cnt = testfail_cnt + 1;
    end
	/*else if(sync_fault_count!=0) begin
		$display("SYNC FAULTS OCCURED");
	end*/
    //else begin
      $readmemb("input_data.log", log_in); //chnged from hex to binary read by pavan
      $readmemb("output_data.log", log_out); //chnged from hex to binary read by pavan
      
      if (log_in[1] === {8{1'bx}}) begin
        $display("---------------------------------------------");
        $display("---------------------------------------------");
        $display("##### received_data.log FILE IS EMPTY ##### ");
        $display("---------------------------------------------");
        $display("---------------------------------------------");
        testfail_cnt = testfail_cnt + 1;
      end
      else begin
        $display("---------------------------------------------");
        $display("---------------------------------------------");
        $display("##### DATA COMPARISON IS STARTED ##### ");
        $display("---------------------------------------------");
        $display("---------------------------------------------");
      end
	//code start by pavan
	`ifdef RGB666
	  i=1;
	  j=1;
	  k=1;
	  $display("The format selected is RGB666");
	  `ifdef USER_DEFINED_PIXEL_COUNT
	  $display("total pixels per line = %d",manual_pixels);  //added by pavan
	  `else
	  $display("total pixels per line = %d",total_pix);  //added by pavan
	  `endif
	  repeat(rgb666_input_array_size) begin
		if(i==13) begin
			i=1;
		end
		if(i==1) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==2) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==3) begin
			if(log_in[k]!==log_out[j][1:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j][1:0]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==4) begin
			if(log_in[k]!==log_out[j-1][7:2]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-1][7:2]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==5) begin
			if(log_in[k]!==log_out[j-1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-1]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==6) begin
			if(log_in[k]!==log_out[j-1][3:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-1][3:0]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==7) begin
			if(log_in[k]!==log_out[j-2][7:4]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-2][7:4]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==8) begin
			if(log_in[k]!==log_out[j-2]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-2]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==9) begin
			if(log_in[k]!==log_out[j-2][5:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-2][5:0]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==10) begin
			if(log_in[k]!==log_out[j-3][7:6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-3][7:6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==11) begin
			if(log_in[k]!==log_out[j-3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-3]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==12) begin
			if(log_in[k]!==log_out[j-3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-3]);
			end
			k=k+1;
			j=j-2;
			pix_count=pix_count+1;
		end
		if(pix_count==total_pix) begin  //144 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		i=i+1;
	  end
	`elsif RGB888
	  i = 1;
	  $display("The format selected is RGB888");
	  `ifdef USER_DEFINED_PIXEL_COUNT
	  $display("total pixels per line = %d",manual_pixels);  //added by pavan
	  `else
	  $display("total pixels per line = %d",total_pix);  //added by pavan
	  `endif
      repeat (actual_byte_count) begin
	    //code start by pavan
		pix_count_tmp=pix_count_tmp+1;
		if(pix_count_tmp==1) begin   
		  pix_count=pix_count+1;
		end
		if(pix_count_tmp==3) begin //3 bytes in 1 pixel
		  pix_count_tmp=0;
		end
		if(pix_count==total_pix) begin  //84 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		//code end by pavan
        if (log_in[i] !== log_out[i]) begin
          $display("%0dns ERROR : Expected and Received datas are not matching. Line%0d",$time, i);
          $display("       Expected  %h", log_in  [i]);
          $display("       Received  %h", log_out [i]);
          testfail_cnt = testfail_cnt + 1;
		  $display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
        end  
        i = i+1;
	  end
	 `elsif RGB444
	  i=1;
	  j=1;
	  k=1;
	  $display("The format selected is RGB444");
	  `ifdef USER_DEFINED_PIXEL_COUNT
	  $display("total pixels per line = %d",manual_pixels);  //added by pavan
	  `else
	  $display("total pixels per line = %d",total_pix);  //added by pavan
	  `endif
	  repeat(rgb444_input_array_size) begin
		if(i==33) begin
			i=1;
		end
		if(i==1) begin
			if(log_in[k]!==log_out[j][0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j][0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==2) begin
			if(log_in[k]!==log_out[j-1][4:1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-1][4:1]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==3) begin
			if(log_in[k]!==log_out[j-2][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-2][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==4) begin
			if(log_in[k]!==log_out[j-3][6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-3][6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==5) begin
			if(log_in[k][0]!==log_out[j-4][7]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k][0],log_out[j-4][7]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==6) begin
			if(log_in[k-1][3:1]!==log_out[j-4][2:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1][3:1],log_out[j-4][2:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==7) begin
			if(log_in[k-1]!==log_out[j-5][3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-5][3]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==8) begin
			if(log_in[k-1]!==log_out[j-6][7:4]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-6][7:4]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==9) begin
			if(log_in[k-1]!==log_out[j-6][0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-6][0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==10) begin
			if(log_in[k-1]!==log_out[j-7][4:1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-7][4:1]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==11) begin
			if(log_in[k-1]!==log_out[j-8][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-8][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==12) begin
			if(log_in[k-1]!==log_out[j-9][6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-9][6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==13) begin
			if(log_in[k-1][0]!==log_out[j-10][7]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1][0],log_out[j-10][7]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==14) begin
			if(log_in[k-2][3:1]!==log_out[j-10][2:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2][3:1],log_out[j-10][2:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==15) begin
			if(log_in[k-2]!==log_out[j-11][3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-11][3]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==16) begin
			if(log_in[k-2]!==log_out[j-12][7:4]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-12][7:4]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==17) begin
			if(log_in[k-2]!==log_out[j-12][0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-12][0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==18) begin
			if(log_in[k-2]!==log_out[j-13][4:1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-13][4:1]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==19) begin
			if(log_in[k-2]!==log_out[j-14][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-14][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==20) begin
			if(log_in[k-2]!==log_out[j-15][6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-15][6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==21) begin
			if(log_in[k-2][0]!==log_out[j-16][7]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2][0],log_out[j-16][7]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==22) begin
			if(log_in[k-3][3:1]!==log_out[j-16][2:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3][3:1],log_out[j-16][2:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==23) begin
			if(log_in[k-3]!==log_out[j-17][3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-17][3]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==24) begin
			if(log_in[k-3]!==log_out[j-18][7:4]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-18][7:4]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==25) begin
			if(log_in[k-3]!==log_out[j-18][0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-18][0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==26) begin
			if(log_in[k-3]!==log_out[j-19][4:1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-19][4:1]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==27) begin
			if(log_in[k-3]!==log_out[j-20][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-20][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==28) begin
			if(log_in[k-3]!==log_out[j-21][6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-21][6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==29) begin
			if(log_in[k-3][0]!==log_out[j-22][7]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3][0],log_out[j-22][7]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==30) begin
			if(log_in[k-4][3:1]!==log_out[j-22][2:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-4][3:1],log_out[j-22][2:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==31) begin
			if(log_in[k-4]!==log_out[j-23][3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-4],log_out[j-23][3]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==32) begin
			if(log_in[k-4]!==log_out[j-24][7:4]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-4],log_out[j-24][7:4]);
			end
			k=k-3;
			j=j-23;
			pix_count=pix_count+1;
		end
		if(pix_count==total_pix) begin  //144 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		i=i+1;
	  end
	  `elsif RGB555
	  i=1;
	  j=1;
	  k=1;
	  $display("The format selected is RGB555");
	  `ifdef USER_DEFINED_PIXEL_COUNT
	  $display("total pixels per line = %d",manual_pixels);  //added by pavan
	  `else
	  $display("total pixels per line = %d",total_pix);  //added by pavan
	  `endif
	  repeat(rgb555_input_array_size) begin
		if(i==26) begin
			i=1;
		end
		if(i==1) begin
			if(log_in[k]!==log_out[j][4:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j][4:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==2) begin
			if(log_in[k]!==log_out[j-1][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-1][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==3) begin
			if(log_in[k][1:0]!==log_out[j-2][7:6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k][1:0],log_out[j-2][7:6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==4) begin
			if(log_in[k-1][2]!==log_out[j-2][0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1][2],log_out[j-2][0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==5) begin
			if(log_in[k-1]!==log_out[j-3][2:1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-3][2:1]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==6) begin
			if(log_in[k-1]!==log_out[j-4][7:3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-4][7:3]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==7) begin
			if(log_in[k-1]!==log_out[j-4][0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-4][0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==8) begin
			if(log_in[k-1]!==log_out[j-5][4:1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-5][4:1]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==9) begin
			if(log_in[k-1]!==log_out[j-6][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1],log_out[j-6][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==10) begin
			if(log_in[k-1][1:0]!==log_out[j-7][7:6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-1][1:0],log_out[j-7][7:6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==11) begin
			if(log_in[k-2][3:2]!==log_out[j-7][1:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2][3:2],log_out[j-7][1:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==12) begin
			if(log_in[k-2]!==log_out[j-8][2]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-8][2]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==13) begin
			if(log_in[k-2]!==log_out[j-9][7:3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-9][7:3]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==14) begin
			if(log_in[k-2]!==log_out[j-9][1:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-9][1:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==15) begin
			if(log_in[k-2]!==log_out[j-10][4:2]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-10][4:2]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==16) begin
			if(log_in[k-2]!==log_out[j-11][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2],log_out[j-11][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==17) begin
			if(log_in[k-2][1:0]!==log_out[j-12][7:6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-2][1:0],log_out[j-12][7:6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==18) begin
			if(log_in[k-3][4:2]!==log_out[j-12][2:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3][4:2],log_out[j-12][2:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==19) begin
			if(log_in[k-3]!==log_out[j-13][7:3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-13][7:3]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==20) begin
			if(log_in[k-3]!==log_out[j-13][2:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-13][2:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==21) begin
			if(log_in[k-3]!==log_out[j-14][4:3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-14][4:3]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==22) begin
			if(log_in[k-3]!==log_out[j-15][5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3],log_out[j-15][5]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==23) begin
			if(log_in[k-3][1:0]!==log_out[j-16][7:6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-3][1:0],log_out[j-16][7:6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==24) begin
			if(log_in[k-4][5:2]!==log_out[j-16][3:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-4][5:2],log_out[j-16][3:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==25) begin
			if(log_in[k-4]!==log_out[j-17][7:4]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k-4],log_out[j-17][7:4]);
			end
			k=k-3;
			j=j-16;
			pix_count=pix_count+1;
		end
		if(pix_count==total_pix) begin  //144 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		i=i+1;
	  end
	  `elsif RGB565
	  i = 1;
	  $display("The format selected is RGB565");
	  `ifdef USER_DEFINED_PIXEL_COUNT
	  $display("total pixels per line = %d",manual_pixels);  //added by pavan
	  `else
	  $display("total pixels per line = %d",total_pix);  //added by pavan
	  `endif
      repeat (actual_byte_count) begin
	    //code start by pavan
		pix_count_tmp=pix_count_tmp+1;
		if(pix_count_tmp==1) begin   
		  pix_count=pix_count+1;
		end
		if(pix_count_tmp==2) begin //2 bytes in 1 pixel
		  pix_count_tmp=0;
		end
		if(pix_count==total_pix) begin  //122 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		//code end by pavan
        if (log_in[i] !== log_out[i]) begin
          $display("%0dns ERROR : Expected and Received datas are not matching. Line%0d",$time, i);
          $display("       Expected  %h", log_in  [i]);
          $display("       Received  %h", log_out [i]);
          testfail_cnt = testfail_cnt + 1;
		  $display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
        end  
        i = i+1;
	  end
	  /*i=1;
	  j=1;
	  k=1;
	  $display("The format selected is RGB565");
	  `ifdef USER_DEFINED_PIXEL_COUNT
	  $display("total pixels per line = %d",manual_pixels);  //added by pavan
	  `else
	  $display("total pixels per line = %d",total_pix);  //added by pavan
	  `endif
	  repeat(actual_byte_count) begin
		if(i==9) begin
			i=1;
		end
		if(i==1) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==2) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==3) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==4) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==5) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==6) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==7) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("padding bit mismatch. Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==8) begin
			if(log_in[k]!==log_out[j]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		if(pix_count==total_pix) begin  //144 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		i=i+1;
	  end*/
	 `elsif RAW8
		i = 1;
		$display("The format selected is RAW8");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
      repeat (actual_byte_count) begin
	    //code start by pavan   
		pix_count=pix_count+1;
		if(pix_count==total_pix) begin  //244 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
        if (log_in[i] !== log_out[i]) begin
          $display("%0dns ERROR : Expected and Received datas are not matching. Line%0d",$time, i);
          $display("       Expected  %h", log_in  [i]);
          $display("       Received  %h", log_out [i]);
          testfail_cnt = testfail_cnt + 1;
		  $display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
        end  
        i = i+1;
	  end
	  `elsif RAW14
		i=1;
		j=1;
		k=1;
		$display("The format selected is RAW14");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
	  repeat(raw14_input_array_size) begin
		if(i==11) begin
			i=1;
		end
		if(i==1) begin
			if(log_in[k]!==log_out[j+4][5:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j+4][5:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==2) begin
			if(log_in[k]!==log_out[j-1]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-1]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==3) begin
			if(log_in[k]!==log_out[j+2][7:6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j+2][7:6]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==4) begin
			if(log_in[k]!==log_out[j+2][3:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j+2][3:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==5) begin
			if(log_in[k]!==log_out[j-3]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-3]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==6) begin
			if(log_in[k]!==log_out[j][7:4]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j][7:4]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==7) begin
			if(log_in[k]!==log_out[j][1:0]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j][1:0]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==8) begin
			if(log_in[k]!==log_out[j-5]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-5]);
			end
			k=k+1;
			j=j+1;
			pix_count=pix_count+1;
		end
		else if(i==9) begin
			if(log_in[k]!==log_out[j-2][7:2]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-2][7:2]);
			end
			k=k+1;
			j=j+1;
		end
		else if(i==10) begin
			if(log_in[k]!==log_out[j-6]) begin
			    testfail_cnt = testfail_cnt + 1;
				$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
				$display("Expected is %h, Received is %h",log_in[k],log_out[j-6]);
			end
			k=k+1;
			j=j-2;
			pix_count=pix_count+1;
		end
		if(pix_count==total_pix) begin  //144 pixels in 1 line
		  line_count=line_count+1;
		  pix_count=0;
		end
		if(line_count==num_lines) begin
		  frame_count=frame_count+1;
		  line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		i=i+1;
	  end
	  `elsif RAW16
		i = 1;
		$display("The format selected is RAW16");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
		repeat (actual_byte_count) begin
			pix_count_tmp=pix_count_tmp+1;
			if(pix_count_tmp==1) begin   
			pix_count=pix_count+1;
			end
			if(pix_count_tmp==2) begin //2 bytes in 1 pixel
			pix_count_tmp=0;
			end
			if(pix_count==total_pix) begin  //124 pixels in 1 line
			line_count=line_count+1;
			pix_count=0;
			end
			if(line_count==num_lines) begin
			frame_count=frame_count+1;
			line_count=0;
			end
			if(frame_count==num_frames) begin
			$display("data comparison ended");
			end
			if (log_in[i] !== log_out[i]) begin
			$display("%0dns ERROR : Expected and Received datas are not matching. Line%0d",$time, i);
			$display("       Expected  %h", log_in  [i]);
			$display("       Received  %h", log_out [i]);
			testfail_cnt = testfail_cnt + 1;
			$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
			end  
			i = i+1;
		end
	  `elsif RAW10
		i=1;
		j=1;
		k=1;
		$display("The format selected is RAW10");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
		repeat(raw10_1lane_input_array_size) begin
			if(i==9) begin
				i=1;
			end
			if(i==1) begin
				if(log_in[k]!==log_out[j+4][1:0]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+4][1:0]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==2) begin
				if(log_in[k]!==log_out[j-1]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-1]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==3) begin
				if(log_in[k]!==log_out[j+2][3:2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+2][3:2]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==4) begin
				if(log_in[k]!==log_out[j-2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==5) begin
				if(log_in[k]!==log_out[j][5:4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j][5:4]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==6) begin
				if(log_in[k]!==log_out[j-3]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-3]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==7) begin
				if(log_in[k]!==log_out[j-2][7:6]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2][7:6]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==8) begin
				if(log_in[k]!==log_out[j-4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-4]);
				end
				k=k+1;
				j=j-2;
				pix_count=pix_count+1;
			end
			if(pix_count==total_pix) begin  //144 pixels in 1 line
				line_count=line_count+1;
				pix_count=0;
			end
			if(line_count==num_lines) begin
				frame_count=frame_count+1;
				line_count=0;
			end
			if(frame_count==num_frames) begin
				$display("data comparison ended");
			end
			i=i+1;
		end
	  `elsif RAW12
		`ifdef NUM_PIX_LANE_4
		i=1;
		j=1;
		k=1;
		$display("The format selected is RAW12- 4 pix lane");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
		repeat(raw12_4lane_input_array_size) begin
			if(i==9) begin
				i=1;
			end
			if(i==1) begin
				if(log_in[k]!==log_out[j+2][3:0]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+2][3:0]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==2) begin
				if(log_in[k]!==log_out[j-1]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-1]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==3) begin
				if(log_in[k]!==log_out[j][7:4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j][7:4]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==4) begin
				if(log_in[k]!==log_out[j-2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==5) begin
				if(log_in[k]!==log_out[j+1][3:0]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+1][3:0]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==6) begin
				if(log_in[k]!==log_out[j-2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==7) begin
				if(log_in[k]!==log_out[j-1][7:4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-1][7:4]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==8) begin
				if(log_in[k]!==log_out[j-3]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-3]);
				end
				k=k+1;
				j=j-1;
				pix_count=pix_count+1;
			end
			if(pix_count==total_pix) begin  //144 pixels in 1 line
				line_count=line_count+1;
				pix_count=0;
			end
			if(line_count==num_lines) begin
				frame_count=frame_count+1;
				line_count=0;
			end
			if(frame_count==num_frames) begin
				$display("data comparison ended");
			end
			i=i+1;
		end
		`else
		i=1;
		j=1;
		k=1;
		$display("The format selected is RAW12");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
		repeat(raw12_1lane_input_array_size) begin
			if(i==5) begin
				i=1;
			end
			if(i==1) begin
				if(log_in[k]!==log_out[j+2][3:0]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+2][3:0]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==2) begin
				if(log_in[k]!==log_out[j-1]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-1]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==3) begin
				if(log_in[k]!==log_out[j][7:4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j][7:4]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==4) begin
				if(log_in[k]!==log_out[j-2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2]);
				end
				k=k+1;
				pix_count=pix_count+1;
			end
			if(pix_count==total_pix) begin  //168 pixels in 1 line
				line_count=line_count+1;
				pix_count=0;
			end
			if(line_count==num_lines) begin
				frame_count=frame_count+1;
				line_count=0;
			end
			if(frame_count==num_frames) begin
				$display("data comparison ended");
			end
			i=i+1;
		end
		`endif
	  `elsif YUV420_8
	  i=1;
	  $display("The format selected is YUV420_8");
	  `ifdef USER_DEFINED_PIXEL_COUNT
	  $display("total pixels per line = %d",manual_pixels);  //added by pavan
	  `else
	  $display("total pixels per line = %d",total_pix);  //added by pavan
	  `endif
	  repeat(actual_byte_count) begin
		if(log_in[i]!==log_out[i]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[i],log_out[i]);
		end
		pix_count=pix_count+1;
		if(pix_count==total_pix) begin  //244 pixels in 1 line
			line_count=line_count+1;
			pix_count=0;
		end
		if(line_count==num_lines) begin
			frame_count=frame_count+1;
			line_count=0;
		end
		if(frame_count==num_frames) begin
			$display("data comparison ended");
		end
		i=i+1;
	  end
	  `elsif YUV420_10
		i=1;
		j=1;
		k=1;
		$display("The format selected is YUV420_10");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
		repeat(yuv420_10_input_array_size) begin
			if(i==9) begin
				i=1;
			end
			if(i==1) begin
				if(log_in[k]!==log_out[j+4][1:0]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+4][1:0]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==2) begin
				if(log_in[k]!==log_out[j-1]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-1]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==3) begin
				if(log_in[k]!==log_out[j+2][3:2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+2][3:2]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==4) begin
				if(log_in[k]!==log_out[j-2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==5) begin
				if(log_in[k]!==log_out[j][5:4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j][5:4]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==6) begin
				if(log_in[k]!==log_out[j-3]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-3]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==7) begin
				if(log_in[k]!==log_out[j-2][7:6]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2][7:6]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==8) begin
				if(log_in[k]!==log_out[j-4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-4]);
				end
				k=k+1;
				j=j-2;
				pix_count=pix_count+1;
			end
			if(pix_count==total_pix) begin  //208 pixels in 1 line
				line_count=line_count+1;
				pix_count=0;
			end
			if(line_count==num_lines) begin
				frame_count=frame_count+1;
				line_count=0;
			end
			if(frame_count==num_frames) begin
				$display("data comparison ended");
			end
			i=i+1;
		end
		`elsif YUV422_8
		i=1;
		$display("The format selected is YUV422_8");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
		repeat(actual_byte_count) begin
			if(log_in[i]!==log_out[i]) begin
						testfail_cnt = testfail_cnt + 1;
						$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
						$display("Expected is %h, Received is %h",log_in[i],log_out[i]);
			end
			pix_count=pix_count+1;
			if(pix_count==total_pix) begin  //244 pixels in 1 line
				line_count=line_count+1;
				pix_count=0;
			end
			if(line_count==num_lines) begin
				frame_count=frame_count+1;
				line_count=0;
			end
			if(frame_count==num_frames) begin
				$display("data comparison ended");
			end
			i=i+1;
	    end
	  `elsif YUV422_10
		i=1;
		j=1;
		k=1;
		$display("The format selected is YUV422_10");
		`ifdef USER_DEFINED_PIXEL_COUNT
		$display("total pixels per line = %d",manual_pixels);  //added by pavan
		`else
		$display("total pixels per line = %d",total_pix);  //added by pavan
		`endif
		repeat(yuv422_10_input_array_size) begin
			if(i==9) begin
				i=1;
			end
			if(i==1) begin
				if(log_in[k]!==log_out[j+4][1:0]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+4][1:0]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==2) begin
				if(log_in[k]!==log_out[j-1]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-1]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==3) begin
				if(log_in[k]!==log_out[j+2][3:2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j+2][3:2]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==4) begin
				if(log_in[k]!==log_out[j-2]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==5) begin
				if(log_in[k]!==log_out[j][5:4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j][5:4]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==6) begin
				if(log_in[k]!==log_out[j-3]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-3]);
				end
				k=k+1;
				j=j+1;
				pix_count=pix_count+1;
			end
			if(i==7) begin
				if(log_in[k]!==log_out[j-2][7:6]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-2][7:6]);
				end
				k=k+1;
				j=j+1;
			end
			if(i==8) begin
				if(log_in[k]!==log_out[j-4]) begin
					testfail_cnt = testfail_cnt + 1;
					$display("Failed in %d pixel number , %d line number , %d frame number",pix_count,line_count,frame_count);
					$display("Expected is %h, Received is %h",log_in[k],log_out[j-4]);
				end
				k=k+1;
				j=j-2;
				pix_count=pix_count+1;
			end
			if(pix_count==total_pix) begin  //208 pixels in 1 line
				line_count=line_count+1;
				pix_count=0;
			end
			if(line_count==num_lines) begin
				frame_count=frame_count+1;
				line_count=0;
			end
			if(frame_count==num_frames) begin
				$display("data comparison ended");
			end
			i=i+1;
		end
	  `else
	  i = 1;
      repeat (actual_byte_count) begin
        if (log_in[i] !== log_out[i]) begin
          $display("%0dns ERROR : Expected and Received datas are not matching. Line%0d",$time, i);
          $display("       Expected  %h", log_in  [i]);
          $display("       Received  %h", log_out [i]);
          testfail_cnt = testfail_cnt + 1;
        end  
        i = i+1;
      end
	  `endif
	  
	//code end by pavan
    //end 
  end
  endtask
	
	`ifdef DSI_RESET_TEST
	initial
	begin
		forever begin
			@(posedge byte_clk_i);
			if(reset_n==1'b0) begin
				test_snow_pixel2byte_dsi_reset;
			end
		end
	end
	`endif
	
	`ifdef CSI2_RESET_TEST
	initial
	begin
		forever begin
			@(posedge byte_clk_i);
			if(reset_n==1'b0) begin
				test_snow_pixel2byte_csi2_reset;
			end
		end
	end
	`endif
	
	`ifdef DSI_RESET_TEST
	initial
	begin
		reset_n       = 1'b1;
		start_vid     = 1'b0;
		txfr_en_i       = 0;
		$display("%0t RESET TEST START\n",$time);
		#(pixclk_period*70)  reset_n = 1'b0; 
		#(pixclk_period*100) reset_n = 1'b1;
		$display($time, " Output ports reset value checking done. ");
		if(testfail_cnt == 0) begin
				$display(" Test fail count : %d   \n", testfail_cnt);
				$display("-----------------------------------------------------");
				$display("***************** RESET TEST PASSED *****************");
				$display("-----------------------------------------------------");
		end else begin
				$display(" ERROR: Test fail count : %d   \n", testfail_cnt);
				$display("-----------------------------------------------------");
				$display("***************** RESET TEST FAILED *****************");
				$display("-----------------------------------------------------");
		end

		$display("%0t RESET TEST END\n",$time);
	end
	`elsif CSI2_RESET_TEST
	initial
	begin
		reset_n       = 1'b1;
		start_vid     = 1'b0;
		txfr_en_i       = 0;
		$display("%0t RESET TEST START\n",$time);
		#(pixclk_period*70)  reset_n = 1'b0; 
		#(pixclk_period*100) reset_n = 1'b1;
		$display($time, " Output ports reset value checking done. ");
		if(testfail_cnt == 0) begin
				$display(" Test fail count : %d   \n", testfail_cnt);
				$display("-----------------------------------------------------");
				$display("***************** RESET TEST PASSED *****************");
				$display("-----------------------------------------------------");
		end else begin
				$display(" ERROR: Test fail count : %d   \n", testfail_cnt);
				$display("-----------------------------------------------------");
				$display("***************** RESET TEST FAILED *****************");
				$display("-----------------------------------------------------");
		end

		$display("%0t RESET TEST END\n",$time);
	end
	`endif
  
  // Stop video generation after frame cnt reached num_frames
   initial begin
      wait(frame_cnt == num_frames)
      `ifdef TX_DSI
		`ifdef AXI_ENABLED
			@(negedge axis_tuser_i[3]);
		`elsif AXI4S_ONLY_ENABLED
			@(negedge axis_tuser_i[3]);
		`else
			@(negedge vsync_i);
		`endif
      `endif
      start_vid = 0;
      $display($time," Video generation stopped \n");
   end

   //task to enter any data(example - test fail count) into any file(example - input_data.log)
   task write_to_file (input [1024*8-1:0] str_in, input [7:0] data);
      integer filedesc;
      if(byte_log_en == 1)
      begin
         filedesc = $fopen(str_in,"a");
         $fwrite(filedesc, "%d\n", data);
         $fclose(filedesc);
      end
   endtask
   
   //task to enter the vsync and hsync signal details into any file
   task write_vh (input [1024*8-1:0] str_in, input vsyn, input hsyn);
      integer filedesc;
      if(byte_log_en == 1)
      begin
         filedesc = $fopen(str_in,"a");
         $fwrite(filedesc, "VSYNC: %1d | HSYNC: %1d\n", vsyn, hsyn);
         $fclose(filedesc);
      end
   endtask

  if (DSI_FORMAT == 1) begin
    //enabling the txfr_en signal after the txfr_delay which is calculated above when only txfr_req and hsync is high. txfr_en is disabled after enabling it only after 4 byte_clk cycles
    initial begin
       forever begin
		  `ifdef AXI_ENABLED
			@(posedge axis_tuser_i[2]);
		  `elsif AXI4S_ONLY_ENABLED
			@(posedge axis_tuser_i[2]);
		  `else
			@(posedge hsync_i);
		  `endif
          @(posedge txfr_req_o);
          repeat (txfr_delay) begin
             @(posedge byte_clk_i);
          end
          @(posedge byte_clk_i);
          txfr_en_i <= 1;     
          repeat (4) begin
             @(posedge byte_clk_i);
          end  
          txfr_en_i <= 0;
       end
    end
    
	//enabling the txfr_en signal after the txfr_delay which is calculated above when only txfr_req and de is high. txfr_en is disabled after enabling it only after wc_delay+4 byte_clk cycles
    initial begin
       forever begin
          @(posedge de_i);
          @(posedge txfr_req_o);
          repeat (txfr_delay) begin
             @(posedge byte_clk_i);
          end
          txfr_en_i <= 1; 
          repeat (wc_delay+4) begin
             @(posedge byte_clk_i);
          end  
          txfr_en_i <= 0;
       end
    end
  
  end
  else begin
    //enabling the txfr_en signal after the txfr_delay which is calculated above when only txfr_req and fv is high. txfr_en is disabled after enabling it only after 4 byte_clk cycles
    initial begin
       forever begin
	      `ifdef AXI_ENABLED
			@(axis_tuser_i[2]);
		  `elsif AXI4S_ONLY_ENABLED
			@(axis_tuser_i[2]);
		  `else
		    @(fv_i);
		  `endif
          @(posedge txfr_req_o);
          @(negedge txfr_req_o);
          txfr_en_i <= 1; 
          repeat (4) begin
             @(posedge byte_clk_i);
          end  
          txfr_en_i <= 0;
       end
    end
	//enabling the txfr_en signal after the txfr_delay which is calculated above when only txfr_req and lv is high. txfr_en is disabled after enabling it only after wc_delay+5 byte_clk cycles for NUM_PIX_LANE2 and after wc_delay+4 byte_clk cycles for any other number of pixel lanes
    initial begin
       forever begin
          `ifdef AXI_ENABLED
			@(axis_tuser_i[3]);
		  `elsif AXI4S_ONLY_ENABLED
			@(axis_tuser_i[3]);
		  `else
		    @(lv_i);
		  `endif
          @(posedge txfr_req_o);
//          @(negedge txfr_req_o);
          repeat (txfr_delay) begin
             @(posedge byte_clk_i);
          end
          txfr_en_i <= 1; 
          `ifdef NUM_PIX_LANE_2
          repeat (wc_delay+85) begin
          `else
		  repeat (wc_delay+84) begin
          `endif
             @(posedge byte_clk_i);
          end
          txfr_en_i <= 0;
       end
    end
  end
  
  //generating pix_clk
  initial begin
      pix_clk_i = 1;
      forever begin
         #pixclk_period pix_clk_i = ~pix_clk_i;
      end
   end

   //generating byte_clk
   initial begin
      byte_clk_i = 1;
      forever begin
         #byteclk_period byte_clk_i = ~byte_clk_i;
      end
   end
   
   initial begin
      apb_pclk_i = 1;
      forever begin
         #apb_clock_period apb_pclk_i = ~apb_pclk_i;
      end
   end
   
    //enabling the writing of input and output log files
    initial begin
        if(enable_write_log == 1) begin
            fileOut  = $fopen("output_data.log","w");
            $fclose(fileOut);

            fileIn = $fopen("input_data.log","w");
            $fclose(fileIn);
        end
    end
	
	assign apb_presetn_i = reset_n;
		
//APB TESTS START
//TEST1: APB RESET TEST	
`ifdef APB_RESET_TEST
	initial
	begin
	    apb_paddr_i=32'h4;
		apb_psel_i=1'b1;
		apb_penable_i=1'b1;
		apb_pwrite_i=1'b0;
		wait(apb_presetn_i==1'b0);
		repeat(3)@(posedge apb_pclk_i) apb_pwrite_i=1'b0;
		apb_pwrite_i=1'b1;
		apb_pwdata_i=32'h12345678;
		if(testfail_cnt==0) begin
		$display("***************APB RESET TEST PASSED***************");
		end
		else begin
		$display("***************APB RESET TEST FAILED***************");
		end
	end
	
	initial
	begin
		forever begin
			@(posedge apb_pclk_i);
			if(apb_presetn_i==1'b0) begin
				test_snow_pixel2byte_apb_reset;
			end
		end
	end
`endif

//TEST2: APB REG1 SINGLE WRITE AND READ TEST
`ifdef APB_SINGLE_WR_RD_REG1_TEST
task apb_wr_reg1_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b1;
	apb_paddr_i=32'h4;
	apb_pwdata_i=$random;
end
endtask

task apb_rd_reg1_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=32'h4;
end
endtask

initial
begin
	apb_psel_i=1'b0;
	apb_penable_i=1'b0;
	apb_pwrite_i=1'b0;
	//wait(eof==1'b1);
	#(pixclk_period*180);
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_wr_reg1_tx;
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_rd_reg1_tx;
end
`endif

//TEST3: APB REG1 MULTI WRITE READ TEST
`ifdef APB_MULTI_WR_RD_REG1_TEST
task apb_wr_reg1_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b1;
	apb_paddr_i=32'h4;
	apb_pwdata_i=$random;
end
endtask

task apb_rd_reg1_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=32'h4;
end
endtask

initial
begin
	apb_psel_i=1'b0;
	apb_penable_i=1'b0;
	apb_pwrite_i=1'b0;
	//wait(eof==1'b1);
	#(pixclk_period*180);
	repeat(3)@(posedge apb_pclk_i) apb_wr_reg1_tx;
	repeat(2)@(posedge apb_pclk_i) apb_rd_reg1_tx;
	repeat(2)@(posedge apb_pclk_i) apb_psel_i=1'b0;
	repeat(1)@(posedge apb_pclk_i) apb_wr_reg1_tx;
	repeat(2)@(posedge apb_pclk_i) apb_penable_i=1'b0;
	repeat(1)@(posedge apb_pclk_i) apb_wr_reg1_tx;
	repeat(1)@(posedge apb_pclk_i) apb_rd_reg1_tx;	
	repeat(1)@(posedge apb_pclk_i) apb_wr_reg1_tx;
end
`endif

//TEST4: APB REG0 SINGLE WRITE AND READ TEST
`ifdef APB_SINGLE_WR_RD_REG0_TEST
task apb_wr_reg0_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b1;
	apb_paddr_i=32'h0;
	apb_pwdata_i=$random;
end
endtask

task apb_rd_reg0_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=32'h0;
end
endtask

initial
begin
	apb_psel_i=1'b0;
	apb_penable_i=1'b0;
	apb_pwrite_i=1'b0;
	//wait(eof==1'b1);
	#(pixclk_period*180);
	repeat(1)@(posedge apb_pclk_i) apb_rd_reg0_tx;
	repeat(1)@(posedge apb_pclk_i) apb_penable_i=1'b0;
	repeat(1)@(posedge apb_pclk_i) apb_wr_reg0_tx;
	
end
`endif

//TEST5: APB REG0 MULTI WRITE READ TEST
`ifdef APB_MULTI_WR_RD_REG0_TEST
task apb_wr_reg0_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b1;
	apb_paddr_i=32'h0;
	apb_pwdata_i=$random;
end
endtask

task apb_rd_reg0_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=32'h0;
end
endtask

initial
begin
	apb_psel_i=1'b0;
	apb_penable_i=1'b0;
	apb_pwrite_i=1'b0;
	//wait(eof==1'b1);
	#(pixclk_period*180);
	repeat(3)@(posedge apb_pclk_i) apb_wr_reg0_tx;
	repeat(2)@(posedge apb_pclk_i) apb_rd_reg0_tx;
	repeat(2)@(posedge apb_pclk_i) apb_psel_i=1'b0;
	repeat(1)@(posedge apb_pclk_i) apb_wr_reg0_tx;
	repeat(2)@(posedge apb_pclk_i) apb_penable_i=1'b0;
	repeat(1)@(posedge apb_pclk_i) apb_wr_reg0_tx;
	repeat(1)@(posedge apb_pclk_i) apb_rd_reg0_tx;	
	repeat(1)@(posedge apb_pclk_i) apb_wr_reg0_tx;
	apb_rd_reg0_tx;
end
`endif

//TEST6: APB WRITE ONCE TO REG1 AT START OF EACH FRAME AND READ FIFO STATUS FROM REG0 REMAINING ALL TIME
`ifdef APB_P2B_COMPLETE_TXN_TEST
task apb_wr_vc_wc_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b1;
	apb_paddr_i=32'h4;
	apb_pwdata_i=$random;
end
endtask

task apb_rd_vc_wc_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=32'h4;
end
endtask

task apb_rd_fifo_status_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=32'h0;
end
endtask

task apb_deassert;
begin
	apb_psel_i=1'b0;
	apb_penable_i=1'b0;
end
endtask

always@(negedge eof)
begin
	@(posedge apb_pclk_i);
	if(apb_presetn_i==1'b1)
	begin
		apb_reg1_count=apb_reg1_count+1;
		apb_wr_vc_wc_tx;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
		apb_deassert;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
		apb_rd_vc_wc_tx;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
		apb_deassert;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
	end
end

initial
begin
	#(pixclk_period*180);
	if(apb_presetn_i==1'b1)
	begin
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
		apb_wr_vc_wc_tx;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
		apb_deassert;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
		apb_rd_vc_wc_tx;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
		apb_deassert;
		@(posedge apb_pclk_i);
		apb_reg1_count=apb_reg1_count+1;
	end
end

always@(posedge apb_pclk_i)
begin
	if(apb_reg1_count==5)
	begin
		apb_reg1_count=0;
	end
end

always@(posedge apb_pclk_i)
begin
	if(apb_reg1_count==0)
	begin
		apb_rd_fifo_status_tx;
	end
end	

always@(posedge apb_pclk_i)
begin
	if(apb_presetn_i==1'b0)
	begin
		apb_psel_i=1'b0;
		apb_penable_i=1'b0;
	end
end
`endif

//TEST7: CHECK SLAVE ADDRESS DECODING ERROR FOR SINGLE TXN
`ifdef APB_SINGLE_ADDR_SLAVE_ERROR_TEST
task apb_wr_reg1_error_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b1;
	apb_paddr_i=32'h2;
	apb_pwdata_i=$random;
end
endtask

task apb_rd_reg1_error_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=32'h2;
end
endtask

initial
begin
	apb_psel_i=1'b0;
	apb_penable_i=1'b0;
	apb_pwrite_i=1'b0;
	//wait(eof==1'b1);
	#(pixclk_period*180);
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_wr_reg1_error_tx;
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_rd_reg1_error_tx;
end
`endif

//TEST8: CHECK SLAVE ADDRESS DECODING ERROR FOR MULTIPLE TXNS
`ifdef APB_MULTI_ADDR_SLAVE_ERROR_TEST
task apb_wr_error_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b1;
	apb_paddr_i=$urandom_range(0,5);
	apb_pwdata_i=$random;
end
endtask

task apb_rd_error_tx;
begin
	apb_psel_i=1'b1;
	apb_penable_i=1'b1;
	apb_pwrite_i=1'b0;
	apb_paddr_i=$urandom_range(0,5);
end
endtask

initial
begin
	apb_psel_i=1'b0;
	apb_penable_i=1'b0;
	apb_pwrite_i=1'b0;
	#(pixclk_period*180);
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_wr_error_tx;
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_wr_error_tx;
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_rd_error_tx;
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_wr_error_tx;
	@(posedge apb_pclk_i);
	@(posedge apb_pclk_i);
	apb_rd_error_tx;
end
`endif
	
//APB CHECKS START
always@(posedge apb_pclk_i) begin
	//check1: checks for output ready assertion when read conditions are met 
	if(apb_pwrite_i == 1'b0 && apb_penable_i == 1'b1 && apb_psel_i == 1'b1) begin
		if(apb_pready_o !== 1'b1) begin
			$display("ERROR: At time %t, READ: APB output ready not asserting as per protocol",$time);
			apb_rd_ready_error_cnt = apb_rd_ready_error_cnt+1;
		end
	end
	
	//check2: checks for output ready assertion when write conditions are met
	if(apb_pwrite_i == 1'b1 && apb_penable_i == 1'b1 && apb_psel_i == 1'b1) begin
		if(apb_pready_o !== 1'b1) begin
			$display("ERROR: At time %t, WRITE: APB output ready not asserting as per protocol",$time);
			apb_wr_ready_error_cnt = apb_wr_ready_error_cnt+1;
			wr_slv_err_cnt = wr_slv_err_cnt+1;
		end
	end
	
	//check3: checks for output read data, when read conditions are met and when output ready is asserted
	//check4: checks for slave error assertion when output data is 'x' or 'z' or '0'
	if(apb_pwrite_i == 1'b0 && apb_penable_i == 1'b1 && apb_psel_i == 1'b1 && apb_pready_o == 1'b1) begin
		if(apb_prdata_o == 32'bx) begin
			$display("ERROR: At time %t, READ: APB output data is unknown",$time);
			if(apb_pslverr_o !== 1'b1) begin
				$display("ERROR: At time %t, READ: slave error response not asserted when output data is unknown",$time);
			end
		end
		else if(apb_prdata_o == 32'bz) begin
			$display("ERROR: At time %t, READ: APB output data is high impedance",$time);
			if(apb_pslverr_o !== 1'b1) begin
				$display("ERROR: At time %t, READ: slave error response not asserted when output data is high impedance",$time);
			end
		end
	end
end

//check5: checks for apb slave error assertion at next clock pulse of when ready is low even when enable,sel,write are high(write_transfer)
initial
begin
	if(wr_slv_err_cnt !== 1'b0) begin
		@(posedge apb_pclk_i);
		if(apb_pslverr_o !== 1'b1) begin
			$display("ERROR: At time %t, WRITE: slave error response not asserted as per protocol",$time);
		end
		else begin
			wr_slv_err_cnt=0;
		end
	end
end

//check6: checks for slave error when addr on the bus is other than 4(reg1) in write txn
always@(posedge apb_pclk_i)
begin
	if(apb_presetn_i) 
	begin
		if(apb_psel_i==1'b1 && apb_penable_i==1'b1 && apb_pwrite_i==1'b1)
		begin
			if((apb_paddr_i !== 32'h4) && (apb_paddr_i !== 32'h0) )
			begin
				//apb_addr_slverr_cnt = apb_addr_slverr_cnt+1;
				if(apb_pslverr_o!==1'b1)
				begin
					apb_addr_slverr_cnt = apb_addr_slverr_cnt+1;
					$display("ERROR: At time %t, WRITE: APB SLAVE ERROR NOT ASSERTED WHEN ADDRESS IS INVALID",$time);
				end
			end
		end
	end
end

//check7: checks for slave error when addr on the bus is other than 0(reg0) & 4(reg1) in read txn	
always@(posedge apb_pclk_i)
begin
	if(apb_psel_i==1'b1 && apb_penable_i==1'b1 && apb_pwrite_i==1'b0)
	begin
		if((apb_paddr_i !== 32'h4) && (apb_paddr_i !== 32'h0))
		begin
			//apb_addr_slverr_cnt = apb_addr_slverr_cnt+1;
			if(apb_pslverr_o!==1'b1)
			begin
				apb_addr_slverr_cnt = apb_addr_slverr_cnt+1;
				$display("ERROR: At time %t, READ: APB SLAVE ERROR NOT ASSERTED WHEN ADDRESS IS INVALID",$time);
			end
		end
	end
end


//APB CHECKS END

	
   //This is to generate and drive the pixel data
   //Common driver for both DSI and CSI2
   vid_timing_gen_driver #(
      .WORD_WIDTH             		(PIX_WIDTH),
	  .NUM_LANE                     (NUM_PIX_LANE),
	  .DSI_FORMAT					(DSI_FORMAT),
      .test_hsync_front_porch 		(hfront_porch),
      .test_hsync_width       		(hsync_pulse),
      .test_hsync_back_porch  		(hback_porch),
	  `ifdef USER_DEFINED_PIXEL_COUNT
      .test_h_width           		(manual_pixels),
	  `else
	  .test_h_width           		(act_pix),
	  `endif
      .test_v_height          		(total_line),
      .test_vsync_front_porch 		(vfront_porch),
      .test_vsync_width       		(vsync_pulse),
      .test_vsync_back_porch  		(vback_porch)
	) I_vid_timing_gen_driver 		
	(
	.clk                  			(pix_clk_i),
	.reset                			(~reset_n),
	.vid_cntl_tgen_active 			(start_vid),
	.byte_log_en          			(byte_log_en),
	`ifdef TX_DSI
		`ifdef AXI_ENABLED
			.tgen_vid_hsync       	(axis_tuser_i[2]),
			.tgen_vid_vsync       	(axis_tuser_i[3]),
		`elsif AXI4S_ONLY_ENABLED
			.tgen_vid_hsync       	(axis_tuser_i[2]),
			.tgen_vid_vsync       	(axis_tuser_i[3]),
		`else
			.tgen_vid_hsync       	(hsync_i),
			.tgen_vid_vsync       	(vsync_i),
		`endif
	.tgen_vid_de          			(de_i),
	`endif
	`ifdef TX_CSI2
		`ifdef AXI_ENABLED
			.tgen_vid_fv          	(axis_tuser_i[2]),
			.tgen_vid_lv          	(axis_tuser_i[3]),
		`elsif AXI4S_ONLY_ENABLED
			.tgen_vid_fv          	(axis_tuser_i[2]),
			.tgen_vid_lv          	(axis_tuser_i[3]),
		`else
			.tgen_vid_fv          	(fv_i),
			.tgen_vid_lv          	(lv_i),
		`endif
	`endif
	`ifdef AXI_ENABLED
		.tgen_vid_axi_data    		(axis_tdata_i),
		.axim_tready_i				(axim_tready_i),
		.axis_tvalid_o				(axis_tvalid_i),
	`elsif AXI4M_ONLY_ENABLED
		.axim_tready_i               (axim_tready_i),
		.tgen_vid_data0              (pix_data0_i),
        .tgen_vid_data1              (pix_data1_i),
        .tgen_vid_data2              (pix_data2_i),
        .tgen_vid_data3              (pix_data3_i),
        .tgen_vid_data4              (pix_data4_i),
        .tgen_vid_data5              (pix_data5_i),
        .tgen_vid_data6              (pix_data6_i),
        .tgen_vid_data7              (pix_data7_i),
        .tgen_vid_data8              (pix_data8_i),
        .tgen_vid_data9              (pix_data9_i),
	`elsif AXI4S_ONLY_ENABLED
		.tgen_vid_axi_data    		(axis_tdata_i),
		.axis_tvalid_o				(axis_tvalid_i),
	`else
		.tgen_vid_data0       		(pix_data0_i),
		.tgen_vid_data1       		(pix_data1_i),
		.tgen_vid_data2       		(pix_data2_i),
		.tgen_vid_data3       		(pix_data3_i),
		.tgen_vid_data4       		(pix_data4_i),
		.tgen_vid_data5       		(pix_data5_i),
		.tgen_vid_data6       		(pix_data6_i),
		.tgen_vid_data7       		(pix_data7_i),
		.tgen_vid_data8       		(pix_data8_i),
		.tgen_vid_data9       		(pix_data9_i),
	`endif
	.tgen_end_of_line     			(),
	.tgen_end_of_frame    			(eof)
   );

`include "dut_inst.v"    //dut connection to p2b rtl top module

   //bytes capturing monitor connections
   `ifdef AXI_ENABLED
		byte_out_monitor #(
		.NUM_TX_LANE (NUM_TX_LANE),
		.TX_GEAR		(TX_GEAR)
		)
		byte_monitor
		(
		.byte_clk (byte_clk_i),
		.axim_tvalid_i (axim_tvalid_o),
		.byte_log_en (byte_log_en),
		.axis_tready_i (axis_tready_o),
		.axim_tdata_i (axim_tdata_o),
		.axim_tready_o(axim_tready_i)
		);
	`elsif AXI4M_ONLY_ENABLED
		byte_out_monitor #(
		.NUM_TX_LANE (NUM_TX_LANE),
		.TX_GEAR		(TX_GEAR)
		)
		byte_monitor
		(
		.byte_clk (byte_clk_i),
		.axim_tvalid_i (axim_tvalid_o),
		.byte_log_en (byte_log_en),
		.axim_tdata_i (axim_tdata_o),
		.axim_tready_o(axim_tready_i)
		);
	`elsif AXI4S_ONLY_ENABLED
		byte_out_monitor #(
		.NUM_TX_LANE (NUM_TX_LANE),
		.TX_GEAR		(TX_GEAR)
		)
		byte_monitor
		(
		.byte_clk (byte_clk_i),
		.byte_en (byte_en_o),
		.byte_log_en (byte_log_en),
		.byte_dout (byte_data_o)
		);
	`else
		byte_out_monitor #(
		.NUM_TX_LANE (NUM_TX_LANE),
		.TX_GEAR		(TX_GEAR)
		)
		byte_monitor
		(
		.byte_clk (byte_clk_i),
		.byte_en (byte_en_o),
		.byte_log_en (byte_log_en),
		.byte_dout (byte_data_o)
		);
	`endif
   
   


   reg CLK_GSR = 0;
   reg USER_GSR = 1;
   
   initial begin
   	forever begin
   		#5;
   		CLK_GSR = ~CLK_GSR;
   	end
   end
   
   GSR GSR_INST (
   	.GSR_N(USER_GSR),
   	.CLK(CLK_GSR)
   );
   
   //picking the reset and tx header files based on csi or dsi
   `ifdef TX_DSI
   `include "tb_include/test_snow_pixel2byte_dsi_reset.vh"
   `include "tb_include/test_snow_pixel2byte_dsi_trans.vh"
   `include "tb_include/test_snow_pixel2byte_apb_reset.vh"
   `else
   `include "tb_include/test_snow_pixel2byte_csi2_trans.vh"
   `include "tb_include/test_snow_pixel2byte_csi2_reset.vh"
   `include "tb_include/test_snow_pixel2byte_apb_reset.vh"
   `endif

endmodule