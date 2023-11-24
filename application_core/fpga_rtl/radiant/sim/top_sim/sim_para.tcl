lappend auto_path "/home/rohit/lscc/radiant/2023.1/scripts/tcl/simulation"
package require simulation_generation
set ::bali::simulation::Para(DEVICEPM) {je5d00}
set ::bali::simulation::Para(DEVICEFAMILYNAME) {LIFCL}
set ::bali::simulation::Para(PROJECT) {top_sim}
set ::bali::simulation::Para(PROJECTPATH) {/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim}
set ::bali::simulation::Para(FILELIST) {"/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/top.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/spi.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/reset_sync.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/osc_ip/rtl/osc_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/byte2pixel_ip/rtl/byte2pixel_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/dphy_rx_ip/rtl/dphy_rx_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/pll_ip/rtl/pll_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/csi_tx/rtl/csi_tx.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/pix2byte/rtl/pix2byte.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/colorbar_gen.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/image_gen.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/frame_buffer.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/ram_ip/rtl/ram_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/ram_inferred.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/simple_bayer.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/display.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/top_sim/tb_top.sv" }
set ::bali::simulation::Para(GLBINCLIST) {}
set ::bali::simulation::Para(INCLIST) {"none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none"}
set ::bali::simulation::Para(WORKLIBLIST) {"work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "work" "" }
set ::bali::simulation::Para(COMPLIST) {"VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" }
set ::bali::simulation::Para(LANGSTDLIST) {"System Verilog" "System Verilog" "System Verilog" "" "" "" "" "" "" "Verilog 2001" "System Verilog" "System Verilog" "" "System Verilog" "System Verilog" "System Verilog" "" }
set ::bali::simulation::Para(SIMLIBLIST) {pmi_work ovi_lifcl}
set ::bali::simulation::Para(MACROLIST) {}
set ::bali::simulation::Para(SIMULATIONTOPMODULE) {tb_top}
set ::bali::simulation::Para(SIMULATIONINSTANCE) {}
set ::bali::simulation::Para(LANGUAGE) {VERILOG}
set ::bali::simulation::Para(SDFPATH)  {}
set ::bali::simulation::Para(INSTALLATIONPATH) {/home/rohit/lscc/radiant/2023.1}
set ::bali::simulation::Para(MEMPATH) {/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/byte2pixel_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/dphy_rx_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/frame_buffer_ram;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/osc_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/pll_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/ram_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/csi_tx;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/pix2byte}
set ::bali::simulation::Para(UDOLIST) {}
set ::bali::simulation::Para(ADDTOPLEVELSIGNALSTOWAVEFORM)  {1}
set ::bali::simulation::Para(RUNSIMULATION)  {0}
set ::bali::simulation::Para(SIMULATIONTIME)  {0}
set ::bali::simulation::Para(SIMULATIONTIMEUNIT)  {}
set ::bali::simulation::Para(ISRTL)  {1}
set ::bali::simulation::Para(HDLPARAMETERS) {}
::bali::simulation::ModelSim_Run
