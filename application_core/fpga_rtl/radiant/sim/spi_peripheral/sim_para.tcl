lappend auto_path "/opt/lscc/radiant/2023.1/scripts/tcl/simulation"
package require simulation_generation
set ::bali::simulation::Para(DEVICEPM) {je5d00}
set ::bali::simulation::Para(DEVICEFAMILYNAME) {LIFCL}
set ::bali::simulation::Para(PROJECT) {spi_peripheral}
set ::bali::simulation::Para(PROJECTPATH) {/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim}
set ::bali::simulation::Para(FILELIST) {"/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/spi_peripheral/tb_top.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/chip_id.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/spi_subperipheral_selector.sv" "/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/source/impl_1/spi_peripheral.sv" }
set ::bali::simulation::Para(GLBINCLIST) {}
set ::bali::simulation::Para(INCLIST) {"none" "none" "none" "none"}
set ::bali::simulation::Para(WORKLIBLIST) {"" "" "" "" }
set ::bali::simulation::Para(COMPLIST) {"VERILOG" "VERILOG" "VERILOG" "VERILOG" }
set ::bali::simulation::Para(LANGSTDLIST) {"" "" "" "" }
set ::bali::simulation::Para(SIMLIBLIST) {pmi_work ovi_lifcl}
set ::bali::simulation::Para(MACROLIST) {}
set ::bali::simulation::Para(SIMULATIONTOPMODULE) {spi_tb}
set ::bali::simulation::Para(SIMULATIONINSTANCE) {}
set ::bali::simulation::Para(LANGUAGE) {VERILOG}
set ::bali::simulation::Para(SDFPATH)  {}
set ::bali::simulation::Para(INSTALLATIONPATH) {/opt/lscc/radiant/2023.1}
set ::bali::simulation::Para(MEMPATH) {/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/byte2pixel_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/dphy_rx_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/frame_buffer_ram;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/osc_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/pll_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/ram_ip;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/csi_tx;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/sim/pix2byte;/home/rohit/Downloads/frame-codebase/application_core/fpga_rtl/radiant/stack_fifo}
set ::bali::simulation::Para(UDOLIST) {}
set ::bali::simulation::Para(ADDTOPLEVELSIGNALSTOWAVEFORM)  {1}
set ::bali::simulation::Para(RUNSIMULATION)  {1}
set ::bali::simulation::Para(SIMULATIONTIME)  {100}
set ::bali::simulation::Para(SIMULATIONTIMEUNIT)  {ns}
set ::bali::simulation::Para(ISRTL)  {1}
set ::bali::simulation::Para(HDLPARAMETERS) {}
::bali::simulation::ModelSim_Run
