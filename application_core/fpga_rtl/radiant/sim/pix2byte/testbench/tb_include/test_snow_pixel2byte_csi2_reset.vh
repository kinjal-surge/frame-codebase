// =========================================================================
// Filename: test_snow_pixel2byte_csi2_reset.v
// Copyright(c) 2017 Lattice Semiconductor Corporation. All rights reserved.
// =========================================================================
`ifndef TEST_SNOW_PIXEL2BYTE_CSI2_RESET
`define TEST_SNOW_PIXEL2BYTE_CSI2_RESET

task test_snow_pixel2byte_csi2_reset;
   begin

      fork

      begin
          #1;
          //Check for proper output values after reset
          `ifdef TX_CSI2
          if(fv_start !== 'b0) begin
              $display($time, " ERROR : fv_start default value not correct : %h ", fv_start);
              testfail_cnt = testfail_cnt+1;
          end
          if(fv_end !== 'b0) begin
              $display($time, " ERROR : fv_end default value not correct : %h ", fv_end);
              testfail_cnt = testfail_cnt+1;
          end
          if(lv_start !== 'b0) begin
              $display($time, " ERROR : lv_start default value not correct : %h ", lv_start);
              testfail_cnt = testfail_cnt+1;
          end
          if(lv_end !== 'b0) begin
              $display($time, " ERROR : lv_end default value not correct : %h ", lv_end);
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
          `ifdef YUV420_8
          if(odd_line !== 'b0) begin
              $display($time, " ERROR : odd_line default value not correct : %h ", odd_line);
              testfail_cnt = testfail_cnt+1;
          end
          `elsif YUV420_10
          if(odd_line !== 'b0) begin
              $display($time, " ERROR : odd_line default value not correct : %h ", odd_line);
              testfail_cnt = testfail_cnt+1;
          end
          `endif
          `endif
          `endif
      end

      join
   end

endtask
`endif
