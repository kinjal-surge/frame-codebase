component pix2byte is
    port(
        rst_n_i: in std_logic;
        pix_clk_i: in std_logic;
        byte_clk_i: in std_logic;
        fv_i: in std_logic;
        lv_i: in std_logic;
        dvalid_i: in std_logic;
        pix_data0_i: in std_logic_vector(9 downto 0);
        c2d_ready_i: in std_logic;
        txfr_en_i: in std_logic;
        fv_start_o: out std_logic;
        fv_end_o: out std_logic;
        lv_start_o: out std_logic;
        lv_end_o: out std_logic;
        txfr_req_o: out std_logic;
        byte_en_o: out std_logic;
        byte_data_o: out std_logic_vector(7 downto 0);
        data_type_o: out std_logic_vector(5 downto 0);
        fifo_overflow_o: out std_logic;
        fifo_underflow_o: out std_logic;
        fifo_full_o: out std_logic;
        fifo_empty_o: out std_logic
    );
end component;

__: pix2byte port map(
    rst_n_i=>,
    pix_clk_i=>,
    byte_clk_i=>,
    fv_i=>,
    lv_i=>,
    dvalid_i=>,
    pix_data0_i=>,
    c2d_ready_i=>,
    txfr_en_i=>,
    fv_start_o=>,
    fv_end_o=>,
    lv_start_o=>,
    lv_end_o=>,
    txfr_req_o=>,
    byte_en_o=>,
    byte_data_o=>,
    data_type_o=>,
    fifo_overflow_o=>,
    fifo_underflow_o=>,
    fifo_full_o=>,
    fifo_empty_o=>
);
