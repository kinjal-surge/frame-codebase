/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

`ifndef RADIANT
`include "modules/camera/crop.sv"
`include "modules/camera/debayer.sv"
`include "modules/camera/image_buffer.sv"
`endif

module camera (
    input logic global_reset_n_in,
    
    input logic clock_spi_in, // 72MHz
    input logic reset_spi_n_in,

    input logic clock_pixel_in, // 36MHz
    input logic reset_pixel_n_in,

    inout wire mipi_clock_p_in,
    inout wire mipi_clock_n_in,
    inout wire mipi_data_p_in,
    inout wire mipi_data_n_in,

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input integer operand_count_in,
    output logic [7:0] response_out,
    output logic response_valid_out
);

localparam X_CROP_START = 542;
localparam X_CROP_END   = 742;
localparam Y_CROP_START = 260;
localparam Y_CROP_END   = 460;

// Registers to hold the current command operations
logic capture_flag;
logic capture_in_progress_flag;

// TODO make capture_size dynamic once we have adjustable resolution
logic [15:0] capture_size = (X_CROP_END - X_CROP_START) * (Y_CROP_END - Y_CROP_START);
logic [15:0] bytes_read;

logic [15:0] bytes_remaining;
assign bytes_remaining = capture_size - bytes_read;

logic [15:0] buffer_read_address;
logic [7:0] buffer_read_data;
assign buffer_read_address = bytes_read;

logic last_op_code_valid_in;
logic last_operand_valid_in;

// Jpeg
logic                   jpeg_sel;
logic                   jpeg_out_size_clear;
logic                   jpeg_reset;
logic [19:0]            jpeg_out_size;

// Handle op-codes as they come in
always_ff @(posedge clock_spi_in) begin
    
    if (reset_spi_n_in == 0) begin
        response_out <= 0;
        response_valid_out <= 0;
        capture_flag <= 0;
        bytes_read <= 0;
        last_op_code_valid_in <= 0;
        last_operand_valid_in <= 0;

        jpeg_sel <= 0;
        jpeg_out_size_clear <= 0;
    end

    else begin

        last_op_code_valid_in <= op_code_valid_in;
        last_operand_valid_in <= operand_valid_in;

        // Clear capture flag once it is in process
        if (capture_in_progress_flag == 1) begin
            capture_flag <= 0;  
        end
        
        if (op_code_valid_in) begin

            case (op_code_in)

                // Capture
                'h20: begin
                    if (capture_in_progress_flag == 0) begin
                        capture_flag <= 1;
                        bytes_read <= 0;
                    end
                end

                // Bytes available
                'h21: begin
                    case (operand_count_in)
                        0: response_out <= bytes_remaining[15:8];
                        1: response_out <= bytes_remaining[7:0];
                    endcase

                    response_valid_out <= 1;
                end

                // Read data
                'h22: begin
                    response_out <= buffer_read_data;
                    response_valid_out <= 1;

                    if (last_operand_valid_in == 0 && operand_valid_in == 1) begin
                        bytes_read <= bytes_read + 1;
                    end
                end

                // JPEG
                'h30: begin
                    if (operand_valid_in) begin
                        jpeg_sel <= operand_in[0];
                        jpeg_out_size_clear <= operand_in[1];
                        jpeg_reset <= operand_in[3];
                    end
                end
                // JPEG size
                'h31: begin
                    case (operand_count_in)
                        0: response_out <= jpeg_out_size[7:0];
                        1: response_out <= jpeg_out_size[15:8];
                        2: response_out <= jpeg_out_size[19:16];
                    endcase
                end
            endcase

        end

        else begin
            response_valid_out <= 0;
        end

    end

end

// Capture command logic
logic [2:0] frame_valid_edge_monitor;
logic debayered_frame_valid;
logic jpeg_end;

always_ff @(posedge clock_spi_in) begin
    if (reset_spi_n_in == 0) begin
        capture_in_progress_flag <= 0;
        frame_valid_edge_monitor <= 0;
    end

    else begin
        frame_valid_edge_monitor <= {frame_valid_edge_monitor,
                                             debayered_frame_valid};

        if (capture_flag && frame_valid_edge_monitor[2:1] == 'b01) begin
            capture_in_progress_flag <= 1;
        end

        else if (jpeg_sel ? jpeg_end | jpeg_reset : frame_valid_edge_monitor[2:1] == 'b10) begin
            capture_in_progress_flag <= 0;
        end
    end
end

`ifdef RADIANT

logic mipi_byte_clock;
logic mipi_byte_reset_n;

logic mipi_payload_enable_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic mipi_payload_enable /* synthesis syn_keep=1 nomerge=""*/;

logic [7:0] mipi_payload_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] mipi_payload /* synthesis syn_keep=1 nomerge=""*/;

logic mipi_sp_enable_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic mipi_sp_enable /* synthesis syn_keep=1 nomerge=""*/;

logic mipi_lp_av_enable_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic mipi_lp_av_enable /* synthesis syn_keep=1 nomerge=""*/;

logic [15:0] mipi_word_count /* synthesis syn_keep=1 nomerge=""*/;
logic [5:0] mipi_datatype;

reset_sync reset_sync_clock_byte (
    .clock_in(mipi_byte_clock),
    .async_reset_n_in(global_reset_n_in),
    .sync_reset_n_out(mipi_byte_reset_n)
);

csi2_receiver_ip csi2_receiver_ip (
    .clk_byte_o(),
    .clk_byte_hs_o(mipi_byte_clock),
    .clk_byte_fr_i(mipi_byte_clock),
    .reset_n_i(global_reset_n_in),
    .reset_byte_fr_n_i(mipi_byte_reset_n),
    .clk_p_io(mipi_clock_p_in),
    .clk_n_io(mipi_clock_n_in),
    .d_p_io(mipi_data_p_in),
    .d_n_io(mipi_data_n_in),
    .payload_en_o(mipi_payload_enable_metastable),
    .payload_o(mipi_payload_metastable),
    .tx_rdy_i(1'b1),
    .pd_dphy_i(~global_reset_n_in),
    .dt_o(mipi_datatype),
    .wc_o(mipi_word_count),
    .ref_dt_i(6'h2B),
    .sp_en_o(mipi_sp_enable_metastable),
    .lp_en_o(),
    .lp_av_en_o(mipi_lp_av_enable_metastable)
);

always @(posedge mipi_byte_clock or negedge mipi_byte_reset_n) begin

    if (!mipi_byte_reset_n) begin
        mipi_payload_enable <= 0;
        mipi_payload <= 0;
        mipi_sp_enable <= 0;
        mipi_lp_av_enable <= 0;
    end

    else begin
        mipi_payload_enable <= mipi_payload_enable_metastable;
        mipi_payload <= mipi_payload_metastable;
        mipi_sp_enable <= mipi_sp_enable_metastable;
        mipi_lp_av_enable <= mipi_lp_av_enable_metastable;
    end

end

logic byte_to_pixel_frame_valid /* synthesis syn_keep=1 nomerge=""*/;
logic byte_to_pixel_line_valid /* synthesis syn_keep=1 nomerge=""*/;
logic [9:0] byte_to_pixel_data /* synthesis syn_keep=1 nomerge=""*/;

byte_to_pixel_ip byte_to_pixel_ip (
    .reset_byte_n_i(mipi_byte_reset_n),
    .clk_byte_i(mipi_byte_clock),
    .sp_en_i(mipi_sp_enable),
    .dt_i(mipi_datatype),
    .lp_av_en_i(mipi_lp_av_enable),
    .payload_en_i(mipi_payload_enable),
    .payload_i(mipi_payload),
    .wc_i(mipi_word_count),
    .reset_pixel_n_i(reset_pixel_n_in),
    .clk_pixel_i(clock_pixel_in),
    .fv_o(byte_to_pixel_frame_valid),
    .lv_o(byte_to_pixel_line_valid),
    .pd_o(byte_to_pixel_data)
);

logic [9:0] cropped_data;
logic cropped_line_valid;
logic cropped_frame_valid;

crop crop (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .x_crop_start(X_CROP_START),
    .x_crop_end(X_CROP_END),
    .y_crop_start(Y_CROP_START),
    .y_crop_end(Y_CROP_END),

    .pixel_red_data_in(byte_to_pixel_data),
    .pixel_green_data_in('0),
    .pixel_blue_data_in('0),
    .line_valid_in(byte_to_pixel_line_valid),
    .frame_valid_in(byte_to_pixel_frame_valid),

    .pixel_red_data_out(cropped_data),
    .pixel_green_data_out(),
    .pixel_blue_data_out(),
    .line_valid_out(cropped_line_valid),
    .frame_valid_out(cropped_frame_valid)
);

logic [9:0] debayered_red_data;
logic [9:0] debayered_green_data;
logic [9:0] debayered_blue_data;
logic debayered_line_valid;
//logic debayered_frame_valid;

debayer debayer (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .pixel_data_in(cropped_data),
    .line_valid_in(cropped_line_valid),
    .frame_valid_in(cropped_frame_valid),

    .pixel_red_data_out(debayered_red_data),
    .pixel_green_data_out(debayered_green_data),
    .pixel_blue_data_out(debayered_blue_data),
    .line_valid_out(debayered_line_valid),
    .frame_valid_out(debayered_frame_valid)
);




// JPEG Reset just in case
logic jpeg_reset_n;
reset_sync reset_sync_jpeg (
    .clock_in(clock_pixel_in),
    .async_reset_n_in(~jpeg_reset),
    .sync_reset_n_out(jpeg_reset_n)
);


// JPEG ISP (RGB2YUV, 4:4:4 2 4:2:0, 16-line MCU buffer)
logic [7:0]             jpeg_in_data[7:0]; 
logic                   jpeg_in_valid;
logic                   jpeg_in_hold;
logic [2:0]             jpeg_in_cnt;

jisp #(
    .SENSOR_X_SIZE      (720),
    .SENSOR_Y_SIZE      (720)
) jisp (
    .rgb24              ({debayered_blue_data[9:2], debayered_green_data[9:2], debayered_red_data[9:2]}),
    .rgb24_valid        (jpeg_sel & debayered_line_valid),
    .rgb24_hold         ( ),
    .frame_valid_in     (jpeg_sel & debayered_frame_valid),
    .line_valid_in      (jpeg_sel & debayered_line_valid),

    .di                 (jpeg_in_data),
    .di_valid           (jpeg_in_valid),
    .di_hold            (jpeg_in_hold),
    .di_cnt             (jpeg_in_cnt),

    .x_size_m1          (X_CROP_END - X_CROP_START),
    .y_size_m1          (Y_CROP_END - Y_CROP_START),

    .clk                (clock_pixel_in),
    .resetn             (reset_pixel_n_in & jpeg_reset_n)
);

logic [127:0]           jpeg_out_data;
logic [4:0]             jpeg_out_bytes;
logic                   jpeg_out_tlast;
logic                   jpeg_out_valid;


jenc #(
    .SENSOR_X_SIZE      (720),
    .SENSOR_Y_SIZE      (720)
) jenc (
    .di                 (jpeg_in_data),
    .di_valid           (jpeg_in_valid),
    .di_hold            (jpeg_in_hold),
    .di_cnt             (jpeg_in_cnt),

    .out_data           (jpeg_out_data),
    .out_bytes          (jpeg_out_bytes),
    .out_tlast          (jpeg_out_tlast),
    .out_valid          (jpeg_out_valid),
    .out_hold           (1'b0),

    .size               (jpeg_out_size),
    .size_clear         (jpeg_out_size_clear),

    .x_size_m1          (X_CROP_END - X_CROP_START),
    .y_size_m1          (Y_CROP_END - Y_CROP_START),

    .clk                (clock_pixel_in),
    .resetn             (reset_pixel_n_in & jpeg_reset_n)
);




// JPEG CDC for frame buffer
// CDC first, then split 128 bits into chunks of 32 bits/4 bytes, then write
//
// Important for synthesis:
// set false_path -from  -to ... (between clocks)
// set_max_delay {$clock_spi_in_period} -from [jpeg_out_data, jpeg_out_bytes, jpeg_out_valid, jpeg_out_tlast] -to  [get_clocks clock_spi_in]
// set_max_delay {$clock_spi_in_period} -from [jpeg_sel] -to [get_clocks clock_pixel_in]
logic [13:0]            jpeg_buffer_address;
logic [31:0]            jpeg_buffer_write_data;
logic                   jpeg_buffer_write_enable;

jenc_cdc jenc_cdc (.*);


// RGB data: Assemble 32 bits/4 bytes, then CDC, then write
//
// Important for synthesis:
// set false_path -from  -to ... (between clocks)
// set_max_delay {$clock_spi_in_period} -from [debayered_frame_valid rgb_buffer_write_data] -to  [get_clocks clock_spi_in]
// set_max_delay {$clock_spi_in_period} -from [jpeg_sel] -to [get_clocks clock_pixel_in]

logic [13:0]            rgb_buffer_address;
logic [31:0]            rgb_buffer_write_data;
logic                   rgb_buffer_write_enable;
	
rgb_cdc rgb_cdc (
    .line_valid         (debayered_line_valid),
    .frame_valid        (debayered_frame_valid),
    .red_data           (debayered_red_data),
    .green_data         (debayered_green_data),
    .blue_data          (debayered_blue_data),
    .*
);

// image buffer
logic [13:0]            buffer_address;
logic [31:0]            buffer_write_data;
logic                   buffer_write_enable;

always_comb buffer_address      = jpeg_sel ? jpeg_buffer_address : rgb_buffer_address;
always_comb buffer_write_data   = jpeg_sel ? jpeg_buffer_write_data : rgb_buffer_write_data;
always_comb buffer_write_enable = jpeg_sel ? jpeg_buffer_write_enable : rgb_buffer_write_enable;

image_buffer image_buffer (
    .clock_in(clock_spi_in),
    .reset_n_in(reset_spi_n_in),
    .write_address_in(buffer_address),
    .read_address_in(buffer_read_address),
    .write_data_in(buffer_write_data),
    .read_data_out(buffer_read_data),
    .write_enable_in(buffer_write_enable)
);

`endif

endmodule
