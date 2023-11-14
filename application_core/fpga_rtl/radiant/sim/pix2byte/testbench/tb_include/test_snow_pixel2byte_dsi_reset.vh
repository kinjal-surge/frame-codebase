// =========================================================================
// Filename: test_snow_pixel2byte_dsi_reset.v
// Copyright(c) 2017 Lattice Semiconductor Corporation. All rights reserved.
// =========================================================================
`ifndef TEST_SNOW_PIXEL2BYTE_DSI_RESET
`define TEST_SNOW_PIXEL2BYTE_DSI_RESET

task test_snow_pixel2byte_dsi_reset;
   begin

      fork

      begin
		   #1;
          //Check for proper output values after reset
          `ifdef TX_DSI
          if(hsync_start !== 'b0) begin
              $display($time, " ERROR : hsync_start default value not correct : %h ", hsync_start);
              testfail_cnt = testfail_cnt+1;
          end
          if(hsync_end !== 'b0) begin
              $display($time, " ERROR : hsync_end default value not correct : %h ", hsync_end);
              testfail_cnt = testfail_cnt+1;
          end
          if(vsync_start !== 'b0) begin
              $display($time, " ERROR : vsync_start default value not correct : %h ", vsync_start);
              testfail_cnt = testfail_cnt+1;
          end
          if(vsync_end !== 'b0) begin
              $display($time, " ERROR : vsync_end default value not correct : %h ", vsync_end);
              testfail_cnt = testfail_cnt+1;
          end
		  `ifdef AXI_ENABLED
			if(axim_tvalid_o !== 'b0) begin
				$display($time, " ERROR : byte_en default value not correct : %h ", axim_tvalid_o);
				testfail_cnt = testfail_cnt+1;
			end
		  `else
			if(byte_en !== 'b0) begin
				$display($time, " ERROR : byte_en default value not correct : %h ", byte_en);
				testfail_cnt = testfail_cnt+1;
			end
		  `endif
		  `ifdef AXI_ENABLED
			if(axim_tdata_o !== 'b0) begin
				$display($time, " ERROR : byte_data default value not correct : %h ", axim_tdata_o);
				testfail_cnt = testfail_cnt+1;
			end
		  `else
			if(byte_data !== 'b0) begin
				$display($time, " ERROR : byte_data default value not correct : %h ", byte_data);
				testfail_cnt = testfail_cnt+1;
			end
		  `endif
          `ifdef TXFR_SIG
          if(txfr_req !== 'b0) begin
              $display($time, " ERROR : txfr_req default value not correct : %h ", txfr_req);
              testfail_cnt = testfail_cnt+1;
          end
          `endif
          `ifdef MISC_ON
          if(data_type === 'bx) begin
              $display($time, " ERROR : data_type default value not correct : %h ", data_type);
              testfail_cnt = testfail_cnt+1;
          end
          `endif
          `endif
      end
	

      join
   end

endtask
`endif
