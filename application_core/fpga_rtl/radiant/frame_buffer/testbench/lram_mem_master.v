`ifndef _LRAM_MEM_MASTER_
`define _LRAM_MEM_MASTER_

module lram_mem_master # (
    parameter MEM_TYPE         = "lram_dp_true",
    parameter ADDR_DEPTH_A     = 16384,
    parameter DATA_WIDTH_A     = 32,
    parameter ADDR_DEPTH_B     = 16384,
    parameter DATA_WIDTH_B     = 32,
    parameter REGMODE_A        = "reg",
    parameter REGMODE_B        = "reg",
    parameter RESETMODE        = "sync",
    parameter RESET_RELEASE    = "sync",
    parameter BYTE_ENABLE_A    = 0,
    parameter BYTE_ENABLE_B    = 0,
    parameter WRITE_MODE_A     = "normal",
    parameter WRITE_MODE_B     = "normal",
    parameter UNALIGNED_READ   = 0,
    parameter INIT_MODE        = "none",
    parameter INIT_FILE        = "none",
    parameter INIT_FILE_FORMAT = "hex",
    parameter ADDR_WIDTH_A     = clog2(ADDR_DEPTH_A),
    parameter ADDR_WIDTH_B     = clog2(ADDR_DEPTH_B),
    parameter BYTE_WIDTH_A     = DATA_WIDTH_A/8,
    parameter BYTE_WIDTH_B     = DATA_WIDTH_B/8,
    parameter BYTE_POL         = 1'b0
)(
// --------------------------
// ----- Common Signals -----
// --------------------------
    input                         clk_i,
    output reg                    dps_i,
// --------------------------
// ----- Port A signals -----
// --------------------------
    input                         rst_a_i,
    output reg                    clk_en_a_i,
    output reg                    rdout_clken_a_i,
    output reg                    wr_en_a_i,
    output reg [DATA_WIDTH_A-1:0] wr_data_a_i,
    output reg [ADDR_WIDTH_A-1:0] addr_a_i,
    output reg [BYTE_WIDTH_A-1:0] ben_a_i,

    input [DATA_WIDTH_A-1:0]      rd_data_a_o,
    input [DATA_WIDTH_A-1:0]      mem_data_a_o,

// --------------------------
// ----- Port B signals -----
// --------------------------

    input                         rst_b_i,
    output reg                    clk_en_b_i,
    output reg                    rdout_clken_b_i,
    output reg                    wr_en_b_i,
    output reg [DATA_WIDTH_B-1:0] wr_data_b_i,
    output reg [ADDR_WIDTH_B-1:0] addr_b_i,
    output reg [BYTE_WIDTH_B-1:0] ben_b_i,

    input [DATA_WIDTH_B-1:0]      rd_data_b_o,
    input [DATA_WIDTH_B-1:0]      mem_data_b_o
);

localparam COUNTER_LIMIT_A = (REGMODE_A == "noreg") ? 2 : 3;
localparam COUNTER_LIMIT_B = (REGMODE_B == "noreg") ? 2 : 3;

localparam INIT_TDP        = 4'b0000;
localparam INIT_PDP        = 4'b0001;
localparam INIT_SP         = 4'b0010;
localparam READ_TDP        = 4'b0011;
localparam READ_PDP        = 4'b0100;
localparam READ_SP         = 4'b0101;

localparam INIT_MODE_A     = MEM_TYPE == "lram_dp_true" ? INIT_TDP : INIT_SP;
localparam INIT_MODE_B     = MEM_TYPE == "lram_dp_true" ? INIT_TDP : INIT_PDP;
localparam READ_MODE_A     = MEM_TYPE == "lram_dp_true" ? READ_TDP : READ_SP;
localparam READ_MODE_B     = MEM_TYPE == "lram_dp_true" ? READ_TDP : READ_PDP;

reg [DATA_WIDTH_A-1:0] buff_doa_ip;
reg [DATA_WIDTH_B-1:0] buff_dob_ip;
reg [DATA_WIDTH_A-1:0] buff_doa_chk;
reg [DATA_WIDTH_B-1:0] buff_dob_chk;

reg ip_dout_err    = 1'b1;
reg ip_segment_err = 1'b1;
reg ip_overall_err = 1'b1;

reg [BYTE_WIDTH_A-1:0] bena_p;
reg [BYTE_WIDTH_A-1:0] bena_p2;

reg [BYTE_WIDTH_B-1:0] benb_p;
reg [BYTE_WIDTH_B-1:0] benb_p2;

reg [DATA_WIDTH_A-1:0] dia_p;
reg [DATA_WIDTH_A-1:0] dia_p2;

reg [DATA_WIDTH_B-1:0] dib_p;
reg [DATA_WIDTH_B-1:0] dib_p2;

reg [1023:0] data_in;

localparam T_BYTE_WIDTH_A = (BYTE_WIDTH_A < 1) ? 1 : BYTE_WIDTH_A;
localparam T_BYTE_WIDTH_B = (BYTE_WIDTH_B < 1) ? 1 : BYTE_WIDTH_B;

wire [T_BYTE_WIDTH_A-1:0] bena_ref = (REGMODE_A == "noreg") ? bena_p : bena_p2;
wire [T_BYTE_WIDTH_B-1:0] benb_ref = (REGMODE_B == "noreg") ? benb_p : benb_p2;
wire [DATA_WIDTH_A-1:0] dia_ref  = (REGMODE_A == "noreg") ? dia_p : dia_p2;
wire [DATA_WIDTH_B-1:0] dib_ref  = (REGMODE_B == "noreg") ? dib_p : dib_p2;

genvar din0;
generate
    for(din0 = 0; din0 < 32; din0 = din0 + 1) begin
        always @ (posedge clk_i) begin
            data_in[din0*32+31:din0*32] <= $urandom_range({32{1'b0}}, {32{1'b1}});
        end
    end
endgenerate

initial begin
    buff_doa_ip  <= {DATA_WIDTH_A{1'b0}};
    buff_dob_ip  <= {DATA_WIDTH_B{1'b0}};
    buff_doa_chk <= {DATA_WIDTH_A{1'b0}};
    buff_dob_chk <= {DATA_WIDTH_B{1'b0}};

    benb_p       <= {BYTE_WIDTH_B{~BYTE_POL}};
    benb_p2      <= {BYTE_WIDTH_B{~BYTE_POL}};
    bena_p       <= {BYTE_WIDTH_A{~BYTE_POL}};
    bena_p2      <= {BYTE_WIDTH_A{~BYTE_POL}};

    dia_p        <= {DATA_WIDTH_A{1'b0}};
    dia_p2       <= {DATA_WIDTH_A{1'b0}};
    dib_p        <= {DATA_WIDTH_B{1'b0}};
    dib_p2       <= {DATA_WIDTH_B{1'b0}};
end

initial begin 
    clk_en_a_i      <= 1'b0;
    rdout_clken_a_i <= 1'b0;
    wr_en_a_i       <= 1'b0;
    wr_data_a_i     <= {DATA_WIDTH_A{1'b0}};
    addr_a_i        <= {ADDR_WIDTH_A{1'b0}};
    ben_a_i         <= {BYTE_WIDTH_A{~BYTE_POL}};

    clk_en_b_i      <= 1'b0;
    rdout_clken_b_i <= 1'b0;
    wr_en_b_i       <= 1'b0;
    wr_data_b_i     <= {DATA_WIDTH_B{1'b0}};
    addr_b_i        <= {ADDR_WIDTH_B{1'b0}};
    ben_b_i         <= {BYTE_WIDTH_B{~BYTE_POL}};

    dps_i           <= 1'b0;
end

always @ (posedge clk_i) begin
    bena_p  <= ben_a_i;
    bena_p2 <= bena_p;
    benb_p  <= ben_b_i;
    benb_p2 <= benb_p;
    dia_p   <= wr_data_a_i;
    dia_p2  <= dia_p;
    dib_p   <= wr_data_b_i;
    dib_p2  <= dib_p;
end

initial begin
    @(negedge rst_a_i);
    @(posedge clk_i);
    // ---- Port A Initialization Check
    if(MEM_TYPE == "lram_rom" || ((MEM_TYPE == "lram_dp_true" || MEM_TYPE == "lram_sp") && INIT_MODE != "none")) begin
        if(MEM_TYPE == "lram_dp_true") begin
            $display("Starting Initialization Check Port A");
        end
        else begin
            $display("Starting Initialization Check");
        end
        read_portA(INIT_MODE_A, 0);
    end

    // ---- Port B Initialization Check
    if((MEM_TYPE == "lram_dp_true" || MEM_TYPE == "lram_dp") && (INIT_MODE != "none")) begin
        if(MEM_TYPE == "lram_dp_true") begin
            $display("Starting Initialization Check Port B");
        end
        else begin
            $display("Starting Initialization Check");
        end
        read_portB(INIT_MODE_B, 0);
    end

    // ---- Port A Write
    if(MEM_TYPE != "lram_rom") begin
        if(MEM_TYPE == "lram_dp_true") begin
            $display("Write at port A started");
        end
        else begin
            $display("Write started");
        end
        write_portA();
        if(MEM_TYPE == "lram_dp_true" || MEM_TYPE == "lram_sp") begin
            read_portA(READ_MODE_A, 0);
        end
        if(MEM_TYPE == "lram_dp_true" || MEM_TYPE == "lram_dp") begin
            read_portB(READ_MODE_B, 0);
        end
    end

    // ---- Port B Write
    if(MEM_TYPE == "lram_dp_true") begin
        $display("Write at port B started");
        write_portB();
        read_portA(READ_MODE_A, 0);
        read_portB(READ_MODE_B, 0);
    end

    // ---- Unaligned Check
    if(UNALIGNED_READ) begin
        $display("Unaligned Read started");
        if(MEM_TYPE == "lram_dp_true" || MEM_TYPE == "lram_sp" || MEM_TYPE == "lram_rom") begin
            read_portA(READ_MODE_A, 1);
        end
        if(MEM_TYPE == "lram_dp_true" || MEM_TYPE == "lram_dp") begin
            read_portB(READ_MODE_B, 1);
        end
    end

    if(ip_overall_err) begin
        $display("-----------------------------------------------------");
        $display("----------------- SIMULATION PASSED -----------------");
        $display("-----------------------------------------------------");
    end
    else begin
        $display("-----------------------------------------------------");
        $display("!!!!!!!!!!!!!!!!! SIMULATION FAILED !!!!!!!!!!!!!!!!!");
        $display("-----------------------------------------------------");
    end
    $finish;
end

task write_portB;
    integer i0;
    begin
        if(WRITE_MODE_B == "write-through") begin
            @(posedge clk_i);
            addr_b_i    <= {ADDR_WIDTH_B{1'b0}};
            clk_en_b_i  <= 1'b1;
            wr_data_b_i <= data_in;
            wr_en_b_i   <= 1'b1;
            ben_b_i     <= {BYTE_WIDTH_B{BYTE_POL}};

            for(i0 = 0; i0 < ADDR_DEPTH_B; i0 = i0 + 1) begin
                @(posedge clk_i);
                addr_b_i     <= addr_b_i + 1'b1;
                wr_data_b_i  <= data_in;
                buff_dob_ip  <= rd_data_b_o;
                buff_dob_chk <= dib_ref;
                if(BYTE_ENABLE_B) begin
                    ben_b_i <= (ben_b_i == {BYTE_WIDTH_B{BYTE_POL}}) ? {{(BYTE_WIDTH_B-1){1'b1}}, 1'b0} : 
                               (ben_b_i[BYTE_WIDTH_B-1] == 1'b0) ? {BYTE_WIDTH_B{1'b0}} : ben_b_i << 1;
                end
                if(i0 >= COUNTER_LIMIT_B) begin
                    if(buff_dob_ip != buff_dob_chk) begin
                        $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_ip, buff_dob_chk, $time);
                        ip_dout_err    <= 1'b0;
                        ip_segment_err <= 1'b0;
                        ip_overall_err <= 1'b0;
                    end
                    else begin
                        ip_dout_err    <= 1'b1;
                    end
                end
            end
            wr_en_b_i <= 1'b0;
            @(posedge clk_i);
            buff_dob_ip  <= rd_data_b_o;
            buff_dob_chk <= dib_ref;
            if(BYTE_ENABLE_B) begin
                ben_b_i <= (ben_b_i == {BYTE_WIDTH_B{BYTE_POL}}) ? {{(BYTE_WIDTH_B-1){1'b1}}, 1'b0} : 
                           (ben_b_i[BYTE_WIDTH_B-1] == 1'b0) ? {BYTE_WIDTH_B{1'b0}} : ben_b_i << 1;
            end
            if(buff_dob_ip != buff_dob_chk) begin
                $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_ip, buff_dob_chk, $time);
                ip_dout_err    <= 1'b0;
                ip_segment_err <= 1'b0;
                ip_overall_err <= 1'b0;
            end
            else begin
                ip_dout_err    <= 1'b1;
            end

            if(REGMODE_B == "reg") begin
                @(posedge clk_i);
                buff_dob_ip  <= rd_data_b_o;
                buff_dob_chk <= dib_ref;
                if(BYTE_ENABLE_B) begin
                    ben_b_i <= (ben_b_i == {BYTE_WIDTH_B{BYTE_POL}}) ? {{(BYTE_WIDTH_B-1){1'b1}}, 1'b0} : 
                               (ben_b_i[BYTE_WIDTH_B-1] == 1'b0) ? {BYTE_WIDTH_B{1'b0}} : ben_b_i << 1;
                end
                if(buff_dob_ip != buff_dob_chk) begin
                    $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_ip, buff_dob_chk, $time);
                    ip_dout_err    <= 1'b0;
                    ip_segment_err <= 1'b0;
                    ip_overall_err <= 1'b0;
                end
                else begin
                    ip_dout_err    <= 1'b1;
                end
            end

            if(ip_segment_err) begin
                if(MEM_TYPE == "lram_dp_true") begin
                    $display("Write Through Check (Port B): PASSED");
                end
                else begin
                    $display("Write Through Check : PASSED");
                end
            end
            else begin
                if(MEM_TYPE == "lram_dp_true") begin
                    $display("Write Through Check (Port B): FAILED");
                end
                else begin
                    $display("Write Through Check : FAILED");
                end
            end
            addr_b_i    <= {ADDR_WIDTH_B{1'b0}};
            clk_en_b_i  <= 1'b0;
            wr_data_b_i <= {DATA_WIDTH_B{1'b0}};
            wr_en_b_i   <= 1'b0;
            ben_b_i     <= {BYTE_WIDTH_B{~BYTE_POL}};
            @(posedge clk_i);
            ip_dout_err    <= 1'b1;
            ip_segment_err <= 1'b1;
        end
        else begin
            @(posedge clk_i);
            addr_b_i    <= {ADDR_WIDTH_B{1'b0}};
            clk_en_b_i  <= 1'b1;
            wr_data_b_i <= data_in;
            wr_en_b_i   <= 1'b1;
            ben_b_i     <= {BYTE_WIDTH_B{BYTE_POL}};

            for(i0 = 0; i0 < ADDR_DEPTH_B; i0 = i0 + 1) begin
                @(posedge clk_i);
                addr_b_i     <= addr_b_i + 1'b1;
                wr_data_b_i  <= data_in;
                if(BYTE_ENABLE_B) begin
                    ben_b_i <= (ben_b_i == {BYTE_WIDTH_B{BYTE_POL}}) ? {{(BYTE_WIDTH_B-1){1'b1}}, 1'b0} : 
                               (ben_b_i[BYTE_WIDTH_B-1] == 1'b0) ? {BYTE_WIDTH_B{1'b0}} : ben_b_i << 1;
                end
            end

            addr_b_i    <= {ADDR_WIDTH_B{1'b0}};
            clk_en_b_i  <= 1'b0;
            wr_data_b_i <= {DATA_WIDTH_B{1'b0}};
            wr_en_b_i   <= 1'b0;
            ben_b_i     <= {BYTE_WIDTH_B{~BYTE_POL}};
            @(posedge clk_i);
        end
    end
endtask

task write_portA;
    integer i0;
    begin
        if(MEM_TYPE == "lram_sp" && WRITE_MODE_A == "read-before-write") begin
            @(posedge clk_i);
            addr_a_i    <= {ADDR_WIDTH_A{1'b0}};
            clk_en_a_i  <= 1'b1;
            wr_data_a_i <= data_in;
            wr_en_a_i   <= 1'b1;
            ben_a_i     <= {BYTE_WIDTH_A{BYTE_POL}};
            
            addr_b_i    <= {ADDR_WIDTH_B{1'b0}};
            clk_en_b_i  <= 1'b1;
            wr_en_b_i   <= 1'b0;

            for(i0 = 0; i0 < ADDR_DEPTH_A; i0 = i0 + 1) begin
                @(posedge clk_i);
                addr_a_i     <= addr_a_i + 1'b1;
                addr_b_i     <= addr_b_i + 1'b1;
                wr_data_a_i  <= data_in;
                buff_doa_ip  <= rd_data_a_o;
                buff_doa_chk <= mem_data_b_o;
                if(BYTE_ENABLE_A) begin
                    ben_a_i <= (ben_a_i == {BYTE_WIDTH_A{1'b0}}) ? {{(BYTE_WIDTH_A-1){1'b1}}, 1'b0} : 
                               (ben_a_i[BYTE_WIDTH_A-1] == 1'b0) ? {BYTE_WIDTH_A{1'b0}} : ben_a_i << 1;
                end
                if(i0 >= COUNTER_LIMIT_A) begin
                    if(buff_doa_ip != buff_doa_chk) begin
                        $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                        ip_dout_err    <= 1'b0;
                        ip_segment_err <= 1'b0;
                        ip_overall_err <= 1'b0;
                    end
                    else begin
                        ip_dout_err    <= 1'b1;
                    end
                end
            end
            wr_en_a_i <= 1'b0;
            @(posedge clk_i);
            buff_doa_ip  <= rd_data_a_o;
            buff_doa_chk <= mem_data_b_o;
            if(BYTE_ENABLE_A) begin
                ben_a_i <= (ben_a_i == {BYTE_WIDTH_A{1'b0}}) ? {{(BYTE_WIDTH_A-1){1'b1}}, 1'b0} : 
                           (ben_a_i[BYTE_WIDTH_A-1] == 1'b0) ? {BYTE_WIDTH_A{1'b0}} : ben_a_i << 1;
            end
            if(i0 >= COUNTER_LIMIT_A) begin
                if(buff_doa_ip != buff_doa_chk) begin
                    $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                    ip_dout_err    <= 1'b0;
                    ip_segment_err <= 1'b0;
                    ip_overall_err <= 1'b0;
                end
                else begin
                    ip_dout_err    <= 1'b1;
                end
            end

            if(REGMODE_A == "reg") begin
                @(posedge clk_i);
                buff_doa_ip  <= rd_data_a_o;
                buff_doa_chk <= mem_data_b_o;
                if(BYTE_ENABLE_A) begin
                    ben_a_i <= (ben_a_i == {BYTE_WIDTH_A{1'b0}}) ? {{(BYTE_WIDTH_A-1){1'b1}}, 1'b0} : 
                               (ben_a_i[BYTE_WIDTH_A-1] == 1'b0) ? {BYTE_WIDTH_A{1'b0}} : ben_a_i << 1;
                end
                if(i0 >= COUNTER_LIMIT_A) begin
                    if(buff_doa_ip != buff_doa_chk) begin
                        $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                        ip_dout_err    <= 1'b0;
                        ip_segment_err <= 1'b0;
                        ip_overall_err <= 1'b0;
                    end
                    else begin
                        ip_dout_err    <= 1'b1;
                    end
                end
            end
            if(ip_segment_err) begin
                $display("Read Before Write Check : PASSED");
            end
            else begin
                $display("Read Before Write Check : FAILED");
            end
            addr_a_i    <= {ADDR_WIDTH_A{1'b0}};
            clk_en_a_i  <= 1'b0;
            wr_data_a_i <= {DATA_WIDTH_A{1'b0}};
            wr_en_a_i   <= 1'b0;
            ben_a_i     <= {BYTE_WIDTH_A{~BYTE_POL}};

            addr_b_i    <= {ADDR_WIDTH_B{1'b0}};
            clk_en_b_i  <= 1'b0;
            wr_en_b_i   <= 1'b0;

            @(posedge clk_i);
            ip_dout_err    <= 1'b1;
            ip_segment_err <= 1'b1;
        end
        else if(WRITE_MODE_A == "write-through") begin
            @(posedge clk_i);
            addr_a_i    <= {ADDR_WIDTH_A{1'b0}};
            clk_en_a_i  <= 1'b1;
            wr_data_a_i <= data_in;
            wr_en_a_i   <= 1'b1;
            ben_a_i     <= {BYTE_WIDTH_A{BYTE_POL}};

            for(i0 = 0; i0 < ADDR_DEPTH_A; i0 = i0 + 1) begin
                @(posedge clk_i);
                addr_a_i     <= addr_a_i + 1'b1;
                wr_data_a_i  <= data_in;
                buff_doa_ip  <= rd_data_a_o;
                buff_doa_chk <= dia_ref;
                if(BYTE_ENABLE_A) begin
                    ben_a_i <= (ben_a_i == {BYTE_WIDTH_A{1'b0}}) ? {{(BYTE_WIDTH_A-1){1'b1}}, 1'b0} : 
                               (ben_a_i[BYTE_WIDTH_A-1] == 1'b0) ? {BYTE_WIDTH_A{1'b0}} : ben_a_i << 1;
                end
                if(i0 >= COUNTER_LIMIT_A) begin
                    if(buff_doa_ip != buff_doa_chk) begin
                        $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                        ip_dout_err    <= 1'b0;
                        ip_segment_err <= 1'b0;
                        ip_overall_err <= 1'b0;
                    end
                    else begin
                        ip_dout_err    <= 1'b1;
                    end
                end
            end
            wr_en_a_i <= 1'b0;
            @(posedge clk_i);
            buff_doa_ip  <= rd_data_a_o;
            buff_doa_chk <= dia_ref;
            if(BYTE_ENABLE_A) begin
                ben_a_i <= (ben_a_i == {BYTE_WIDTH_A{1'b0}}) ? {{(BYTE_WIDTH_A-1){1'b1}}, 1'b0} : 
                           (ben_a_i[BYTE_WIDTH_A-1] == 1'b0) ? {BYTE_WIDTH_A{1'b0}} : ben_a_i << 1;
            end
            if(buff_doa_ip != buff_doa_chk) begin
                $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                ip_dout_err    <= 1'b0;
                ip_segment_err <= 1'b0;
                ip_overall_err <= 1'b0;
            end
            else begin
                ip_dout_err    <= 1'b1;
            end

            if(REGMODE_A == "reg") begin
                @(posedge clk_i);
                buff_doa_ip  <= rd_data_a_o;
                buff_doa_chk <= dia_ref;
                if(BYTE_ENABLE_A) begin
                    ben_a_i <= (ben_a_i == {BYTE_WIDTH_A{1'b0}}) ? {{(BYTE_WIDTH_A-1){1'b1}}, 1'b0} : 
                               (ben_a_i[BYTE_WIDTH_A-1] == 1'b0) ? {BYTE_WIDTH_A{1'b0}} : ben_a_i << 1;
                end
                if(buff_doa_ip != buff_doa_chk) begin
                    $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                    ip_dout_err    <= 1'b0;
                    ip_segment_err <= 1'b0;
                    ip_overall_err <= 1'b0;
                end
                else begin
                    ip_dout_err    <= 1'b1;
                end
            end

            if(ip_segment_err) begin
                if(MEM_TYPE == "lram_dp_true") begin
                    $display("Write Through Check (Port A): PASSED");
                end
                else begin
                    $display("Write Through Check : PASSED");
                end
            end
            else begin
                if(MEM_TYPE == "lram_dp_true") begin
                    $display("Write Through Check (Port A): FAILED");
                end
                else begin
                    $display("Write Through Check : FAILED");
                end
            end
            addr_a_i    <= {ADDR_WIDTH_A{1'b0}};
            clk_en_a_i  <= 1'b0;
            wr_data_a_i <= {DATA_WIDTH_A{1'b0}};
            wr_en_a_i   <= 1'b0;
            ben_a_i     <= {BYTE_WIDTH_A{~BYTE_POL}};
            @(posedge clk_i);
            ip_dout_err    <= 1'b1;
            ip_segment_err <= 1'b1;
        end
        else begin
            @(posedge clk_i);
            addr_a_i    <= {ADDR_WIDTH_A{1'b0}};
            clk_en_a_i  <= 1'b1;
            wr_data_a_i <= data_in;
            wr_en_a_i   <= 1'b1;
            ben_a_i     <= {BYTE_WIDTH_A{BYTE_POL}};

            for(i0 = 0; i0 < ADDR_DEPTH_A; i0 = i0 + 1) begin
                @(posedge clk_i);
                addr_a_i     <= addr_a_i + 1'b1;
                wr_data_a_i  <= data_in;
                if(BYTE_ENABLE_A) begin
                    ben_a_i <= (ben_a_i == {BYTE_WIDTH_A{1'b0}}) ? {{(BYTE_WIDTH_A-1){1'b1}}, 1'b0} : 
                               (ben_a_i[BYTE_WIDTH_A-1] == 1'b0) ? {BYTE_WIDTH_A{1'b0}} : ben_a_i << 1;
                end
            end

            addr_a_i    <= {ADDR_WIDTH_A{1'b0}};
            clk_en_a_i  <= 1'b0;
            wr_data_a_i <= {DATA_WIDTH_A{1'b0}};
            wr_en_a_i   <= 1'b0;
            ben_a_i     <= {BYTE_WIDTH_A{~BYTE_POL}};
            @(posedge clk_i);
        end
    end
endtask

task read_portB;
    input [3:0] msg_code;
    input ualigned;
    integer i0;
    begin
        @(posedge clk_i);
        addr_b_i        <= {ADDR_WIDTH_B{1'b0}};
        clk_en_b_i      <= 1'b1;
        rdout_clken_b_i <= 1'b1;
        ben_b_i         <= (UNALIGNED_READ) ? {BYTE_WIDTH_B{1'b0}} : {BYTE_WIDTH_B{~BYTE_POL}};
        for(i0 = 0; i0 < ADDR_DEPTH_B; i0 = i0 + 1) begin
            @(posedge clk_i);
            addr_b_i     <= addr_b_i + 1'b1;
            buff_dob_ip  <= rd_data_b_o;
            if(ualigned) begin
                buff_dob_chk <= benb_ref[2] ? (mem_data_b_o << 8*benb_ref[1:0]) : (mem_data_b_o >> 8*benb_ref[1:0]);
                ben_b_i <= (ben_b_i == 4'b0111) ? 4'b0000 : ben_b_i + 1'b1;
            end
            else begin
                buff_dob_chk <= mem_data_b_o;
            end
            if(i0 >= COUNTER_LIMIT_B) begin
                if(buff_dob_chk != buff_dob_ip) begin
                    if(MEM_TYPE == "lram_dp_true") begin
                        $display("Data MISMATCH (Port B) EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_chk, buff_dob_ip, $time);
                    end
                    else begin
                        $display("Data MISMATCH at RD_PORT EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_chk, buff_dob_ip, $time);
                    end
                    ip_dout_err    <= 1'b0;
                    ip_segment_err <= 1'b0;
                    ip_overall_err <= 1'b0;
                end
                else begin
                    ip_dout_err    <= 1'b1;
                end
            end
        end

        @(posedge clk_i);
        buff_dob_ip  <= rd_data_b_o;
        if(ualigned) begin
            buff_dob_chk <= benb_ref[2] ? (mem_data_b_o << 8*benb_ref[1:0]) : (mem_data_b_o >> 8*benb_ref[1:0]);
            ben_b_i <= (ben_b_i == 4'b0111) ? 4'b0000 : ben_b_i + 1'b1;
        end
        else begin
            buff_dob_chk <= mem_data_b_o;
        end
        if(buff_dob_chk != buff_dob_ip) begin
            if(MEM_TYPE == "lram_dp_true") begin
                $display("Data MISMATCH (Port B) EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_chk, buff_dob_ip, $time);
            end
            else begin
                $display("Data MISMATCH at RD_PORT EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_chk, buff_dob_ip, $time);
            end
            ip_dout_err    <= 1'b0;
            ip_segment_err <= 1'b0;
            ip_overall_err <= 1'b0;
        end
        else begin
            ip_dout_err    <= 1'b1;
        end

        if(REGMODE_B == "reg") begin
            @(posedge clk_i);
            buff_dob_ip  <= rd_data_b_o;
            if(ualigned) begin
                buff_dob_chk <= benb_ref[2] ? (mem_data_b_o << 8*benb_ref[1:0]) : (mem_data_b_o >> 8*benb_ref[1:0]);
                ben_b_i <= (ben_b_i == 4'b0111) ? 4'b0000 : ben_b_i + 1'b1;
            end
            else begin
                buff_dob_chk <= mem_data_b_o;
            end
            if(buff_dob_chk != buff_dob_ip) begin
                if(MEM_TYPE == "lram_dp_true") begin
                    $display("Data MISMATCH (Port B) EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_chk, buff_dob_ip, $time);
                end
                else begin
                    $display("Data MISMATCH at RD_PORT EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_dob_chk, buff_dob_ip, $time);
                end
                ip_dout_err    <= 1'b0;
                ip_segment_err <= 1'b0;
                ip_overall_err <= 1'b0;
            end
            else begin
                ip_dout_err    <= 1'b1;
            end
        end

        addr_b_i        <= {ADDR_WIDTH_B{1'b0}};
        clk_en_b_i      <= 1'b0;
        rdout_clken_b_i <= 1'b0;

        if(ip_segment_err) begin
            case(msg_code)
                INIT_TDP: $display("Initialization Check (Port B) : PASSED");
                INIT_PDP: $display("Initialization Check : PASSED");
                READ_TDP: $display("Read Data (Port B) : PASSED");
                READ_PDP: $display("Read Data : PASSED");
            endcase
        end
        else begin
            case(msg_code)
                INIT_TDP: $display("Initialization Check (Port B) : FAILED");
                INIT_PDP: $display("Initialization Check : FAILED");
                READ_TDP: $display("Read Data (Port B) : FAILED");
                READ_PDP: $display("Read Data : FAILED");
            endcase
        end
        @(posedge clk_i);
        ip_dout_err    <= 1'b1;
        ip_segment_err <= 1'b1;
    end
endtask

task read_portA;
    input [3:0] msg_code;
    input ualigned;
    integer i0;
    begin
        @(posedge clk_i);
        addr_a_i        <= {ADDR_WIDTH_A{1'b0}};
        clk_en_a_i      <= 1'b1;
        rdout_clken_a_i <= 1'b1;
        ben_a_i         <= (UNALIGNED_READ) ? {BYTE_WIDTH_A{1'b0}} : {BYTE_WIDTH_A{~BYTE_POL}};
        for(i0 = 0; i0 < ADDR_DEPTH_A; i0 = i0 + 1) begin
            @(posedge clk_i);
            addr_a_i     <= addr_a_i + 1'b1;
            buff_doa_ip  <= rd_data_a_o;
            if(ualigned) begin
                buff_doa_chk <= bena_ref[2] ? (mem_data_a_o << 8*bena_ref[1:0]) : (mem_data_a_o >> 8*bena_ref[1:0]);
                ben_a_i <= (ben_a_i == 4'b0111) ? 4'b0000 : ben_a_i + 1'b1;
            end
            else begin
                buff_doa_chk <= mem_data_a_o;
            end
            if(i0 >= COUNTER_LIMIT_A) begin
                if(buff_doa_ip != buff_doa_chk) begin
                    if(MEM_TYPE == "lram_dp_true") begin
                        $display("Data MISMATCH (Port A) EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                    end
                    else begin
                        $display("Data MISMATCH at RD_PORT EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                    end
                    ip_dout_err    <= 1'b0;
                    ip_segment_err <= 1'b0;
                    ip_overall_err <= 1'b0;
                end
                else begin
                    ip_dout_err    <= 1'b1;
                end
            end
        end
        @(posedge clk_i);
        buff_doa_ip  <= rd_data_a_o;
        if(ualigned) begin
            buff_doa_chk <= bena_ref[2] ? (mem_data_a_o << 8*bena_ref[1:0]) : (mem_data_a_o >> 8*bena_ref[1:0]);
            ben_a_i <= (ben_a_i == 4'b0111) ? 4'b0000 : ben_a_i + 1'b1;
        end
        else begin
            buff_doa_chk <= mem_data_a_o;
        end
        
        if(buff_doa_ip != buff_doa_chk) begin
            if(MEM_TYPE == "lram_dp_true") begin
                $display("Data MISMATCH (Port A) EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
            end
            else begin
                $display("Data MISMATCH at RD_PORT EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
            end
            ip_dout_err    <= 1'b0;
            ip_segment_err <= 1'b0;
            ip_overall_err <= 1'b0;
        end
        else begin
            ip_dout_err    <= 1'b1;
        end
        
        if(REGMODE_A == "reg") begin
            @(posedge clk_i);
            buff_doa_ip  <= rd_data_a_o;
            if(ualigned) begin
                buff_doa_chk <= bena_ref[2] ? (mem_data_a_o << 8*bena_ref[1:0]) : (mem_data_a_o >> 8*bena_ref[1:0]);
                ben_a_i <= (ben_a_i == 4'b0111) ? 4'b0000 : ben_a_i + 1'b1;
            end
            else begin
                buff_doa_chk <= mem_data_a_o;
            end
        
            if(i0 >= COUNTER_LIMIT_A) begin
                if(buff_doa_ip != buff_doa_chk) begin
                    if(MEM_TYPE == "lram_dp_true") begin
                        $display("Data MISMATCH (Port A) EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                    end
                    else begin
                        $display("Data MISMATCH at RD_PORT EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", buff_doa_chk, buff_doa_ip, $time);
                    end
                    ip_dout_err    <= 1'b0;
                    ip_segment_err <= 1'b0;
                    ip_overall_err <= 1'b0;
                end
                else begin
                    ip_dout_err    <= 1'b1;
                end
            end
        end

        addr_a_i        <= {ADDR_WIDTH_A{1'b0}};
        clk_en_a_i      <= 1'b0;
        rdout_clken_a_i <= 1'b0;
        if(ip_segment_err) begin
            case(msg_code)
                INIT_TDP: $display("Initialization Check (Port A) : PASSED");
                INIT_SP:  $display("Initialization Check : PASSED");
                READ_TDP: $display("Read Data (Port A) : PASSED");
                READ_SP:  $display("Read Data : PASSED");
            endcase
        end
        else begin
            case(msg_code)
                INIT_TDP: $display("Initialization Check (Port A) : FAILED");
                INIT_SP:  $display("Initialization Check : FAILED");
                READ_TDP: $display("Read Data (Port A) : FAILED");
                READ_SP:  $display("Read Data : FAILED");
            endcase
        end
        @(posedge clk_i);
        ip_dout_err    <= 1'b1;
        ip_segment_err <= 1'b1;
    end
endtask
function [31:0] clog2;
    input [31:0] value;
    reg   [31:0] num;
    begin
        num = value - 1;
        for (clog2=0; num>0; clog2=clog2+1) num = num>>1;
    end
endfunction

endmodule
`endif