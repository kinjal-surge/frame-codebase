lappend auto_path "/home/rohit/lscc/radiant/2023.1/scripts/tcl/simulation"
package require simulation_generation
set ::bali::simulation::Para(DEVICEPM) {je5d00}
set ::bali::simulation::Para(DEVICEFAMILYNAME) {LIFCL}
set ::bali::simulation::Para(PROJECT) {simple_bayer}
set ::bali::simulation::Para(PROJECTPATH) {/home/rohit/Downloads/frame_fpga/sim}
set ::bali::simulation::Para(FILELIST) {"/home/rohit/Downloads/frame_fpga/source/impl_1/simple_bayer.sv" "/home/rohit/Downloads/frame_fpga/sim/simple_bayer/tb_top.sv" }
set ::bali::simulation::Para(GLBINCLIST) {}
set ::bali::simulation::Para(INCLIST) {"none" "none"}
set ::bali::simulation::Para(WORKLIBLIST) {"" "" }
set ::bali::simulation::Para(COMPLIST) {"VERILOG" "VERILOG" }
set ::bali::simulation::Para(LANGSTDLIST) {"" "" }
set ::bali::simulation::Para(SIMLIBLIST) {pmi_work ovi_lifcl}
set ::bali::simulation::Para(MACROLIST) {}
set ::bali::simulation::Para(SIMULATIONTOPMODULE) {simple_bayer}
set ::bali::simulation::Para(SIMULATIONINSTANCE) {}
set ::bali::simulation::Para(LANGUAGE) {VERILOG}
set ::bali::simulation::Para(SDFPATH)  {}
set ::bali::simulation::Para(INSTALLATIONPATH) {/home/rohit/lscc/radiant/2023.1}
set ::bali::simulation::Para(MEMPATH) {/home/rohit/Downloads/frame_fpga/byte2pixel_ip;/home/rohit/Downloads/frame_fpga/dphy_rx_ip;/home/rohit/Downloads/frame_fpga/osc_ip;/home/rohit/Downloads/frame_fpga/pll_ip;/home/rohit/Downloads/frame_fpga/ram_ip;/home/rohit/Downloads/frame_fpga/sim/csi_tx;/home/rohit/Downloads/frame_fpga/sim/pix2byte;/home/rohit/Downloads/frame_fpga/sim/pll_ip_sim}
set ::bali::simulation::Para(UDOLIST) {}
set ::bali::simulation::Para(ADDTOPLEVELSIGNALSTOWAVEFORM)  {1}
set ::bali::simulation::Para(RUNSIMULATION)  {1}
set ::bali::simulation::Para(SIMULATIONTIME)  {100}
set ::bali::simulation::Para(SIMULATIONTIMEUNIT)  {ns}
set ::bali::simulation::Para(ISRTL)  {1}
set ::bali::simulation::Para(HDLPARAMETERS) {}
::bali::simulation::ModelSim_Run
