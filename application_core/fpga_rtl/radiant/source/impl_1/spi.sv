/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright � 2023 Brilliant Labs Limited
 */

 module spi (
    // Main speed system clock
    input logic clk,

    // SPI SCK pin input.
    input logic sck,

    // SPI chip select input.
    input logic cs,

    input logic copi,

    output logic cipo,
	
	input logic reset,
	
	input logic [7:0] debug8,	
	input logic [31:0] debug32,
	output logic [16:0] rd_addr,
	input logic [31:0] rd_data,
	output logic rd_en,
	output logic [15:0] debug_out
);

localparam CHIPID_REG = 8'h00;
localparam DBG8_REG = 8'hB8;
localparam DBG32_REG = 8'hB9;
localparam DBG_RAM8 = 8'hBC;
localparam DBG_RAM16 = 8'hBA;
localparam DBG_RAM32 = 8'hBB;
localparam CHIPID = 8'hAA;
localparam DISPLAY = 8'hCC;

// Registers to keep track of SCK and CS edges
logic [1:0] cs_edge_monitor = 0;
logic [1:0] sck_edge_monitor = 0;

logic [7:0] bit_counter = 0;
logic [33:0] byte_counter = 0;

logic [7:0] cipo_reg;
logic [7:0] copi_reg;
logic [15:0] cipo_reg16;
logic [31:0] cipo_reg32;

logic [7:0] opcode;

always @(posedge clk) begin
    // Update the edge monitors with the latest cs and sck signal values
    cs_edge_monitor <= {cs_edge_monitor[0], cs};
    sck_edge_monitor <= {sck_edge_monitor[0], sck};

    // CS low, transaction in progress
    if (cs_edge_monitor == 2'b00) begin 
        // If CS is rising edge, we reset the counters and release io
        if (cs_edge_monitor == 'b01) begin
            bit_counter <= 0;
            byte_counter <= 0;
        end

        // We only change data counters on the falling edge of SCK
        if (sck_edge_monitor == 'b10) begin
            // Opcode
            if (byte_counter == 'd0) begin
                if (bit_counter == 'd7) begin
                    opcode <= copi_reg;
                    case (copi_reg)
                        CHIPID_REG: begin
                            cipo_reg <= CHIPID;
                            cipo <= CHIPID[7];
                        end
						DBG8_REG: begin
							cipo_reg <= debug8;
							cipo <= debug8[7];
						end
						DBG32_REG: begin
							cipo_reg32 <= debug32;
							cipo <= debug32[31];
						end
						DBG_RAM8: begin
							rd_en <= 1;
							cipo <= 0;
							rd_addr <= 0;
						end
						DBG_RAM32: begin
							rd_en <= 1;
							cipo <= 0;
							rd_addr <= 0;
						end
						DBG_RAM16: begin
							rd_en <= 1;
							cipo <= 0;
						end
						
						default: begin
                            cipo_reg <= copi_reg;
                            cipo <= copi_reg[7];
                        end
                    endcase
                end else cipo <= 1;
            end
            // Response
			
			// 1 byte resp opcodes
			if ((opcode == CHIPID_REG || opcode == DBG8_REG || DBG_RAM8) & byte_counter != 0) begin
				case (bit_counter)
					'd0: cipo <= cipo_reg[6];
					'd1: cipo <= cipo_reg[5];
					'd2: cipo <= cipo_reg[4];
					'd3: cipo <= cipo_reg[3];
					'd4: cipo <= cipo_reg[2];
					'd5: cipo <= cipo_reg[1];
					'd6: cipo <= cipo_reg[0];
					'd7: rd_addr <= rd_addr +1;
					default: cipo <= 1;
				endcase
			end
			
			// 2 byte resp opcodes
			if (opcode == DBG_RAM16 & byte_counter != 0) begin
				if (byte_counter[0]) begin
					case(bit_counter)
						'd0: begin
							cipo_reg16 <= rd_data;
							cipo <= 0;
							rd_addr <= rd_addr +1;
						end
						'd1: cipo <= cipo_reg16[13];
						'd2: cipo <= cipo_reg16[12];
						'd3: cipo <= cipo_reg16[11];
						'd4: cipo <= cipo_reg16[10];
						'd5: cipo <= cipo_reg16[9];
						'd6: cipo <= cipo_reg16[8];
						'd7: cipo <= cipo_reg16[7];
						default: cipo <= 1;
					endcase
				end else begin
					case (bit_counter)
						'd0: cipo <= cipo_reg16[6];
						'd1: cipo <= cipo_reg16[5];
						'd2: cipo <= cipo_reg16[4];
						'd3: cipo <= cipo_reg16[3];
						'd4: cipo <= cipo_reg16[2];
						'd5: cipo <= cipo_reg16[1];
						'd6: cipo <= cipo_reg16[0];
						'd7: cipo <= 0;
						default: cipo <= 1;
					endcase
				end
			end
			
			// 4 byte resp opcodes
			if ((opcode == DBG_RAM32 | opcode == DBG32_REG) & byte_counter != 0) begin
				case(byte_counter[1:0])
				2'b01: begin // msb
					case (bit_counter)
						'd0: cipo <= cipo_reg32[31];
						'd1: cipo <= cipo_reg32[30];
						'd2: cipo <= cipo_reg32[29];
						'd3: cipo <= cipo_reg32[28];
						'd4: cipo <= cipo_reg32[27];
						'd5: cipo <= cipo_reg32[26];
						'd6: cipo <= cipo_reg32[25];
						'd7: cipo <= cipo_reg32[24];
						default: cipo <= 1;
					endcase
				end
				
				2'b10: begin
					case (bit_counter)
						'd0: cipo <= cipo_reg32[23];
						'd1: cipo <= cipo_reg32[22];
						'd2: cipo <= cipo_reg32[21];
						'd3: cipo <= cipo_reg32[20];
						'd4: cipo <= cipo_reg32[19];
						'd5: cipo <= cipo_reg32[18];
						'd6: cipo <= cipo_reg32[17];
						'd7: cipo <= cipo_reg32[16];
						default: cipo <= 1;
					endcase
				end
				2'b11: begin
					case (bit_counter)
						'd0: cipo <= cipo_reg32[15];
						'd1: cipo <= cipo_reg32[14];
						'd2: cipo <= cipo_reg32[13];
						'd3: cipo <= cipo_reg32[12];
						'd4: cipo <= cipo_reg32[11];
						'd5: cipo <= cipo_reg32[10];
						'd6: cipo <= cipo_reg32[9];
						'd7: cipo <= cipo_reg32[8];
						default: cipo <= 1;
					endcase
				end
				2'b00: begin
					case (bit_counter)
						'd0: cipo <= cipo_reg32[7];
						'd1: cipo <= cipo_reg32[6];
						'd2: cipo <= cipo_reg32[5];
						'd3: cipo <= cipo_reg32[4];
						'd4: cipo <= cipo_reg32[3];
						'd5: cipo <= cipo_reg32[2];
						'd6: cipo <= cipo_reg32[1];
						'd7: cipo <= cipo_reg32[0];
						default: cipo <= 1;
					endcase
				end
				endcase // byte_counter[1:0]
			end
					
            // Increment counter
            if (bit_counter == 'd7) begin 
                bit_counter <= 0;
                byte_counter <= byte_counter + 1;
				if (byte_counter[1:0] == 'b00) begin
					
				end
            end else bit_counter <= bit_counter + 1;
        end

        // Rising edge of SCK 
        else if ((sck_edge_monitor == 'b01) && (byte_counter == 'd0)) begin
            // Shift in data from nRF MSB first
	        case (bit_counter)
				'd0: copi_reg[7] <= copi;
				'd1: copi_reg[6] <= copi;
				'd2: copi_reg[5] <= copi;
				'd3: copi_reg[4] <= copi;
				'd4: copi_reg[3] <= copi;
				'd5: copi_reg[2] <= copi;
				'd6: copi_reg[1] <= copi;
				'd7: copi_reg[0] <= copi;
			endcase
        end
		
		else if ((sck_edge_monitor == 'b01) && (byte_counter == 'd1)) begin
			case (bit_counter)
				'd0: debug_out[15] <= copi;
				'd1: debug_out[14] <= copi;
				'd2: debug_out[13] <= copi;
				'd3: debug_out[12] <= copi;
				'd4: debug_out[11] <= copi;
				'd5: debug_out[10] <= copi;
				'd6: debug_out[9] <= copi;
				'd7: debug_out[8] <= copi;
			endcase
		end
		else if ((sck_edge_monitor == 'b01) && (byte_counter == 'd2)) begin
			case (bit_counter)
				'd0: debug_out[7] <= copi;
				'd1: debug_out[6] <= copi;
				'd2: debug_out[5] <= copi;
				'd3: debug_out[4] <= copi;
				'd4: debug_out[3] <= copi;
				'd5: debug_out[2] <= copi;
				'd6: debug_out[1] <= copi;
				'd7: debug_out[0] <= copi;
			endcase
		end
		
		if (opcode == DBG_RAM8 && bit_counter == 'd7) begin
			cipo <= rd_data[7];
			cipo_reg <= rd_data;
		end
    end
    // Reset on falling CS
    if (cs_edge_monitor == 2'b10 || reset) begin
        bit_counter <= 0;
        byte_counter <= 0;
        opcode <= 0;
        cipo <= 0;
		rd_en <= 0;
		rd_addr <= 0;
    end
end

endmodule