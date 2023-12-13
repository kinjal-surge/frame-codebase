component ram_ip is
    port(
        clk_i: in std_logic;
        dps_i: in std_logic;
        rst_i: in std_logic;
        wr_clk_en_i: in std_logic;
        rd_clk_en_i: in std_logic;
        wr_en_i: in std_logic;
        wr_data_i: in std_logic_vector(31 downto 0);
        wr_addr_i: in std_logic_vector(13 downto 0);
        rd_addr_i: in std_logic_vector(13 downto 0);
        rd_data_o: out std_logic_vector(31 downto 0);
        lramready_o: out std_logic;
        rd_datavalid_o: out std_logic
    );
end component;

__: ram_ip port map(
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
