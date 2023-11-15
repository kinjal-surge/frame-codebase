component pll_ip is
    port(
        clki_i: in std_logic;
        clkop_o: out std_logic;
        clkos_o: out std_logic;
        clkos2_o: out std_logic;
        clkos3_o: out std_logic;
        clkos4_o: out std_logic;
        lock_o: out std_logic
    );
end component;

__: pll_ip port map(
    clki_i=>,
    clkop_o=>,
    clkos_o=>,
    clkos2_o=>,
    clkos3_o=>,
    clkos4_o=>,
    lock_o=>
);
