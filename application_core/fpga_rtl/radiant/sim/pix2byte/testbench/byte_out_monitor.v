// =========================================================================
// Filename: byte_out_monitor.v
// Copyright(c) 2017 Lattice Semiconductor Corporation. All rights reserved.
// =========================================================================
`ifndef BYTE_OUT_MONITOR
`define BYTE_OUT_MONITOR

`include "dut_defines.v" 
`include "tb_include/tb_params.vh"  

module byte_out_monitor #(
    parameter NUM_TX_LANE   = 1,
    parameter TX_GEAR       = 8
)
	(  
   `ifdef AXI_ENABLED
		input byte_clk,
		input axim_tvalid_i,
		input byte_log_en,
		input axis_tready_i,
		input [(NUM_TX_LANE*TX_GEAR)+24-1:0] axim_tdata_i,
		output reg axim_tready_o
   `elsif AXI4M_ONLY_ENABLED
		input byte_clk,
		input axim_tvalid_i,
		input byte_log_en,
		input [(NUM_TX_LANE*TX_GEAR)+24-1:0] axim_tdata_i,
		output reg axim_tready_o
   `elsif AXI4S_ONLY_ENABLED
		input byte_clk,
		input byte_en,
		input byte_log_en,
		input [NUM_TX_LANE*TX_GEAR-1:0] byte_dout
   `else
		input byte_clk,
		input byte_en,
		input byte_log_en,
		input [NUM_TX_LANE*TX_GEAR-1:0] byte_dout
	`endif
   

);

   reg [7:0] byte0;
   reg [7:0] byte1;
   reg [7:0] byte2;
   reg [7:0] byte3;
   reg [7:0] byte4;
   reg [7:0] byte5;
   reg [7:0] byte6;
   reg [7:0] byte7;
   integer actual_byte_count=0;
   integer ready_count=0;

   initial begin
      detect_data;      
   end    

   task detect_data;
   begin
	    `ifdef AXI_ENABLED
			forever begin
				@(posedge byte_clk);
//        		#1;
				axim_tready_o=1;
		 
				if(axim_tvalid_i==1 && axis_tready_i==1) begin
					`ifdef NUM_TX_LANE_4
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 
							byte0 = axim_tdata_i[7:0]  ;  // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8] ;  // byte4 = byte_dout[15:8];
							byte2 = axim_tdata_i[23:16];  // byte1 = byte_dout[23:16];
							byte3 = axim_tdata_i[31:24];  // byte5 = byte_dout[31:24];
							byte4 = axim_tdata_i[39:32];  // byte2 = byte_dout[39:32];
							byte5 = axim_tdata_i[47:40];  // byte6 = byte_dout[47:40];
							byte6 = axim_tdata_i[55:48];  // byte3 = byte_dout[55:48];             
							byte7 = axim_tdata_i[63:56];  // byte7 = byte_dout[63:56];
			
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							write_to_file("output_data.log", byte4);
							write_to_file("output_data.log", byte5);
							write_to_file("output_data.log", byte6);
							write_to_file("output_data.log", byte7);
							actual_byte_count = actual_byte_count + 8;
						`else
							// deinterleaved:             // original 64bit interleaved:  
							byte0 = axim_tdata_i[7:0];    // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8];   // byte1 = byte_dout[23:16];
							byte2 = axim_tdata_i[23:16];  // byte2 = byte_dout[39:32];
							byte3 = axim_tdata_i[31:24];  // byte3 = byte_dout[55:48];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`endif
					`endif

					`ifdef NUM_TX_LANE_2
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = axim_tdata_i[7:0];    // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8];   // byte2 = byte_dout[15:8];
							byte2 = axim_tdata_i[23:16];  // byte1 = byte_dout[23:16];
							byte3 = axim_tdata_i[31:24];  // byte3 = byte_dout[31:24];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`else
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = axim_tdata_i[7:0];    // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8];   // byte1 = byte_dout[23:16];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`endif
					`endif

					`ifdef NUM_TX_LANE_1
						`ifdef TX_GEAR_16
							byte0 = axim_tdata_i[7:0];
							byte1 = axim_tdata_i[15:8];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`else
							byte0 = axim_tdata_i[7:0];
							write_to_file("output_data.log", byte0);
							actual_byte_count = actual_byte_count + 1;
						`endif
					`endif
				end
			end
		`elsif AXI4M_ONLY_ENABLED
			forever begin
				@(posedge byte_clk);
//        		#1;
				axim_tready_o=1;
		 
				if(axim_tvalid_i==1) begin
					`ifdef NUM_TX_LANE_4
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 
							byte0 = axim_tdata_i[7:0]  ;  // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8] ;  // byte4 = byte_dout[15:8];
							byte2 = axim_tdata_i[23:16];  // byte1 = byte_dout[23:16];
							byte3 = axim_tdata_i[31:24];  // byte5 = byte_dout[31:24];
							byte4 = axim_tdata_i[39:32];  // byte2 = byte_dout[39:32];
							byte5 = axim_tdata_i[47:40];  // byte6 = byte_dout[47:40];
							byte6 = axim_tdata_i[55:48];  // byte3 = byte_dout[55:48];             
							byte7 = axim_tdata_i[63:56];  // byte7 = byte_dout[63:56];
			
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							write_to_file("output_data.log", byte4);
							write_to_file("output_data.log", byte5);
							write_to_file("output_data.log", byte6);
							write_to_file("output_data.log", byte7);
							actual_byte_count = actual_byte_count + 8;
						`else
							// deinterleaved:             // original 64bit interleaved:  
							byte0 = axim_tdata_i[7:0];    // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8];   // byte1 = byte_dout[23:16];
							byte2 = axim_tdata_i[23:16];  // byte2 = byte_dout[39:32];
							byte3 = axim_tdata_i[31:24];  // byte3 = byte_dout[55:48];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`endif
					`endif

					`ifdef NUM_TX_LANE_2
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = axim_tdata_i[7:0];    // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8];   // byte2 = byte_dout[15:8];
							byte2 = axim_tdata_i[23:16];  // byte1 = byte_dout[23:16];
							byte3 = axim_tdata_i[31:24];  // byte3 = byte_dout[31:24];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`else
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = axim_tdata_i[7:0];    // byte0 = byte_dout[7:0];
							byte1 = axim_tdata_i[15:8];   // byte1 = byte_dout[23:16];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`endif
					`endif

					`ifdef NUM_TX_LANE_1
						`ifdef TX_GEAR_16
							byte0 = axim_tdata_i[7:0];
							byte1 = axim_tdata_i[15:8];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`else
							byte0 = axim_tdata_i[7:0];
							write_to_file("output_data.log", byte0);
							actual_byte_count = actual_byte_count + 1;
						`endif
					`endif
				end
			end
		`elsif AXI4S_ONLY_ENABLED
			forever begin
				@(posedge byte_clk);
//        		#1;
        
				if (byte_en == 1) begin
					`ifdef NUM_TX_LANE_4
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 
							byte0 = byte_dout[7:0]  ;  // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8] ;  // byte4 = byte_dout[15:8];
							byte2 = byte_dout[23:16];  // byte1 = byte_dout[23:16];
							byte3 = byte_dout[31:24];  // byte5 = byte_dout[31:24];
							byte4 = byte_dout[39:32];  // byte2 = byte_dout[39:32];
							byte5 = byte_dout[47:40];  // byte6 = byte_dout[47:40];
							byte6 = byte_dout[55:48];  // byte3 = byte_dout[55:48];             
							byte7 = byte_dout[63:56];  // byte7 = byte_dout[63:56];
			
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							write_to_file("output_data.log", byte4);
							write_to_file("output_data.log", byte5);
							write_to_file("output_data.log", byte6);
							write_to_file("output_data.log", byte7);
							actual_byte_count = actual_byte_count + 8;
						`else
							// deinterleaved:             // original 64bit interleaved:  
							byte0 = byte_dout[7:0];    // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];   // byte1 = byte_dout[23:16];
							byte2 = byte_dout[23:16];  // byte2 = byte_dout[39:32];
							byte3 = byte_dout[31:24];  // byte3 = byte_dout[55:48];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`endif
					`endif
	
					`ifdef NUM_TX_LANE_2
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = byte_dout[7:0];    // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];   // byte2 = byte_dout[15:8];
							byte2 = byte_dout[23:16];  // byte1 = byte_dout[23:16];
							byte3 = byte_dout[31:24];  // byte3 = byte_dout[31:24];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`else
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = byte_dout[7:0];    // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];   // byte1 = byte_dout[23:16];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`endif
					`endif
	
					`ifdef NUM_TX_LANE_1
						`ifdef TX_GEAR_16
							byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`else
							byte0 = byte_dout[7:0];
							write_to_file("output_data.log", byte0);
							actual_byte_count = actual_byte_count + 1;
						`endif
					`endif
				end
			end
		`else
			forever begin
				@(posedge byte_clk);
//        		#1;
        
				if (byte_en == 1) begin
					`ifdef NUM_TX_LANE_4
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 
							byte0 = byte_dout[7:0]  ;  // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8] ;  // byte4 = byte_dout[15:8];
							byte2 = byte_dout[23:16];  // byte1 = byte_dout[23:16];
							byte3 = byte_dout[31:24];  // byte5 = byte_dout[31:24];
							byte4 = byte_dout[39:32];  // byte2 = byte_dout[39:32];
							byte5 = byte_dout[47:40];  // byte6 = byte_dout[47:40];
							byte6 = byte_dout[55:48];  // byte3 = byte_dout[55:48];             
							byte7 = byte_dout[63:56];  // byte7 = byte_dout[63:56];
			
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							write_to_file("output_data.log", byte4);
							write_to_file("output_data.log", byte5);
							write_to_file("output_data.log", byte6);
							write_to_file("output_data.log", byte7);
							actual_byte_count = actual_byte_count + 8;
						`else
							// deinterleaved:             // original 64bit interleaved:  
							byte0 = byte_dout[7:0];    // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];   // byte1 = byte_dout[23:16];
							byte2 = byte_dout[23:16];  // byte2 = byte_dout[39:32];
							byte3 = byte_dout[31:24];  // byte3 = byte_dout[55:48];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`endif
					`endif
	
					`ifdef NUM_TX_LANE_2
						`ifdef TX_GEAR_16
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = byte_dout[7:0];    // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];   // byte2 = byte_dout[15:8];
							byte2 = byte_dout[23:16];  // byte1 = byte_dout[23:16];
							byte3 = byte_dout[31:24];  // byte3 = byte_dout[31:24];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							write_to_file("output_data.log", byte2);
							write_to_file("output_data.log", byte3);
							actual_byte_count = actual_byte_count + 4;
						`else
							// deinterleaved:             // original 64bit interleaved: 			   
							byte0 = byte_dout[7:0];    // byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];   // byte1 = byte_dout[23:16];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`endif
					`endif
	
					`ifdef NUM_TX_LANE_1
						`ifdef TX_GEAR_16
							byte0 = byte_dout[7:0];
							byte1 = byte_dout[15:8];
							write_to_file("output_data.log", byte0);
							write_to_file("output_data.log", byte1);
							actual_byte_count = actual_byte_count + 2;
						`else
							byte0 = byte_dout[7:0];
							write_to_file("output_data.log", byte0);
							actual_byte_count = actual_byte_count + 1;
						`endif
					`endif
				end
			end
		`endif
		
   end
   endtask

   task write_to_file (input [1024*8-1:0] str_in, input [7:0] data);
     integer filedesc;
     if(byte_log_en == 1)
     begin
       filedesc = $fopen(str_in,"a");
       $fwrite(filedesc, "%b\n", data); //changed from hex to binary by pavan
       $fclose(filedesc);
     end
   endtask  

  
endmodule
`endif