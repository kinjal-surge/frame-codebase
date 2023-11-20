component frame_buffer is
    port(
        clk_i: in std_logic;
        dps_i: in std_logic;
        rst_i: in std_logic;
        wr_clk_en_i: in std_logic;
        rd_clk_en_i: in std_logic;
        wr_en_i: in std_logic;
        wr_data_i: in std_logic_vector(9 downto 0);
        wr_addr_i: in std_logic_vector(16 downto 0);
        rd_addr_i: in std_logic_vector(16 downto 0);
        rd_data_o: out std_logic_vector(9 downto 0);
        lramready_o: out std_logic;
        rd_datavalid_o: out std_logic
    );
end component;

__: frame_buffer port map(
    clk_i=>,
    dps_i=>,
    rst_i=>,
    wr_clk_en_i=>,
    rd_clk_en_i=>,
    wr_en_i=>,
    wr_data_i=>,
    wr_addr_i=>,
    rd_addr_i=>,
    rd_data_o=>,
    lramready_o=>,
    rd_datavalid_o=>
);
