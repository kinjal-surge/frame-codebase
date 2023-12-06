lappend auto_path "/opt/lscc/radiant/2023.1/scripts/tcl/simulation"
package require simulation_generation
set ::bali::simulation::Para(DEVICEPM) {je5d00}
set ::bali::simulation::Para(DEVICEFAMILYNAME) {LIFCL}
set ::bali::simulation::Para(PROJECT) {post_synth}
set ::bali::simulation::Para(PROJECTPATH) {/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim}
set ::bali::simulation::Para(FILELIST) {"/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/impl_1/frame_fpga_impl_1_syn.vo" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/color_table.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/curve_cubic.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/display.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/fp_mult.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/frame_buffer.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/line.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/lram_fb.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/ram_inferred.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/reset_sync.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/simple_bayer.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/spi.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/vector_engine.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/xy_to_addr.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/top_sim/tb_top.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/stack_fifo/rtl/stack_fifo.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/frame_buffer/rtl/frame_buffer.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/dphy_rx_ip/rtl/dphy_rx_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/frame_buffer_ram/rtl/frame_buffer_ram.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/osc_ip/rtl/osc_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/pll_ip/rtl/pll_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/ram_ip/rtl/ram_ip.v" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/byte2pixel_ip/rtl/byte2pixel_ip.v" }
set ::bali::simulation::Para(GLBINCLIST) {}
set ::bali::simulation::Para(INCLIST) {"none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none" "none"}
set ::bali::simulation::Para(WORKLIBLIST) {"" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" }
set ::bali::simulation::Para(COMPLIST) {"VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" "VERILOG" }
set ::bali::simulation::Para(LANGSTDLIST) {"" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" }
set ::bali::simulation::Para(SIMLIBLIST) {pmi_work ovi_lifcl}
set ::bali::simulation::Para(MACROLIST) {}
set ::bali::simulation::Para(SIMULATIONTOPMODULE) {tb_top}
set ::bali::simulation::Para(SIMULATIONINSTANCE) {/dut}
set ::bali::simulation::Para(LANGUAGE) {VERILOG}
set ::bali::simulation::Para(SDFPATH)  {}
set ::bali::simulation::Para(INSTALLATIONPATH) {/opt/lscc/radiant/2023.1}
set ::bali::simulation::Para(MEMPATH) {/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/byte2pixel_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/dphy_rx_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/frame_buffer_ram;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/osc_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/pll_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/ram_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/csi_tx;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/pix2byte;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/stack_fifo}
set ::bali::simulation::Para(UDOLIST) {}
set ::bali::simulation::Para(ADDTOPLEVELSIGNALSTOWAVEFORM)  {1}
set ::bali::simulation::Para(RUNSIMULATION)  {1}
set ::bali::simulation::Para(SIMULATIONTIME)  {100}
set ::bali::simulation::Para(SIMULATIONTIMEUNIT)  {ns}
set ::bali::simulation::Para(ISRTL)  {0}
set ::bali::simulation::Para(HDLPARAMETERS) {}
::bali::simulation::ModelSim_Run
