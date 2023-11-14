// ======================================
// 1. Create new project using Lattice Diamond for Windows.
// 2. Open Active-HDL Lattice Edition GUI tool.
// 3. Click Tools -> Execute macro, then select the do file.
// 4. Wait for simulation to finish.

// ###############
// Testbench Parameters

// Modify the following testbench directives if you want to modify simulation settings.
// SIP_PCLK        - Used to set the period of the input pixel clock (in ps)
//`define SIP_BCLK 12000.0

//`define DSI_RESET_TEST  			  		//TO RUN DSI RESET TEST
//`define CSI2_RESET_TEST  			  		//TO RUN CSI2 RESET TEST
`define TRANS_TEST		                    //TO RUN TRANSACTION TEST FOR ANY OF THE CSI2 OR DSI
//`define USER_DEFINED_PIXEL_COUNT    		//TO MANUALLY DRIVE USER DEFINED NUMBER OF PIXELS TO INPUT
//`define APB_RESET_TEST              		//TO RUN APB RESET TEST
//`define APB_SINGLE_WR_RD_REG1_TEST  		//SINGLE WRITE AND READ FROM ADDRESS LOCATION 'h4 I.E. FROM REG1
//`define APB_MULTI_WR_RD_REG1_TEST   		//MULTI WRITE AND READ FROM ADDRESS LOCATION 'h4 I.E. FROM REG1
//`define APB_SINGLE_WR_RD_REG0_TEST  		//SINGLE WRITE AND READ FROM ADDRESS LOCATION 'h0 I.E. FROM REG0
//`define APB_MULTI_WR_RD_REG0_TEST   		//MULTI WRITE AND READ FROM ADDRESS LOCATION 'h0 I.E. FROM REG0
//`define APB_P2B_COMPLETE_TXN_TEST   		//PERFORM SINGLE WRITE TO VC AND WC AND START OF EACH FRAME(WR TO REG1) AND THEN READ CONTINUOUSLY THE FIFO STATUS(READ FROM REG0)
//`define APB_SINGLE_ADDR_SLAVE_ERROR_TEST 	//SLAVE ADDRESS DECODING ERROR TEST FOR SINGLE ADDRESS
//`define APB_MULTI_ADDR_SLAVE_ERROR_TEST  	//SLAVE ADDRESS DECODING ERROR TEST FOR MULTIPLE ADDRESS

// SIP_BCLK        - Used to set the period of the input byte clock (in ps) 
//`define SIP_PCLK 7500.0

//USER DEFINES PIXELS COUNT
`define USER_PIXEL_COUNT 4

// NUM_FRAMES      - Used to set the number of video frames
`define NUM_FRAMES 3

// NUM_LINES       - Used to set the number of lines per frame
`define NUM_LINES 5

// HFRONT          - Number of cycles before HSYNC signal asserts (Horizontal Front Blanking)
`define HFRONT 528

// HPULSE          - Number of cycles HSYNC signal asserts
`define HPULSE 44

// HBACK           - Number of cycles after HSYNC signal asserts (Horizontal Rear Blanking)
`define HBACK 300

// VFRONT          - Number of cycles before VSYNC signal asserts (Vertical Front Blanking)
`define VFRONT 4

// VPULSE          - Number of cycles VSYNC signal asserts
`define VPULSE 5

// VBACK           - Number of cycles after VSYNC signal asserts (Vertical Rear Blanking)
`define VBACK 36

// NUM_BYTES              - Number of bytes sent per line
`define NUM_BYTES 240
