// =========================================================================
// Filename: test_snow_pixel2byte_csi2_reset.v
// Copyright(c) 2017 Lattice Semiconductor Corporation. All rights reserved.
// =========================================================================
`ifndef TEST_SNOW_PIXEL2BYTE_APB_RESET
`define TEST_SNOW_PIXEL2BYTE_APB_RESET

task test_snow_pixel2byte_apb_reset;
   begin

      fork

      begin
          #1;
          //Check for proper output values after reset
          if(apb_prdata_o !== 'b0) begin
              $display($time, " ERROR : output read data default value not correct : %h ", apb_prdata_o);
              testfail_cnt = testfail_cnt+1;
          end
          if(apb_pslverr_o !== 'b0) begin
              $display($time, " ERROR : Slave error is asserted in reset state which is incorrect : %h ", apb_pslverr_o);
              testfail_cnt = testfail_cnt+1;
          end
          if(vc_o !== 'b0) begin
              $display($time, " ERROR : output virtual count default value not correct : %h ", vc_o);
              testfail_cnt = testfail_cnt+1;
          end
          if(wc_o !== 'b0) begin
              $display($time, " ERROR : output word count default value not correct : %h ", wc_o);
              testfail_cnt = testfail_cnt+1;
          end
      end

      join
   end

endtask
`endif

