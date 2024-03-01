module huff_tables  (
    input   logic               clk,
    input   logic [3:0]         rl[1:0],
    input   logic [3:0]         coeff_length[1:0],
    input   logic [1:0]         re,
    input   logic [1:0]         chroma,
    input   logic [1:0]         ac,
    output  logic [4:0]         len[1:0],
    output  logic [15:0]        code[1:0]
);

// Address re-mapping:
//  0x00 .. 0xFA  = AC
//  0xB0 .. 0xBB  = DC
//  LSB 
//      0 = Y
//      1 = UV

localparam N_ENTRIES = 2*(1 + 'h bb); // 2x188 = 376

// 20x376
logic [19:0] rom[N_ENTRIES-1:0]; /* synthesis syn_romstyle = "Logic" */ //previously "Block_RAM"
logic [8:0] addr[1:0];
always @(*)  
for (int i=0; i<2; i++)
    if (ac[i])  addr[i] = {coeff_length[i],           rl[i], chroma[i]}; // {coeff len, RL,        chroma} - AC coeff len always less than 0xB
    else        addr[i] = {           4'hb, coeff_length[i], chroma[i]}; // {0xB,       coeff len, chroma}

logic [4:0]         lenq[1:0];
always @(posedge clk) 
for (int i=0; i<2; i++) begin
    lenq[i] <= rom[addr[i]][19:16];
    code[i] <= rom[addr[i]][15:0];
end
always_comb
for (int i=0; i<2; i++)
    len[i] = 1 + lenq[i];

always_comb begin
    for (int a=0; a<N_ENTRIES; a++) rom[a] = 'hx; // applies to 2x14 entries only

    // DC-Y (12 entries)
    rom[{4'h b, 4'h 0, 1'b0}] = {4'd  1, 12'b 00_0000000000, 4'hx};
    rom[{4'h b, 4'h 1, 1'b0}] = {4'd  2, 12'b 010_000000000, 4'hx};
    rom[{4'h b, 4'h 2, 1'b0}] = {4'd  2, 12'b 011_000000000, 4'hx};
    rom[{4'h b, 4'h 3, 1'b0}] = {4'd  2, 12'b 100_000000000, 4'hx};
    rom[{4'h b, 4'h 4, 1'b0}] = {4'd  2, 12'b 101_000000000, 4'hx};
    rom[{4'h b, 4'h 5, 1'b0}] = {4'd  2, 12'b 110_000000000, 4'hx};
    rom[{4'h b, 4'h 6, 1'b0}] = {4'd  3, 12'b 1110_00000000, 4'hx};
    rom[{4'h b, 4'h 7, 1'b0}] = {4'd  4, 12'b 11110_0000000, 4'hx};
    rom[{4'h b, 4'h 8, 1'b0}] = {4'd  5, 12'b 111110_000000, 4'hx};
    rom[{4'h b, 4'h 9, 1'b0}] = {4'd  6, 12'b 1111110_00000, 4'hx};
    rom[{4'h b, 4'h a, 1'b0}] = {4'd  7, 12'b 11111110_0000, 4'hx};
    rom[{4'h b, 4'h b, 1'b0}] = {4'd  8, 12'b 111111110_000, 4'hx}; //len=9

    // DC-UV (12 entries)
    rom[{4'h b, 4'h 0, 1'b1}] = {4'd  1, 12'b 00_0000000000, 4'hx};
    rom[{4'h b, 4'h 1, 1'b1}] = {4'd  1, 12'b 01_0000000000, 4'hx};
    rom[{4'h b, 4'h 2, 1'b1}] = {4'd  1, 12'b 10_0000000000, 4'hx};
    rom[{4'h b, 4'h 3, 1'b1}] = {4'd  2, 12'b 110_000000000, 4'hx};
    rom[{4'h b, 4'h 4, 1'b1}] = {4'd  3, 12'b 1110_00000000, 4'hx};
    rom[{4'h b, 4'h 5, 1'b1}] = {4'd  4, 12'b 11110_0000000, 4'hx};
    rom[{4'h b, 4'h 6, 1'b1}] = {4'd  5, 12'b 111110_000000, 4'hx};
    rom[{4'h b, 4'h 7, 1'b1}] = {4'd  6, 12'b 1111110_00000, 4'hx};
    rom[{4'h b, 4'h 8, 1'b1}] = {4'd  7, 12'b 11111110_0000, 4'hx};
    rom[{4'h b, 4'h 9, 1'b1}] = {4'd  8, 12'b 111111110_000, 4'hx};
    rom[{4'h b, 4'h a, 1'b1}] = {4'd  9, 12'b 1111111110_00, 4'hx};
    rom[{4'h b, 4'h b, 1'b1}] = {4'd 10, 12'b 11111111110_0, 4'hx}; //len=11

    //AC-Y (162 entries)
    rom[{8'h 10, 1'b0}] = {4'd  1, 16'b 00_00000000000000};
    rom[{8'h 20, 1'b0}] = {4'd  1, 16'b 01_00000000000000};
    rom[{8'h 30, 1'b0}] = {4'd  2, 16'b 100_0000000000000};
    rom[{8'h 00, 1'b0}] = {4'd  3, 16'b 1010_000000000000};
    rom[{8'h 40, 1'b0}] = {4'd  3, 16'b 1011_000000000000};
    rom[{8'h 11, 1'b0}] = {4'd  3, 16'b 1100_000000000000};
    rom[{8'h 50, 1'b0}] = {4'd  4, 16'b 11010_00000000000};
    rom[{8'h 21, 1'b0}] = {4'd  4, 16'b 11011_00000000000};
    rom[{8'h 12, 1'b0}] = {4'd  4, 16'b 11100_00000000000};
    rom[{8'h 13, 1'b0}] = {4'd  5, 16'b 111010_0000000000};
    rom[{8'h 14, 1'b0}] = {4'd  5, 16'b 111011_0000000000};
    rom[{8'h 60, 1'b0}] = {4'd  6, 16'b 1111000_000000000};
    rom[{8'h 31, 1'b0}] = {4'd  6, 16'b 1111001_000000000};
    rom[{8'h 15, 1'b0}] = {4'd  6, 16'b 1111010_000000000};
    rom[{8'h 16, 1'b0}] = {4'd  6, 16'b 1111011_000000000};
    rom[{8'h 70, 1'b0}] = {4'd  7, 16'b 11111000_00000000};
    rom[{8'h 22, 1'b0}] = {4'd  7, 16'b 11111001_00000000};
    rom[{8'h 17, 1'b0}] = {4'd  7, 16'b 11111010_00000000};
    rom[{8'h 41, 1'b0}] = {4'd  8, 16'b 111110110_0000000};
    rom[{8'h 23, 1'b0}] = {4'd  8, 16'b 111110111_0000000};
    rom[{8'h 18, 1'b0}] = {4'd  8, 16'b 111111000_0000000};
    rom[{8'h 19, 1'b0}] = {4'd  8, 16'b 111111001_0000000};
    rom[{8'h 1a, 1'b0}] = {4'd  8, 16'b 111111010_0000000};
    rom[{8'h 80, 1'b0}] = {4'd  9, 16'b 1111110110_000000};
    rom[{8'h 32, 1'b0}] = {4'd  9, 16'b 1111110111_000000};
    rom[{8'h 24, 1'b0}] = {4'd  9, 16'b 1111111000_000000};
    rom[{8'h 1b, 1'b0}] = {4'd  9, 16'b 1111111001_000000};
    rom[{8'h 1c, 1'b0}] = {4'd  9, 16'b 1111111010_000000};
    rom[{8'h 51, 1'b0}] = {4'd 10, 16'b 11111110110_00000};
    rom[{8'h 25, 1'b0}] = {4'd 10, 16'b 11111110111_00000};
    rom[{8'h 1d, 1'b0}] = {4'd 10, 16'b 11111111000_00000};
    rom[{8'h 0f, 1'b0}] = {4'd 10, 16'b 11111111001_00000};
    rom[{8'h 42, 1'b0}] = {4'd 11, 16'b 111111110100_0000};
    rom[{8'h 33, 1'b0}] = {4'd 11, 16'b 111111110101_0000};
    rom[{8'h 26, 1'b0}] = {4'd 11, 16'b 111111110110_0000};
    rom[{8'h 27, 1'b0}] = {4'd 11, 16'b 111111110111_0000};
    rom[{8'h 28, 1'b0}] = {4'd 14, 16'b 111111111000000_0};
    rom[{8'h 90, 1'b0}] = {4'd 15, 16'b 1111111110000010};
    rom[{8'h a0, 1'b0}] = {4'd 15, 16'b 1111111110000011};
    rom[{8'h 61, 1'b0}] = {4'd 15, 16'b 1111111110000100};
    rom[{8'h 71, 1'b0}] = {4'd 15, 16'b 1111111110000101};
    rom[{8'h 81, 1'b0}] = {4'd 15, 16'b 1111111110000110};
    rom[{8'h 91, 1'b0}] = {4'd 15, 16'b 1111111110000111};
    rom[{8'h a1, 1'b0}] = {4'd 15, 16'b 1111111110001000};
    rom[{8'h 52, 1'b0}] = {4'd 15, 16'b 1111111110001001};
    rom[{8'h 62, 1'b0}] = {4'd 15, 16'b 1111111110001010};
    rom[{8'h 72, 1'b0}] = {4'd 15, 16'b 1111111110001011};
    rom[{8'h 82, 1'b0}] = {4'd 15, 16'b 1111111110001100};
    rom[{8'h 92, 1'b0}] = {4'd 15, 16'b 1111111110001101};
    rom[{8'h a2, 1'b0}] = {4'd 15, 16'b 1111111110001110};
    rom[{8'h 43, 1'b0}] = {4'd 15, 16'b 1111111110001111};
    rom[{8'h 53, 1'b0}] = {4'd 15, 16'b 1111111110010000};
    rom[{8'h 63, 1'b0}] = {4'd 15, 16'b 1111111110010001};
    rom[{8'h 73, 1'b0}] = {4'd 15, 16'b 1111111110010010};
    rom[{8'h 83, 1'b0}] = {4'd 15, 16'b 1111111110010011};
    rom[{8'h 93, 1'b0}] = {4'd 15, 16'b 1111111110010100};
    rom[{8'h a3, 1'b0}] = {4'd 15, 16'b 1111111110010101};
    rom[{8'h 34, 1'b0}] = {4'd 15, 16'b 1111111110010110};
    rom[{8'h 44, 1'b0}] = {4'd 15, 16'b 1111111110010111};
    rom[{8'h 54, 1'b0}] = {4'd 15, 16'b 1111111110011000};
    rom[{8'h 64, 1'b0}] = {4'd 15, 16'b 1111111110011001};
    rom[{8'h 74, 1'b0}] = {4'd 15, 16'b 1111111110011010};
    rom[{8'h 84, 1'b0}] = {4'd 15, 16'b 1111111110011011};
    rom[{8'h 94, 1'b0}] = {4'd 15, 16'b 1111111110011100};
    rom[{8'h a4, 1'b0}] = {4'd 15, 16'b 1111111110011101};
    rom[{8'h 35, 1'b0}] = {4'd 15, 16'b 1111111110011110};
    rom[{8'h 45, 1'b0}] = {4'd 15, 16'b 1111111110011111};
    rom[{8'h 55, 1'b0}] = {4'd 15, 16'b 1111111110100000};
    rom[{8'h 65, 1'b0}] = {4'd 15, 16'b 1111111110100001};
    rom[{8'h 75, 1'b0}] = {4'd 15, 16'b 1111111110100010};
    rom[{8'h 85, 1'b0}] = {4'd 15, 16'b 1111111110100011};
    rom[{8'h 95, 1'b0}] = {4'd 15, 16'b 1111111110100100};
    rom[{8'h a5, 1'b0}] = {4'd 15, 16'b 1111111110100101};
    rom[{8'h 36, 1'b0}] = {4'd 15, 16'b 1111111110100110};
    rom[{8'h 46, 1'b0}] = {4'd 15, 16'b 1111111110100111};
    rom[{8'h 56, 1'b0}] = {4'd 15, 16'b 1111111110101000};
    rom[{8'h 66, 1'b0}] = {4'd 15, 16'b 1111111110101001};
    rom[{8'h 76, 1'b0}] = {4'd 15, 16'b 1111111110101010};
    rom[{8'h 86, 1'b0}] = {4'd 15, 16'b 1111111110101011};
    rom[{8'h 96, 1'b0}] = {4'd 15, 16'b 1111111110101100};
    rom[{8'h a6, 1'b0}] = {4'd 15, 16'b 1111111110101101};
    rom[{8'h 37, 1'b0}] = {4'd 15, 16'b 1111111110101110};
    rom[{8'h 47, 1'b0}] = {4'd 15, 16'b 1111111110101111};
    rom[{8'h 57, 1'b0}] = {4'd 15, 16'b 1111111110110000};
    rom[{8'h 67, 1'b0}] = {4'd 15, 16'b 1111111110110001};
    rom[{8'h 77, 1'b0}] = {4'd 15, 16'b 1111111110110010};
    rom[{8'h 87, 1'b0}] = {4'd 15, 16'b 1111111110110011};
    rom[{8'h 97, 1'b0}] = {4'd 15, 16'b 1111111110110100};
    rom[{8'h a7, 1'b0}] = {4'd 15, 16'b 1111111110110101};
    rom[{8'h 38, 1'b0}] = {4'd 15, 16'b 1111111110110110};
    rom[{8'h 48, 1'b0}] = {4'd 15, 16'b 1111111110110111};
    rom[{8'h 58, 1'b0}] = {4'd 15, 16'b 1111111110111000};
    rom[{8'h 68, 1'b0}] = {4'd 15, 16'b 1111111110111001};
    rom[{8'h 78, 1'b0}] = {4'd 15, 16'b 1111111110111010};
    rom[{8'h 88, 1'b0}] = {4'd 15, 16'b 1111111110111011};
    rom[{8'h 98, 1'b0}] = {4'd 15, 16'b 1111111110111100};
    rom[{8'h a8, 1'b0}] = {4'd 15, 16'b 1111111110111101};
    rom[{8'h 29, 1'b0}] = {4'd 15, 16'b 1111111110111110};
    rom[{8'h 39, 1'b0}] = {4'd 15, 16'b 1111111110111111};
    rom[{8'h 49, 1'b0}] = {4'd 15, 16'b 1111111111000000};
    rom[{8'h 59, 1'b0}] = {4'd 15, 16'b 1111111111000001};
    rom[{8'h 69, 1'b0}] = {4'd 15, 16'b 1111111111000010};
    rom[{8'h 79, 1'b0}] = {4'd 15, 16'b 1111111111000011};
    rom[{8'h 89, 1'b0}] = {4'd 15, 16'b 1111111111000100};
    rom[{8'h 99, 1'b0}] = {4'd 15, 16'b 1111111111000101};
    rom[{8'h a9, 1'b0}] = {4'd 15, 16'b 1111111111000110};
    rom[{8'h 2a, 1'b0}] = {4'd 15, 16'b 1111111111000111};
    rom[{8'h 3a, 1'b0}] = {4'd 15, 16'b 1111111111001000};
    rom[{8'h 4a, 1'b0}] = {4'd 15, 16'b 1111111111001001};
    rom[{8'h 5a, 1'b0}] = {4'd 15, 16'b 1111111111001010};
    rom[{8'h 6a, 1'b0}] = {4'd 15, 16'b 1111111111001011};
    rom[{8'h 7a, 1'b0}] = {4'd 15, 16'b 1111111111001100};
    rom[{8'h 8a, 1'b0}] = {4'd 15, 16'b 1111111111001101};
    rom[{8'h 9a, 1'b0}] = {4'd 15, 16'b 1111111111001110};
    rom[{8'h aa, 1'b0}] = {4'd 15, 16'b 1111111111001111};
    rom[{8'h 2b, 1'b0}] = {4'd 15, 16'b 1111111111010000};
    rom[{8'h 3b, 1'b0}] = {4'd 15, 16'b 1111111111010001};
    rom[{8'h 4b, 1'b0}] = {4'd 15, 16'b 1111111111010010};
    rom[{8'h 5b, 1'b0}] = {4'd 15, 16'b 1111111111010011};
    rom[{8'h 6b, 1'b0}] = {4'd 15, 16'b 1111111111010100};
    rom[{8'h 7b, 1'b0}] = {4'd 15, 16'b 1111111111010101};
    rom[{8'h 8b, 1'b0}] = {4'd 15, 16'b 1111111111010110};
    rom[{8'h 9b, 1'b0}] = {4'd 15, 16'b 1111111111010111};
    rom[{8'h ab, 1'b0}] = {4'd 15, 16'b 1111111111011000};
    rom[{8'h 2c, 1'b0}] = {4'd 15, 16'b 1111111111011001};
    rom[{8'h 3c, 1'b0}] = {4'd 15, 16'b 1111111111011010};
    rom[{8'h 4c, 1'b0}] = {4'd 15, 16'b 1111111111011011};
    rom[{8'h 5c, 1'b0}] = {4'd 15, 16'b 1111111111011100};
    rom[{8'h 6c, 1'b0}] = {4'd 15, 16'b 1111111111011101};
    rom[{8'h 7c, 1'b0}] = {4'd 15, 16'b 1111111111011110};
    rom[{8'h 8c, 1'b0}] = {4'd 15, 16'b 1111111111011111};
    rom[{8'h 9c, 1'b0}] = {4'd 15, 16'b 1111111111100000};
    rom[{8'h ac, 1'b0}] = {4'd 15, 16'b 1111111111100001};
    rom[{8'h 2d, 1'b0}] = {4'd 15, 16'b 1111111111100010};
    rom[{8'h 3d, 1'b0}] = {4'd 15, 16'b 1111111111100011};
    rom[{8'h 4d, 1'b0}] = {4'd 15, 16'b 1111111111100100};
    rom[{8'h 5d, 1'b0}] = {4'd 15, 16'b 1111111111100101};
    rom[{8'h 6d, 1'b0}] = {4'd 15, 16'b 1111111111100110};
    rom[{8'h 7d, 1'b0}] = {4'd 15, 16'b 1111111111100111};
    rom[{8'h 8d, 1'b0}] = {4'd 15, 16'b 1111111111101000};
    rom[{8'h 9d, 1'b0}] = {4'd 15, 16'b 1111111111101001};
    rom[{8'h ad, 1'b0}] = {4'd 15, 16'b 1111111111101010};
    rom[{8'h 1e, 1'b0}] = {4'd 15, 16'b 1111111111101011};
    rom[{8'h 2e, 1'b0}] = {4'd 15, 16'b 1111111111101100};
    rom[{8'h 3e, 1'b0}] = {4'd 15, 16'b 1111111111101101};
    rom[{8'h 4e, 1'b0}] = {4'd 15, 16'b 1111111111101110};
    rom[{8'h 5e, 1'b0}] = {4'd 15, 16'b 1111111111101111};
    rom[{8'h 6e, 1'b0}] = {4'd 15, 16'b 1111111111110000};
    rom[{8'h 7e, 1'b0}] = {4'd 15, 16'b 1111111111110001};
    rom[{8'h 8e, 1'b0}] = {4'd 15, 16'b 1111111111110010};
    rom[{8'h 9e, 1'b0}] = {4'd 15, 16'b 1111111111110011};
    rom[{8'h ae, 1'b0}] = {4'd 15, 16'b 1111111111110100};
    rom[{8'h 1f, 1'b0}] = {4'd 15, 16'b 1111111111110101};
    rom[{8'h 2f, 1'b0}] = {4'd 15, 16'b 1111111111110110};
    rom[{8'h 3f, 1'b0}] = {4'd 15, 16'b 1111111111110111};
    rom[{8'h 4f, 1'b0}] = {4'd 15, 16'b 1111111111111000};
    rom[{8'h 5f, 1'b0}] = {4'd 15, 16'b 1111111111111001};
    rom[{8'h 6f, 1'b0}] = {4'd 15, 16'b 1111111111111010};
    rom[{8'h 7f, 1'b0}] = {4'd 15, 16'b 1111111111111011};
    rom[{8'h 8f, 1'b0}] = {4'd 15, 16'b 1111111111111100};
    rom[{8'h 9f, 1'b0}] = {4'd 15, 16'b 1111111111111101};
    rom[{8'h af, 1'b0}] = {4'd 15, 16'b 1111111111111110};
 
    //AC-UV  (162 entries)
    rom[{8'h 00, 1'b1}] = {4'd  1, 16'b 00_00000000000000};
    rom[{8'h 10, 1'b1}] = {4'd  1, 16'b 01_00000000000000};
    rom[{8'h 20, 1'b1}] = {4'd  2, 16'b 100_0000000000000};
    rom[{8'h 30, 1'b1}] = {4'd  3, 16'b 1010_000000000000};
    rom[{8'h 11, 1'b1}] = {4'd  3, 16'b 1011_000000000000};
    rom[{8'h 40, 1'b1}] = {4'd  4, 16'b 11000_00000000000};
    rom[{8'h 50, 1'b1}] = {4'd  4, 16'b 11001_00000000000};
    rom[{8'h 12, 1'b1}] = {4'd  4, 16'b 11010_00000000000};
    rom[{8'h 13, 1'b1}] = {4'd  4, 16'b 11011_00000000000};
    rom[{8'h 60, 1'b1}] = {4'd  5, 16'b 111000_0000000000};
    rom[{8'h 21, 1'b1}] = {4'd  5, 16'b 111001_0000000000};
    rom[{8'h 14, 1'b1}] = {4'd  5, 16'b 111010_0000000000};
    rom[{8'h 15, 1'b1}] = {4'd  5, 16'b 111011_0000000000};
    rom[{8'h 70, 1'b1}] = {4'd  6, 16'b 1111000_000000000};
    rom[{8'h 16, 1'b1}] = {4'd  6, 16'b 1111001_000000000};
    rom[{8'h 17, 1'b1}] = {4'd  6, 16'b 1111010_000000000};
    rom[{8'h 31, 1'b1}] = {4'd  7, 16'b 11110110_00000000};
    rom[{8'h 22, 1'b1}] = {4'd  7, 16'b 11110111_00000000};
    rom[{8'h 23, 1'b1}] = {4'd  7, 16'b 11111000_00000000};
    rom[{8'h 18, 1'b1}] = {4'd  7, 16'b 11111001_00000000};
    rom[{8'h 80, 1'b1}] = {4'd  8, 16'b 111110100_0000000};
    rom[{8'h 41, 1'b1}] = {4'd  8, 16'b 111110101_0000000};
    rom[{8'h 24, 1'b1}] = {4'd  8, 16'b 111110110_0000000};
    rom[{8'h 19, 1'b1}] = {4'd  8, 16'b 111110111_0000000};
    rom[{8'h 1a, 1'b1}] = {4'd  8, 16'b 111111000_0000000};
    rom[{8'h 1b, 1'b1}] = {4'd  8, 16'b 111111001_0000000};
    rom[{8'h 1c, 1'b1}] = {4'd  8, 16'b 111111010_0000000};
    rom[{8'h 90, 1'b1}] = {4'd  9, 16'b 1111110110_000000};
    rom[{8'h 32, 1'b1}] = {4'd  9, 16'b 1111110111_000000};
    rom[{8'h 33, 1'b1}] = {4'd  9, 16'b 1111111000_000000};
    rom[{8'h 25, 1'b1}] = {4'd  9, 16'b 1111111001_000000};
    rom[{8'h 0f, 1'b1}] = {4'd  9, 16'b 1111111010_000000};
    rom[{8'h 51, 1'b1}] = {4'd 10, 16'b 11111110110_00000};
    rom[{8'h 26, 1'b1}] = {4'd 10, 16'b 11111110111_00000};
    rom[{8'h 27, 1'b1}] = {4'd 10, 16'b 11111111000_00000};
    rom[{8'h 1d, 1'b1}] = {4'd 10, 16'b 11111111001_00000};
    rom[{8'h a0, 1'b1}] = {4'd 11, 16'b 111111110100_0000};
    rom[{8'h 61, 1'b1}] = {4'd 11, 16'b 111111110101_0000};
    rom[{8'h 42, 1'b1}] = {4'd 11, 16'b 111111110110_0000};
    rom[{8'h 43, 1'b1}] = {4'd 11, 16'b 111111110111_0000};
    rom[{8'h 1e, 1'b1}] = {4'd 13, 16'b 11111111100000_00};
    rom[{8'h 52, 1'b1}] = {4'd 14, 16'b 111111111000010_0};
    rom[{8'h 1f, 1'b1}] = {4'd 14, 16'b 111111111000011_0};
    rom[{8'h 71, 1'b1}] = {4'd 15, 16'b 1111111110001000};
    rom[{8'h 81, 1'b1}] = {4'd 15, 16'b 1111111110001001};
    rom[{8'h 91, 1'b1}] = {4'd 15, 16'b 1111111110001010};
    rom[{8'h a1, 1'b1}] = {4'd 15, 16'b 1111111110001011};
    rom[{8'h 62, 1'b1}] = {4'd 15, 16'b 1111111110001100};
    rom[{8'h 72, 1'b1}] = {4'd 15, 16'b 1111111110001101};
    rom[{8'h 82, 1'b1}] = {4'd 15, 16'b 1111111110001110};
    rom[{8'h 92, 1'b1}] = {4'd 15, 16'b 1111111110001111};
    rom[{8'h a2, 1'b1}] = {4'd 15, 16'b 1111111110010000};
    rom[{8'h 53, 1'b1}] = {4'd 15, 16'b 1111111110010001};
    rom[{8'h 63, 1'b1}] = {4'd 15, 16'b 1111111110010010};
    rom[{8'h 73, 1'b1}] = {4'd 15, 16'b 1111111110010011};
    rom[{8'h 83, 1'b1}] = {4'd 15, 16'b 1111111110010100};
    rom[{8'h 93, 1'b1}] = {4'd 15, 16'b 1111111110010101};
    rom[{8'h a3, 1'b1}] = {4'd 15, 16'b 1111111110010110};
    rom[{8'h 34, 1'b1}] = {4'd 15, 16'b 1111111110010111};
    rom[{8'h 44, 1'b1}] = {4'd 15, 16'b 1111111110011000};
    rom[{8'h 54, 1'b1}] = {4'd 15, 16'b 1111111110011001};
    rom[{8'h 64, 1'b1}] = {4'd 15, 16'b 1111111110011010};
    rom[{8'h 74, 1'b1}] = {4'd 15, 16'b 1111111110011011};
    rom[{8'h 84, 1'b1}] = {4'd 15, 16'b 1111111110011100};
    rom[{8'h 94, 1'b1}] = {4'd 15, 16'b 1111111110011101};
    rom[{8'h a4, 1'b1}] = {4'd 15, 16'b 1111111110011110};
    rom[{8'h 35, 1'b1}] = {4'd 15, 16'b 1111111110011111};
    rom[{8'h 45, 1'b1}] = {4'd 15, 16'b 1111111110100000};
    rom[{8'h 55, 1'b1}] = {4'd 15, 16'b 1111111110100001};
    rom[{8'h 65, 1'b1}] = {4'd 15, 16'b 1111111110100010};
    rom[{8'h 75, 1'b1}] = {4'd 15, 16'b 1111111110100011};
    rom[{8'h 85, 1'b1}] = {4'd 15, 16'b 1111111110100100};
    rom[{8'h 95, 1'b1}] = {4'd 15, 16'b 1111111110100101};
    rom[{8'h a5, 1'b1}] = {4'd 15, 16'b 1111111110100110};
    rom[{8'h 36, 1'b1}] = {4'd 15, 16'b 1111111110100111};
    rom[{8'h 46, 1'b1}] = {4'd 15, 16'b 1111111110101000};
    rom[{8'h 56, 1'b1}] = {4'd 15, 16'b 1111111110101001};
    rom[{8'h 66, 1'b1}] = {4'd 15, 16'b 1111111110101010};
    rom[{8'h 76, 1'b1}] = {4'd 15, 16'b 1111111110101011};
    rom[{8'h 86, 1'b1}] = {4'd 15, 16'b 1111111110101100};
    rom[{8'h 96, 1'b1}] = {4'd 15, 16'b 1111111110101101};
    rom[{8'h a6, 1'b1}] = {4'd 15, 16'b 1111111110101110};
    rom[{8'h 37, 1'b1}] = {4'd 15, 16'b 1111111110101111};
    rom[{8'h 47, 1'b1}] = {4'd 15, 16'b 1111111110110000};
    rom[{8'h 57, 1'b1}] = {4'd 15, 16'b 1111111110110001};
    rom[{8'h 67, 1'b1}] = {4'd 15, 16'b 1111111110110010};
    rom[{8'h 77, 1'b1}] = {4'd 15, 16'b 1111111110110011};
    rom[{8'h 87, 1'b1}] = {4'd 15, 16'b 1111111110110100};
    rom[{8'h 97, 1'b1}] = {4'd 15, 16'b 1111111110110101};
    rom[{8'h a7, 1'b1}] = {4'd 15, 16'b 1111111110110110};
    rom[{8'h 28, 1'b1}] = {4'd 15, 16'b 1111111110110111};
    rom[{8'h 38, 1'b1}] = {4'd 15, 16'b 1111111110111000};
    rom[{8'h 48, 1'b1}] = {4'd 15, 16'b 1111111110111001};
    rom[{8'h 58, 1'b1}] = {4'd 15, 16'b 1111111110111010};
    rom[{8'h 68, 1'b1}] = {4'd 15, 16'b 1111111110111011};
    rom[{8'h 78, 1'b1}] = {4'd 15, 16'b 1111111110111100};
    rom[{8'h 88, 1'b1}] = {4'd 15, 16'b 1111111110111101};
    rom[{8'h 98, 1'b1}] = {4'd 15, 16'b 1111111110111110};
    rom[{8'h a8, 1'b1}] = {4'd 15, 16'b 1111111110111111};
    rom[{8'h 29, 1'b1}] = {4'd 15, 16'b 1111111111000000};
    rom[{8'h 39, 1'b1}] = {4'd 15, 16'b 1111111111000001};
    rom[{8'h 49, 1'b1}] = {4'd 15, 16'b 1111111111000010};
    rom[{8'h 59, 1'b1}] = {4'd 15, 16'b 1111111111000011};
    rom[{8'h 69, 1'b1}] = {4'd 15, 16'b 1111111111000100};
    rom[{8'h 79, 1'b1}] = {4'd 15, 16'b 1111111111000101};
    rom[{8'h 89, 1'b1}] = {4'd 15, 16'b 1111111111000110};
    rom[{8'h 99, 1'b1}] = {4'd 15, 16'b 1111111111000111};
    rom[{8'h a9, 1'b1}] = {4'd 15, 16'b 1111111111001000};
    rom[{8'h 2a, 1'b1}] = {4'd 15, 16'b 1111111111001001};
    rom[{8'h 3a, 1'b1}] = {4'd 15, 16'b 1111111111001010};
    rom[{8'h 4a, 1'b1}] = {4'd 15, 16'b 1111111111001011};
    rom[{8'h 5a, 1'b1}] = {4'd 15, 16'b 1111111111001100};
    rom[{8'h 6a, 1'b1}] = {4'd 15, 16'b 1111111111001101};
    rom[{8'h 7a, 1'b1}] = {4'd 15, 16'b 1111111111001110};
    rom[{8'h 8a, 1'b1}] = {4'd 15, 16'b 1111111111001111};
    rom[{8'h 9a, 1'b1}] = {4'd 15, 16'b 1111111111010000};
    rom[{8'h aa, 1'b1}] = {4'd 15, 16'b 1111111111010001};
    rom[{8'h 2b, 1'b1}] = {4'd 15, 16'b 1111111111010010};
    rom[{8'h 3b, 1'b1}] = {4'd 15, 16'b 1111111111010011};
    rom[{8'h 4b, 1'b1}] = {4'd 15, 16'b 1111111111010100};
    rom[{8'h 5b, 1'b1}] = {4'd 15, 16'b 1111111111010101};
    rom[{8'h 6b, 1'b1}] = {4'd 15, 16'b 1111111111010110};
    rom[{8'h 7b, 1'b1}] = {4'd 15, 16'b 1111111111010111};
    rom[{8'h 8b, 1'b1}] = {4'd 15, 16'b 1111111111011000};
    rom[{8'h 9b, 1'b1}] = {4'd 15, 16'b 1111111111011001};
    rom[{8'h ab, 1'b1}] = {4'd 15, 16'b 1111111111011010};
    rom[{8'h 2c, 1'b1}] = {4'd 15, 16'b 1111111111011011};
    rom[{8'h 3c, 1'b1}] = {4'd 15, 16'b 1111111111011100};
    rom[{8'h 4c, 1'b1}] = {4'd 15, 16'b 1111111111011101};
    rom[{8'h 5c, 1'b1}] = {4'd 15, 16'b 1111111111011110};
    rom[{8'h 6c, 1'b1}] = {4'd 15, 16'b 1111111111011111};
    rom[{8'h 7c, 1'b1}] = {4'd 15, 16'b 1111111111100000};
    rom[{8'h 8c, 1'b1}] = {4'd 15, 16'b 1111111111100001};
    rom[{8'h 9c, 1'b1}] = {4'd 15, 16'b 1111111111100010};
    rom[{8'h ac, 1'b1}] = {4'd 15, 16'b 1111111111100011};
    rom[{8'h 2d, 1'b1}] = {4'd 15, 16'b 1111111111100100};
    rom[{8'h 3d, 1'b1}] = {4'd 15, 16'b 1111111111100101};
    rom[{8'h 4d, 1'b1}] = {4'd 15, 16'b 1111111111100110};
    rom[{8'h 5d, 1'b1}] = {4'd 15, 16'b 1111111111100111};
    rom[{8'h 6d, 1'b1}] = {4'd 15, 16'b 1111111111101000};
    rom[{8'h 7d, 1'b1}] = {4'd 15, 16'b 1111111111101001};
    rom[{8'h 8d, 1'b1}] = {4'd 15, 16'b 1111111111101010};
    rom[{8'h 9d, 1'b1}] = {4'd 15, 16'b 1111111111101011};
    rom[{8'h ad, 1'b1}] = {4'd 15, 16'b 1111111111101100};
    rom[{8'h 2e, 1'b1}] = {4'd 15, 16'b 1111111111101101};
    rom[{8'h 3e, 1'b1}] = {4'd 15, 16'b 1111111111101110};
    rom[{8'h 4e, 1'b1}] = {4'd 15, 16'b 1111111111101111};
    rom[{8'h 5e, 1'b1}] = {4'd 15, 16'b 1111111111110000};
    rom[{8'h 6e, 1'b1}] = {4'd 15, 16'b 1111111111110001};
    rom[{8'h 7e, 1'b1}] = {4'd 15, 16'b 1111111111110010};
    rom[{8'h 8e, 1'b1}] = {4'd 15, 16'b 1111111111110011};
    rom[{8'h 9e, 1'b1}] = {4'd 15, 16'b 1111111111110100};
    rom[{8'h ae, 1'b1}] = {4'd 15, 16'b 1111111111110101};
    rom[{8'h 2f, 1'b1}] = {4'd 15, 16'b 1111111111110110};
    rom[{8'h 3f, 1'b1}] = {4'd 15, 16'b 1111111111110111};
    rom[{8'h 4f, 1'b1}] = {4'd 15, 16'b 1111111111111000};
    rom[{8'h 5f, 1'b1}] = {4'd 15, 16'b 1111111111111001};
    rom[{8'h 6f, 1'b1}] = {4'd 15, 16'b 1111111111111010};
    rom[{8'h 7f, 1'b1}] = {4'd 15, 16'b 1111111111111011};
    rom[{8'h 8f, 1'b1}] = {4'd 15, 16'b 1111111111111100};
    rom[{8'h 9f, 1'b1}] = {4'd 15, 16'b 1111111111111101};
    rom[{8'h af, 1'b1}] = {4'd 15, 16'b 1111111111111110};
end
endmodule
